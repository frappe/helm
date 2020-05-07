---
layout: default
---

{% include breadcrumbs.html %}

## Create Restore Backups from Cloud Job

Create a file named `restore-backups.yaml` with following content.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: restore-backups-${TIMESTAMP}
spec:
  backoffLimit: 1
  template:
    spec:
      securityContext:
        supplementalGroups: [1000]
      containers:
      - name: restore-backups
        image: frappe/erpnext-worker:${VERSION}
        args: ["restore-backup"]
        imagePullPolicy: IfNotPresent
        volumeMounts:
          - name: sites-dir
            mountPath: /home/frappe/frappe-bench/sites
        env:
          - name: "MYSQL_ROOT_PASSWORD"
            valueFrom:
              secretKeyRef:
                key: password
                name: mariadb-root-password
          - name: "BUCKET_NAME"
            value: ${BUCKET_NAME}
          - name: "ACCESS_KEY_ID"
            valueFrom:
              secretKeyRef:
                key: accessKey
                name: push-backup-s3-secret
          - name: "SECRET_ACCESS_KEY"
            valueFrom:
              secretKeyRef:
                key: secretKey
                name: push-backup-s3-secret
          - name: "ENDPOINT_URL"
            value: "${ENDPOINT_URL}"
          - name: "REGION"
            value: ${REGION}
          - name: "BUCKET_DIR"
            value: "${BUCKET_DIR}"
      restartPolicy: Never
      volumes:
        - name: sites-dir
          persistentVolumeClaim:
            claimName: ${SITES_PVC}
            readOnly: false
```

Change the following properties:

- `metadata.name`: unique name for the job e.g. restore-backups-202004201620
- `spec.template.spec.containers[?(@.name==restore-backups)].image`: Image to restore backups. Find it using following command
```console
$ kubectl get deployments.apps -n <namespace> <helm-release-name>-erpnext-erpnext -o jsonpath="{.spec.template.spec.containers[0].image}"
```
- `spec.template.spec.containers[?(@.name==restore-backups)].env[?(@.name==BUCKET_NAME)].value`: Name of S3 compatible storage bucket.
- `spec.template.spec.containers[?(@.name==restore-backups)].env[?(@.name==REGION)].value`: Name of region for S3 compatible object storage.
- `spec.template.spec.containers[?(@.name==restore-backups)].env[?(@.name==ENDPOINT_URL)].value`: Endpoint URL of S3 compatible object storage.
- `spec.template.spec.containers[?(@.name==restore-backups)].env[?(@.name==BUCKET_DIR)].value`: Directory inside bucket where backups are located.
- `spec.template.spec.volumes[0].persistentVolumeClaim.claimName`: PVC where sites are located


Create the resource:

```console
$ kubectl -n <namespace> -f restore-backups.yaml
```
