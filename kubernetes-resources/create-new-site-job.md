---
layout: default
---

{% include breadcrumbs.html %}

## Create New Site Job

Create a file named `add-example-site-job.yaml` with following content.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: create-new-site-${SITE_NAME}
spec:
  backoffLimit: 1
  template:
    spec:
      securityContext:
        supplementalGroups: [1000]
      containers:
      - name: create-site
        image: frappe/erpnext-worker:${VERSION}
        args: ["new"]
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
          - name: "ADMIN_PASSWORD"
            value: ${ADMIN_PASSWORD}
          - name: "INSTALL_APPS"
            value: "erpnext"
      restartPolicy: Never
      volumes:
        - name: sites-dir
          persistentVolumeClaim:
            claimName: ${SITES_PVC}
            readOnly: false
```

Change the following properties:

- `metadata.name`: unique name for site creation job. e.g. create-erp-example-com
- `spec.template.spec.containers[?(@.name==create-site)].image`: Image to create new site. Find it using following command
```console
$ kubectl get deployments.apps -n <namespace> <helm-release-name>-erpnext-erpnext -o jsonpath="{.spec.template.spec.containers[0].image}"
```
- `spec.template.spec.containers[?(@.name==create-site)].env[?(@.name==SITE_NAME)].value`: Site name to create, e.g. `erp.example.com` this has to resolve to LoadBalancer External IP
- `spec.template.spec.containers[?(@.name==create-site)].env[?(@.name==ADMIN_PASSWORD)].value`: Set password for site Administrator
- `spec.template.spec.volumes[0].persistentVolumeClaim.claimName`: PVC where sites are located

Create the resource:

```console
$ kubectl -n <namespace> -f add-example-site-job.yaml
```
