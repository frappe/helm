---
layout: default
---

{% include breadcrumbs.html %}

## Create Backup and Push CronJob

Create a file named `backup-and-push-cronjob.yaml` with following content.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-and-push
spec:
  schedule: "0 0 * * *"
  jobTemplate:
    spec:
      backoffLimit: 1
      template:
        spec:
          securityContext:
            supplementalGroups: [1000]
          initContainers:
          - name: backup
            image: frappe/erpnext-worker:${VERSION}
            args: ["backup"]
            imagePullPolicy: IfNotPresent
            env:
              - name: "WITH_FILES"
                value: "1"
            volumeMounts:
              - name: sites-dir
                mountPath: /home/frappe/frappe-bench/sites
          containers:
          - name: push-backup
            image: frappe/erpnext-worker:${VERSION}
            args: ["push-backup"]
            imagePullPolicy: IfNotPresent
            volumeMounts:
              - name: sites-dir
                mountPath: /home/frappe/frappe-bench/sites
            env:
              - name: "BUCKET_NAME"
                value: ${BUCKET_NAME}
              - name: "REGION"
                value: ${REGION}
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

- `metadata.name`: Name for the CronJob e.g. backup-and-push-daily
- `spec.jobTemplate.spec.template.spec.initContainer[0].image`: Image to backup sites.
- `spec.jobTemplate.spec.template.spec.container[0].image`: Image to push backups.
- Find image it using following command
```console
$ kubectl get deployments.apps -n <namespace> <helm-release-name>-erpnext-erpnext -o jsonpath="{.spec.template.spec.containers[0].image}"
```
- `spec.jobTemplate.spec.template.spec.containers[?(@.name==push-backup)].env[?(@.name==BUCKET_NAME)].value`: Name of S3 compatible storage bucket.
- `spec.jobTemplate.spec.template.spec.containers[?(@.name==push-backup)].env[?(@.name==REGION)].value`: Name of region for S3 compatible object storage.
- `spec.jobTemplate.spec.template.spec.containers[?(@.name==push-backup)].env[?(@.name==ENDPOINT_URL)].value`: Endpoint URL of S3 compatible object storage.
- `spec.jobTemplate.spec.template.spec.containers[?(@.name==push-backup)].env[?(@.name==BUCKET_DIR)].value`: Directory inside bucket where backups are located.
- `spec.jobTemplate.spec.template.spec.volumes[0].persistentVolumeClaim.claimName`: PVC where sites are located

Create the resource:

```console
$ kubectl -n <namespace> -f backup-and-push-cronjob.yaml
```
