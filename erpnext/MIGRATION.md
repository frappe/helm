# Guide: Migrating from Bitnami Subcharts to Built-in Components

This guide is for users who are running an older version of this chart with the Bitnami subcharts for MariaDB or PostgreSQL and wish to migrate to the new built-in StatefulSets.

With the new architecture, a simple `helm upgrade` is designed to be non-disruptive. Your application will continue to use the existing Bitnami subchart, and a new, empty built-in database StatefulSet will be provisioned alongside it.

This guide outlines the **manual, two-stage process** to complete the migration to the new database.

## The Migration Process

**IMPORTANT:** The final step of the migration process involves a brief period of downtime as you switch the application's database connection.

You **must** take a complete backup before starting.

## Migration Strategy

The migration is a two-stage process:

1.  **Stage 1: Provision New Database.**
    You will upgrade your Helm release, which will create the new built-in database StatefulSet. Your application will continue to run, connected to the old Bitnami database.

2.  **Stage 2: Data Migration and Switchover.**
    You will manually back up your site data from the old database and restore it into the new one. Finally, you will reconfigure the chart to point the application to the new database and decommission the old one.

---

## Step-by-Step Guide (Example: MariaDB)

### Stage 1: Upgrade and Provision New Database

1.  **(CRITICAL) Create a Full Backup**

    Before starting, ensure you have a complete and verified backup of your site(s).

    ```bash
    # Replace <release-name> and <your-site-name> with your current values
    helm template <release-name> frappe/erpnext \
      -f your-values.yaml \
      --set jobs.backup.enabled=true \
      --set jobs.backup.siteName=<your-site-name> \
      -s templates/job-backup.yaml | kubectl apply -f -
    ```

    Wait for the backup job to complete and verify the backup files are created in your sites volume.

2.  **Update `values.yaml` for Upgrade**

    Modify your `values.yaml` to enable the new built-in StatefulSet. Your existing `mariadb.enabled: true` (or `mariadb-subchart.enabled: true`) should remain, which keeps the old database running.

    ```yaml
    # your-values.yaml

    # Keep the classic Bitnami subchart enabled
    mariadb:
      enabled: true # Or mariadb-subchart.enabled: true

    # Enable the new built-in StatefulSet and configure it
    mariadb-sts:
      enabled: true
      persistence:
        # storageClass: "default" # or your preferred storage class
        size: 8Gi
    ```

3.  **Upgrade the Helm Chart**

    Now, perform the upgrade. This will create the new, empty `mariadb-sts` StatefulSet. Your site will remain operational and connected to the old Bitnami database.

    ```bash
    helm upgrade <release-name> frappe/erpnext --version <new-chart-version> -f your-values.yaml
    ```

### Stage 2: Migrate Data and Switch Over

At this point, you have two databases running. Now you will move the data and switch the application. This stage will involve downtime.

1.  **Backup and Restore Data**

    The most reliable method is to use `bench backup` and `bench restore`. You will need to `exec` into a pod to get the database credentials and run the commands. A detailed guide on this is outside the scope of this document, but it involves:
    *   Taking a fresh backup from the old database.
    *   Restoring that backup into the new database (`<release-name>-mariadb`).

2.  **Update `values.yaml` for Switchover**

    Modify your `values.yaml` to disable the old Bitnami subchart. This tells Helm to re-run the `configure` job, which will now point `common_site_config.json` to the new database.

    ```yaml
    # your-values.yaml

    # Disable the classic Bitnami subchart
    mariadb:
      enabled: false
    mariadb-subchart:
      enabled: false

    # Keep the new built-in StatefulSet enabled
    mariadb-sts:
      enabled: true
      persistence:
        # storageClass: "default"
        size: 8Gi
    ```

3.  **Final Helm Upgrade (The Switchover)**

    This is the final step. This upgrade will:
    *   Delete the old Bitnami MariaDB deployment.
    *   Re-run the `configure` job, which updates `db_host` to point to the new `mariadb-sts` service.
    *   Restart your application pods, which will now connect to the new database containing your restored data.

```bash
helm upgrade <release-name> frappe/erpnext --version <new-chart-version> -f your-values.yaml
```
