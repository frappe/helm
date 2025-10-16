# Guide: Migrating from Bitnami Subcharts to Built-in Components

This guide is for users who are running an older version of this chart (e.g., v7.x) with the Bitnami subcharts for MariaDB, PostgreSQL, or Redis, and wish to migrate to the new built-in StatefulSets.

With the new transitional architecture, you can continue using the Bitnami subcharts by simply running `helm upgrade`. This guide is only for those who want to perform the migration.

## The Migration Process

**IMPORTANT:** The migration process involves a brief period of downtime and will replace your existing database instance. When you disable the Bitnami subchart and enable the built-in StatefulSet during the `helm upgrade`, Helm will delete the old database resources.

Therefore, you **must** take a complete backup before starting.

## Migration Strategy

The safest migration strategy is to back up your data, reconfigure Helm to use the new components, perform the upgrade (which creates a new empty database), and then restore your backup into the new instance.

1.  **Backup Site:** Create a full backup of your site (database + files).
2.  **Update `values.yaml`:** Disable the Bitnami subchart (e.g., `mariadb-subchart.enabled: false`) and enable the corresponding built-in component (e.g., `mariadb.enabled: true`).
3.  **Upgrade Helm Chart:** Run `helm upgrade`. This will delete the old Bitnami database and create the new, empty built-in database.
4.  **Restore Site:** Use a Kubernetes Job to restore your site from the backup created in Step 1.
5.  **Run `bench migrate`:** Apply any necessary database schema changes.

---

## Step-by-Step Guide (Example: MariaDB)

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

### Step 2: Update `values.yaml` for Migration

Modify your `values.yaml` to disable the old Bitnami subchart and enable the new built-in StatefulSet.

```yaml
# your-values.yaml

# Disable the classic Bitnami subchart
mariadb-subchart:
  enabled: false

# Enable the new built-in StatefulSet and configure it
mariadb:
  enabled: true
  persistence:
    storageClass: "nfs" # or your preferred storage class
    size: 8Gi
```

### Step 3: Upgrade the Helm Chart

Now, perform the upgrade. **This is the step that will delete the old Bitnami database and create the new, empty one.** Your site will be down until the restore is complete.

```bash
helm upgrade <release-name> frappe/erpnext --version <new-chart-version> -f your-values.yaml
```

### Step 4: Restore Your Site

Create a Kubernetes `Job` to restore your site from the backup taken in Step 1. You will need to find the name of your backup file.

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

After the restore is complete, run `bench migrate` to ensure the database schema is up-to-date with the application version. You can do this with another Kubernetes Job or by executing the command in a running pod.

Your migration is now complete. Your ERPNext instance is running with the new, self-contained database.

# Migrate from Helm Chart 3.x.x to 4.x.x

Before you begin make sure you have taken backups to restore from fresh install.

Make following changes along with additional changes as per requirement to `custom-values.yaml`:

```yaml
mariadb:
  enabled: false

dbHost: "mariadb.mariadb.svc.cluster.local"
dbPort: 3306
dbRootUser: root
dbRootPassword: admin

jobs:
  configure:
    enabled: true

persistence:
  worker:
    storageClass: nfs
```

Note:

- Make sure your storage class is same as the one set in previous release. It will not re-create any PVC and use the old one instead.
- If the `dbRootPassword` is set it will create secret.

Delete old deployments

```shell
kubectl get deploy -n erpnext | grep frappe-bench | awk '{print $1}' | xargs kubectl delete deploy -n erpnext
```

Delete old serviceaccounts

```shell
kubectl get sa -n erpnext | grep frappe-bench | awk '{print $1}' | xargs kubectl delete sa -n erpnext
```

Delete old services

```shell
kubectl get svc -n erpnext | grep frappe-bench | awk '{print $1}' | xargs kubectl delete svc -n erpnext
```

Delete old secret if it exists

```shell
kubectl delete secret -n erpnext frappe-bench
```

Delete old configmaps if they exists, new configmaps will be based on `custom-values.yaml`

```shell
kubectl get cm -n erpnext | grep frappe-bench | awk '{print $1}' | xargs kubectl delete cm -n erpnext
```

Upgrade

```shell
helm upgrade frappe-bench -n erpnext frappe/erpnext -f custom-values.yaml
```
