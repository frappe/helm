---
layout: default
---

{% include breadcrumbs.html %}

## Create Push Backup S3 Secret

Create a file named `s3-secret.yaml` with following content.

```yaml
apiVersion: v1
data:
  accessKey: ${ACCESS_KEY_ID_BASE64}
  secretKey: ${SECRET_ACCESS_KEY_BASE64}
kind: Secret
metadata:
  name: push-backup-s3-secret
type: Opaque
```

Change the following properties:

- `data.accessKey`: S3 Access Key ID encoded as base64
- `data.secretKey`: S3 Secret Access Key encoded as base64

Note down the `metadata.name`. It is required create Jobs to push backups to cloud or to restore backups from cloud.

Create the resource using:

```console
$ kubectl create -n <namespace> -f s3-secret.yaml
```
