---
layout: default
---

{% include breadcrumbs.html %}

## Create Migrate Sites Job

Create a file named `migrate-sites.yaml` with following content.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: migrate-sites-${TIMESTAMP}
spec:
  backoffLimit: 1
  template:
    spec:
      securityContext:
        supplementalGroups: [1000]
      containers:
      - name: migrate-sites
        image: frappe/erpnext-worker:${VERSION}
        args: ["migrate"]
        imagePullPolicy: IfNotPresent
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

- `metadata.name`: unique name for the job e.g. migrate-202004201620
- `spec.template.spec.containers[?(@.name==migrate-sites)].image`: Image to migrate sites. Find it using following command
```console
$ kubectl get deployments.apps -n <namespace> <helm-release-name>-erpnext-erpnext -o jsonpath="{.spec.template.spec.containers[0].image}"
```
- `spec.template.spec.volumes[0].persistentVolumeClaim.claimName`: PVC where sites are located


Create the resource:

```console
$ kubectl -n <namespace> -f migrate-sites.yaml
```
