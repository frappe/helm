---
layout: default
---

{% include breadcrumbs.html %}

## Create Backup Sites Job

Create a file named `backup-sites.yaml` with following content.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: backup-sites-${TIMESTAMP}
spec:
  backoffLimit: 1
  template:
    spec:
      securityContext:
        supplementalGroups: [1000]
      containers:
      - name: backup-sites
        image: frappe/erpnext-worker:${VERSION}
        args: ["backup"]
        imagePullPolicy: IfNotPresent
        env:
          - name: "WITH_FILES"
            value: "1"
        volumeMounts:
          - name: sites-dir
            mountPath: /home/frappe/frappe-bench/sites
      restartPolicy: Never
      volumes:
        - name: sites-dir
          persistentVolumeClaim:
            claimName: ${SITES_PVC}
            readOnly: false
```

Change the following properties:

- `metadata.name`: unique name for the job e.g. backup-202004201620
- `spec.template.spec.containers[?(@.name==backup-sites)].image`: Image to backup sites. Find it using following command
```console
$ kubectl get deployments.apps -n <namespace> <helm-release-name>-erpnext-erpnext -o jsonpath="{.spec.template.spec.containers[0].image}"
```
- `spec.template.spec.volumes[0].persistentVolumeClaim.claimName`: PVC where sites are located


Create the resource:

```console
$ kubectl -n <namespace> -f backup-sites.yaml
```
