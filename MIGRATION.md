# Migration Guide: Upgrading from v7 to v8.x+

This guide is for users upgrading from chart version `7.0.244` (or older) to a newer version (`>=8.0.0`).

## The Challenge: Why a Direct `helm upgrade` Will Fail

**IMPORTANT:** This is a major breaking change. A direct `helm upgrade` will cause **permanent data loss**.

Versions `>=8.0.0` of this chart replace the Bitnami subcharts for MariaDB and PostgreSQL with built-in `StatefulSet`s. When you run `helm upgrade`, Helm's reconciliation logic will see that the Bitnami `mariadb` dependency has been removed from the chart's definition. As a result, Helm will automatically delete all resources created by that subchart in the previous release, including the `StatefulSet` and `PersistentVolumeClaim` (PVC) that hold your database data.

To prevent this, you must perform a manual migration by exporting your data from the old database and importing it into the new one.

## The Safe Migration Strategy

The safest migration strategy involves a brief period of downtime. We will take a backup, perform the upgrade which creates a new empty database, and then restore the backup into the new database.

1.  **Backup Site:** Create a full backup of your site (database + files).
2.  **Export SQL Data:** Manually export a SQL dump from the old Bitnami database as a secondary precaution.
3.  **Upgrade Helm Chart:** Perform the `helm upgrade`. This will delete the old Bitnami database and create the new empty, built-in database.
4.  **Restore Site:** Use a Kubernetes Job to restore your site from the backup created in Step 1. This will import the data into the new database.
5.  **Run Migration:** Run the `bench migrate` command to apply any necessary database schema changes.

---

## Step-by-Step Migration

### Step 1: (CRITICAL) Create a Full Backup

Before starting, ensure you have a complete and verified backup of your site(s). You can generate a backup job using `helm template`.

```bash
# Replace <release-name> and <your-site-name> with your current values
helm template <release-name> frappe/erpnext \
  -f your-values.yaml \
  --set jobs.backup.enabled=true \
  --set jobs.backup.siteName=<your-site-name> \
  -s templates/job-backup.yaml | kubectl apply -f -
```

Wait for the backup job to complete and verify the backup files are created in your sites volume.

### Step 2: (Recommended) Manually Export SQL Data

As an extra safety measure, manually export a SQL dump from your old database. You can do this by executing `mysqldump` or `pg_dump` inside the running Bitnami database pod. This gives you a second recovery option.

### Step 3: Upgrade the Helm Chart

First, update your `values.yaml` to ensure the new built-in database is enabled.

```yaml
# your-values.yaml

# Enable the new built-in StatefulSet
mariadb:
  enabled: true
  # Configure persistence, resources, etc. as needed
  persistence:
    storageClass: "nfs" # or your preferred storage class
    size: 8Gi
# Make sure other external DB settings are disabled
# dbHost: ...
```

Now, perform the upgrade. **This is the step that will delete the old Bitnami database and create the new, empty one.**

```bash
helm upgrade <release-name> frappe/erpnext --version <new-chart-version> -f your-values.yaml
```

### Step 4: Restore Your Site

Create a `Job` to restore your site from the backup taken in Step 1. You will need to find the name of your backup file (e.g., by listing files in the sites PVC).

```yaml
# Example restore job definition (save as restore-job.yaml)
apiVersion: batch/v1
kind: Job
metadata:
  name: restore-from-backup
spec:
  template:
    spec:
      containers:
      - name: restore
        image: frappe/erpnext:v15.83.0 # Use your image version
        command: ["bench", "restore", "/path/to/your/backup.sql.gz", "--with-private-files", "/path/to/your/private-files.tar.gz"]
        volumeMounts:
        - name: sites-dir
          mountPath: /home/frappe/frappe-bench/sites
      restartPolicy: Never
      volumes:
      - name: sites-dir
        persistentVolumeClaim:
          claimName: <your-pvc-name> # e.g., "frappe-bench-erpnext"
```

Apply the job to start the restore process: `kubectl apply -f restore-job.yaml`.

### Step 5: Run Migration

After the restore is complete, run `bench migrate` to ensure the database schema is up-to-date with the application version. You can do this with another Kubernetes Job or by executing the command in a running worker pod.

After the import is complete, your migration is finished. Your ERPNext instance is now running with the new, self-contained database.
