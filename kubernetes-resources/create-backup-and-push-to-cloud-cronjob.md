---
layout: default
---

{% include breadcrumbs.html %}

## Create Migrate Sites Job

Create a file named `backup-and-push-cronjob.yaml` with following content.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-backup-push
```

Change the following properties:

- `metadata.name`: Name for the CronJob e.g. daily-backup-push

Create the resource:

```console
$ kubectl -n <namespace> -f backup-and-push-cronjob.yaml
```
