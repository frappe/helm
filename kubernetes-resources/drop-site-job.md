---
layout: default
---

{% include breadcrumbs.html %}

## Drop Site Job

Create a file named `drop-site-job.yaml` with following content.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: drop-site-${SITE_NAME}
spec:
  backoffLimit: 1
  template:
    spec:
      securityContext:
        supplementalGroups: [1000]
      containers:
      - name: drop-site
        image: frappe/erpnext-worker:${VERSION}
        args: ["drop"]
        imagePullPolicy: IfNotPresent
        volumeMounts:
          - name: sites-dir
            mountPath: /home/frappe/frappe-bench/sites
        env:
          - name: "SITE_NAME"
            value: ${SITE_NAME}
          - name: "DB_ROOT_USER"
            value: root
          - name: "MYSQL_ROOT_PASSWORD"
            valueFrom:
              secretKeyRef:
                key: password
                name: mariadb-root-password
      restartPolicy: Never
      volumes:
        - name: sites-dir
          persistentVolumeClaim:
            claimName: ${SITES_PVC}
            readOnly: false
```

Change the following properties:

- `metadata.name`: unique name for site deletion job. e.g. drop-erp-example-com
- `spec.template.spec.containers[?(@.name==drop-site)].image`: Image to drop site. Find it using following command
```console
$ kubectl get deployments.apps -n <namespace> <helm-release-name>-erpnext-erpnext -o jsonpath="{.spec.template.spec.containers[0].image}"
```
- `spec.template.spec.containers[?(@.name==drop-site)].env[?(@.name==SITE_NAME)].value`: Site name to drop, e.g. `erp.example.com` 
- `spec.template.spec.volumes[0].persistentVolumeClaim.claimName`: PVC where sites are located

Create the resource:

```console
$ kubectl create -n <namespace> -f drop-site-job.yaml
```
