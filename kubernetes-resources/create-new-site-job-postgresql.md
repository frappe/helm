---
layout: default
---

{% include breadcrumbs.html %}

## Create New Site Job (PostgreSQL)

Copy PostgreSQL secret into erpnext namespace

```console
$ kubectl get secret postgresql -n postgresql -o yaml | \
    grep -v '^\s*namespace:\s' | \
      kubectl apply -n erpnext -f -
```

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
          - name: "POSTGRES_HOST"
            value: "postgresql.postgresql.svc.cluster.local"
          - name: "SITE_NAME"
            value: ${SITE_NAME}
          - name: "DB_ROOT_USER"
            value: postgres
          - name: "POSTGRES_PASSWORD"
            valueFrom:
              secretKeyRef:
                key: postgresql-password
                name: postgresql
          - name: "ADMIN_PASSWORD"
            value: ${ADMIN_PASSWORD}
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
$ kubectl create -n <namespace> -f add-example-site-job.yaml
```

## Health check

Setup helm release with health check for connection to PostgreSQL as secondary database. It will ensure PostgreSQL connection is alive for connected workers and scheduler pods. Execute `helm install` or `helm upgrade` command.

Example:

```console
$ helm install <release-name> --namespace <namespace> frappe/erpnext \
    --set mariadbHost=mariadb.mariadb.svc.cluster.local \
    --set persistence.worker.storageClass=<storageClass> \
    --set persistence.logs.storageClass=<storageClass> \
    --set postgresHost=postgresql.postgresql.svc.cluster.local \
    --set postgresPort=5432
```
