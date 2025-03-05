# Frappe / ERPNext

[Frappe](https://frappe.io)/[ERPNext](https://erpnext.com) Free and Open Source Enterprise Resource Planning (ERP).

## TL;DR;

For evaluation setup simple in-cluster NFS server to make the `nfs` storage class with RWX capabilities available for use. Make sure you have default storage class (`kubectl get sc`) already on your cluster before creating `nfs` storage class.

```shell
kubectl create namespace nfs
helm repo add nfs-ganesha-server-and-external-provisioner https://kubernetes-sigs.github.io/nfs-ganesha-server-and-external-provisioner
helm upgrade --install -n nfs in-cluster nfs-ganesha-server-and-external-provisioner/nfs-server-provisioner --set 'storageClass.mountOptions={vers=4.1}' --set persistence.enabled=true --set persistence.size=8Gi
```

Install ERPNext using the `nfs` storage class.

```shell
kubectl create namespace erpnext
helm repo add frappe https://helm.erpnext.com
helm upgrade --install frappe-bench --namespace erpnext frappe/erpnext --set persistence.worker.storageClass=nfs
```

# Contents

1. [Introduction](#introduction)
2. [Parameters](#parameters)
3. [Requirements](#requirements)
    1. [Storage Class with ReadWriteMany access mode](#storage-class-with-readwritemany-access-mode)
    2. [Database](#database)
    3. [Managed Redis](#managed-redis)
4. [Installation](#installation)
    1. [Existing PVC](#existing-pvc)
    2. [Existing Storage Class](#existing-storage-class)
    3. [External Database](#external-database)
    4. [External Redis](#external-redis)
    5. [Install Helm Chart](#install-helm-chart)
5. [Generate Additional Resources](#generate-additional-resources)
    1. [Create new site](#create-new-site)
    2. [Create Ingress](#create-ingress)
    3. [Backup site](#backup-site)
    4. [Migrate site](#migrate-site)
    5. [Drop Site](#drop-site)
    6. [Configure service hosts](#configure-service-hosts)
    7. [Fix volume permission](#fix-volume-permission)
6. [Uninstall the Chart](#uninstall-the-chart)
7. [Migrate from Helm Chart 3.x.x to 4.x.x](#migrate-from-helm-chart-3xx-to-4xx)

## Introduction

This chart bootstraps a [Frappe/ERPNext](https://github.com/frappe/frappe_docker) deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Parameters

The following table lists the configurable parameters of the ERPNext chart and their default values.

### erpnext

![Version: 7.0.171](https://img.shields.io/badge/Version-7.0.171-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v15.53.4](https://img.shields.io/badge/AppVersion-v15.53.4-informational?style=flat-square)

Kubernetes Helm Chart for ERPNext and Frappe Framework Apps.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | mariadb | 11.5.7 |
| https://charts.bitnami.com/bitnami | postgresql | 12.1.6 |
| https://charts.bitnami.com/bitnami | redis-cache(redis) | 17.15.2 |
| https://charts.bitnami.com/bitnami | redis-queue(redis) | 17.15.2 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"frappe/erpnext"` |  |
| image.tag | string | `"v15.53.4"` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"erp.cluster.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| jobs.backup.affinity | object | `{}` |  |
| jobs.backup.backoffLimit | int | `0` |  |
| jobs.backup.enabled | bool | `false` |  |
| jobs.backup.nodeSelector | object | `{}` |  |
| jobs.backup.resources | object | `{}` |  |
| jobs.backup.siteName | string | `"erp.cluster.local"` |  |
| jobs.backup.tolerations | list | `[]` |  |
| jobs.backup.withFiles | bool | `true` |  |
| jobs.configure.affinity | object | `{}` |  |
| jobs.configure.args | list | `[]` |  |
| jobs.configure.backoffLimit | int | `0` |  |
| jobs.configure.command | list | `[]` |  |
| jobs.configure.enabled | bool | `true` |  |
| jobs.configure.envVars | list | `[]` |  |
| jobs.configure.fixVolume | bool | `true` |  |
| jobs.configure.nodeSelector | object | `{}` |  |
| jobs.configure.resources | object | `{}` |  |
| jobs.configure.tolerations | list | `[]` |  |
| jobs.createSite.adminExistingSecret | string | `""` |  |
| jobs.createSite.adminExistingSecretKey | string | `"password"` |  |
| jobs.createSite.adminPassword | string | `"changeit"` |  |
| jobs.createSite.affinity | object | `{}` |  |
| jobs.createSite.backoffLimit | int | `0` |  |
| jobs.createSite.dbType | string | `"mariadb"` |  |
| jobs.createSite.enabled | bool | `false` |  |
| jobs.createSite.forceCreate | bool | `false` |  |
| jobs.createSite.installApps[0] | string | `"erpnext"` |  |
| jobs.createSite.nodeSelector | object | `{}` |  |
| jobs.createSite.resources | object | `{}` |  |
| jobs.createSite.siteName | string | `"erp.cluster.local"` |  |
| jobs.createSite.tolerations | list | `[]` |  |
| jobs.custom.affinity | object | `{}` |  |
| jobs.custom.backoffLimit | int | `0` |  |
| jobs.custom.containers | list | `[]` |  |
| jobs.custom.enabled | bool | `false` |  |
| jobs.custom.initContainers | list | `[]` |  |
| jobs.custom.jobName | string | `""` |  |
| jobs.custom.labels | object | `{}` |  |
| jobs.custom.nodeSelector | object | `{}` |  |
| jobs.custom.restartPolicy | string | `"Never"` |  |
| jobs.custom.tolerations | list | `[]` |  |
| jobs.custom.volumes | list | `[]` |  |
| jobs.dropSite.affinity | object | `{}` |  |
| jobs.dropSite.backoffLimit | int | `0` |  |
| jobs.dropSite.enabled | bool | `false` |  |
| jobs.dropSite.forced | bool | `false` |  |
| jobs.dropSite.nodeSelector | object | `{}` |  |
| jobs.dropSite.resources | object | `{}` |  |
| jobs.dropSite.siteName | string | `"erp.cluster.local"` |  |
| jobs.dropSite.tolerations | list | `[]` |  |
| jobs.migrate.affinity | object | `{}` |  |
| jobs.migrate.backoffLimit | int | `0` |  |
| jobs.migrate.enabled | bool | `false` |  |
| jobs.migrate.nodeSelector | object | `{}` |  |
| jobs.migrate.resources | object | `{}` |  |
| jobs.migrate.siteName | string | `"erp.cluster.local"` |  |
| jobs.migrate.skipFailing | bool | `false` |  |
| jobs.migrate.tolerations | list | `[]` |  |
| jobs.volumePermissions.affinity | object | `{}` |  |
| jobs.volumePermissions.backoffLimit | int | `0` |  |
| jobs.volumePermissions.enabled | bool | `false` |  |
| jobs.volumePermissions.nodeSelector | object | `{}` |  |
| jobs.volumePermissions.resources | object | `{}` |  |
| jobs.volumePermissions.tolerations | list | `[]` |  |
| mariadb.auth.password | string | `"changeit"` |  |
| mariadb.auth.replicationPassword | string | `"changeit"` |  |
| mariadb.auth.rootPassword | string | `"changeit"` |  |
| mariadb.auth.username | string | `"erpnext"` |  |
| mariadb.enabled | bool | `true` |  |
| mariadb.primary.extraFlags | string | `"--skip-character-set-client-handshake --skip-innodb-read-only-compressed --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci"` |  |
| mariadb.primary.service.ports.mysql | int | `3306` |  |
| nameOverride | string | `""` |  |
| nginx.affinity | object | `{}` |  |
| nginx.autoscaling.enabled | bool | `false` |  |
| nginx.autoscaling.maxReplicas | int | `3` |  |
| nginx.autoscaling.minReplicas | int | `1` |  |
| nginx.autoscaling.targetCPU | int | `75` |  |
| nginx.autoscaling.targetMemory | int | `75` |  |
| nginx.defaultTopologySpread.maxSkew | int | `1` |  |
| nginx.defaultTopologySpread.topologyKey | string | `"kubernetes.io/hostname"` |  |
| nginx.defaultTopologySpread.whenUnsatisfiable | string | `"DoNotSchedule"` |  |
| nginx.envVars | list | `[]` |  |
| nginx.environment.clientMaxBodySize | string | `"50m"` |  |
| nginx.environment.frappeSiteNameHeader | string | `"$host"` |  |
| nginx.environment.proxyReadTimeout | string | `"120"` |  |
| nginx.environment.upstreamRealIPAddress | string | `"127.0.0.1"` |  |
| nginx.environment.upstreamRealIPHeader | string | `"X-Forwarded-For"` |  |
| nginx.environment.upstreamRealIPRecursive | string | `"off"` |  |
| nginx.initContainers | list | `[]` |  |
| nginx.livenessProbe.initialDelaySeconds | int | `5` |  |
| nginx.livenessProbe.periodSeconds | int | `10` |  |
| nginx.livenessProbe.tcpSocket.port | int | `8080` |  |
| nginx.nodeSelector | object | `{}` |  |
| nginx.readinessProbe.initialDelaySeconds | int | `5` |  |
| nginx.readinessProbe.periodSeconds | int | `10` |  |
| nginx.readinessProbe.tcpSocket.port | int | `8080` |  |
| nginx.replicaCount | int | `1` |  |
| nginx.resources | object | `{}` |  |
| nginx.service.port | int | `8080` |  |
| nginx.service.type | string | `"ClusterIP"` |  |
| nginx.sidecars | list | `[]` |  |
| nginx.tolerations | list | `[]` |  |
| persistence.logs.accessModes[0] | string | `"ReadWriteMany"` |  |
| persistence.logs.enabled | bool | `false` |  |
| persistence.logs.size | string | `"8Gi"` |  |
| persistence.worker.accessModes[0] | string | `"ReadWriteMany"` |  |
| persistence.worker.enabled | bool | `true` |  |
| persistence.worker.size | string | `"8Gi"` |  |
| podSecurityContext.supplementalGroups[0] | int | `1000` |  |
| postgresql.auth.postgresPassword | string | `"changeit"` |  |
| postgresql.auth.username | string | `"postgres"` |  |
| postgresql.enabled | bool | `false` |  |
| postgresql.primary.service.ports.postgresql | int | `5432` |  |
| redis-cache.architecture | string | `"standalone"` |  |
| redis-cache.auth.enabled | bool | `false` |  |
| redis-cache.auth.sentinel | bool | `false` |  |
| redis-cache.enabled | bool | `true` |  |
| redis-cache.master.containerPorts.redis | int | `6379` |  |
| redis-cache.master.persistence.enabled | bool | `false` |  |
| redis-queue.architecture | string | `"standalone"` |  |
| redis-queue.auth.enabled | bool | `false` |  |
| redis-queue.auth.sentinel | bool | `false` |  |
| redis-queue.enabled | bool | `true` |  |
| redis-queue.master.containerPorts.redis | int | `6379` |  |
| redis-queue.master.persistence.enabled | bool | `false` |  |
| securityContext.capabilities.add[0] | string | `"CAP_CHOWN"` |  |
| serviceAccount.create | bool | `true` |  |
| socketio.affinity | object | `{}` |  |
| socketio.autoscaling.enabled | bool | `false` |  |
| socketio.autoscaling.maxReplicas | int | `3` |  |
| socketio.autoscaling.minReplicas | int | `1` |  |
| socketio.autoscaling.targetCPU | int | `75` |  |
| socketio.autoscaling.targetMemory | int | `75` |  |
| socketio.envVars | list | `[]` |  |
| socketio.initContainers | list | `[]` |  |
| socketio.livenessProbe.initialDelaySeconds | int | `5` |  |
| socketio.livenessProbe.periodSeconds | int | `10` |  |
| socketio.livenessProbe.tcpSocket.port | int | `9000` |  |
| socketio.nodeSelector | object | `{}` |  |
| socketio.readinessProbe.initialDelaySeconds | int | `5` |  |
| socketio.readinessProbe.periodSeconds | int | `10` |  |
| socketio.readinessProbe.tcpSocket.port | int | `9000` |  |
| socketio.replicaCount | int | `1` |  |
| socketio.resources | object | `{}` |  |
| socketio.service.port | int | `9000` |  |
| socketio.service.type | string | `"ClusterIP"` |  |
| socketio.sidecars | list | `[]` |  |
| socketio.tolerations | list | `[]` |  |
| worker.default.affinity | object | `{}` |  |
| worker.default.autoscaling.enabled | bool | `false` |  |
| worker.default.autoscaling.maxReplicas | int | `3` |  |
| worker.default.autoscaling.minReplicas | int | `1` |  |
| worker.default.autoscaling.targetCPU | int | `75` |  |
| worker.default.autoscaling.targetMemory | int | `75` |  |
| worker.default.envVars | list | `[]` |  |
| worker.default.initContainers | list | `[]` |  |
| worker.default.livenessProbe.override | bool | `false` |  |
| worker.default.livenessProbe.probe | object | `{}` |  |
| worker.default.nodeSelector | object | `{}` |  |
| worker.default.readinessProbe.override | bool | `false` |  |
| worker.default.readinessProbe.probe | object | `{}` |  |
| worker.default.replicaCount | int | `1` |  |
| worker.default.resources | object | `{}` |  |
| worker.default.sidecars | list | `[]` |  |
| worker.default.tolerations | list | `[]` |  |
| worker.defaultTopologySpread.maxSkew | int | `1` |  |
| worker.defaultTopologySpread.topologyKey | string | `"kubernetes.io/hostname"` |  |
| worker.defaultTopologySpread.whenUnsatisfiable | string | `"DoNotSchedule"` |  |
| worker.gunicorn.affinity | object | `{}` |  |
| worker.gunicorn.args | list | `[]` |  |
| worker.gunicorn.autoscaling.enabled | bool | `false` |  |
| worker.gunicorn.autoscaling.maxReplicas | int | `3` |  |
| worker.gunicorn.autoscaling.minReplicas | int | `1` |  |
| worker.gunicorn.autoscaling.targetCPU | int | `75` |  |
| worker.gunicorn.autoscaling.targetMemory | int | `75` |  |
| worker.gunicorn.envVars | list | `[]` |  |
| worker.gunicorn.initContainers | list | `[]` |  |
| worker.gunicorn.livenessProbe.initialDelaySeconds | int | `5` |  |
| worker.gunicorn.livenessProbe.periodSeconds | int | `10` |  |
| worker.gunicorn.livenessProbe.tcpSocket.port | int | `8000` |  |
| worker.gunicorn.nodeSelector | object | `{}` |  |
| worker.gunicorn.readinessProbe.initialDelaySeconds | int | `5` |  |
| worker.gunicorn.readinessProbe.periodSeconds | int | `10` |  |
| worker.gunicorn.readinessProbe.tcpSocket.port | int | `8000` |  |
| worker.gunicorn.replicaCount | int | `1` |  |
| worker.gunicorn.resources | object | `{}` |  |
| worker.gunicorn.service.port | int | `8000` |  |
| worker.gunicorn.service.type | string | `"ClusterIP"` |  |
| worker.gunicorn.sidecars | list | `[]` |  |
| worker.gunicorn.tolerations | list | `[]` |  |
| worker.healthProbe | string | `"exec:\n  command:\n    - bash\n    - -c\n    - echo \"Ping backing services\";\n    {{- if .Values.mariadb.enabled }}\n    {{- if eq .Values.mariadb.architecture \"replication\" }}\n    - wait-for-it {{ .Release.Name }}-mariadb-primary:{{ .Values.mariadb.primary.service.ports.mysql }} -t 1;\n    {{- else }}\n    - wait-for-it {{ .Release.Name }}-mariadb:{{ .Values.mariadb.primary.service.ports.mysql }} -t 1;\n    {{- end }}\n    {{- else if .Values.dbHost }}\n    - wait-for-it {{ .Values.dbHost }}:{{ .Values.mariadb.primary.service.ports.mysql }} -t 1;\n    {{- end }}\n    {{- if index .Values \"redis-cache\" \"host\" }}\n    - wait-for-it {{ .Release.Name }}-redis-cache-master:{{ index .Values \"redis-cache\" \"master\" \"containerPorts\" \"redis\" }} -t 1;\n    {{- else if index .Values \"redis-cache\" \"host\" }}\n    - wait-for-it {{ index .Values \"redis-cache\" \"host\" }} -t 1;\n    {{- end }}\n    {{- if index .Values \"redis-queue\" \"host\" }}\n    - wait-for-it {{ .Release.Name }}-redis-queue-master:{{ index .Values \"redis-queue\" \"master\" \"containerPorts\" \"redis\" }} -t 1;\n    {{- else if index .Values \"redis-queue\" \"host\" }}\n    - wait-for-it {{ index .Values \"redis-queue\" \"host\" }} -t 1;\n    {{- end }}\n    {{- if .Values.postgresql.host }}\n    - wait-for-it {{ .Values.postgresql.host }}:{{ .Values.postgresql.primary.service.ports.postgresql }} -t 1;\n    {{- else if .Values.postgresql.enabled }}\n    - wait-for-it {{ .Release.Name }}-postgresql:{{ .Values.postgresql.primary.service.ports.postgresql }} -t 1;\n    {{- end }}\ninitialDelaySeconds: 15\nperiodSeconds: 5\n"` |  |
| worker.long.affinity | object | `{}` |  |
| worker.long.autoscaling.enabled | bool | `false` |  |
| worker.long.autoscaling.maxReplicas | int | `3` |  |
| worker.long.autoscaling.minReplicas | int | `1` |  |
| worker.long.autoscaling.targetCPU | int | `75` |  |
| worker.long.autoscaling.targetMemory | int | `75` |  |
| worker.long.envVars | list | `[]` |  |
| worker.long.initContainers | list | `[]` |  |
| worker.long.livenessProbe.override | bool | `false` |  |
| worker.long.livenessProbe.probe | object | `{}` |  |
| worker.long.nodeSelector | object | `{}` |  |
| worker.long.readinessProbe.override | bool | `false` |  |
| worker.long.readinessProbe.probe | object | `{}` |  |
| worker.long.replicaCount | int | `1` |  |
| worker.long.resources | object | `{}` |  |
| worker.long.sidecars | list | `[]` |  |
| worker.long.tolerations | list | `[]` |  |
| worker.scheduler.affinity | object | `{}` |  |
| worker.scheduler.envVars | list | `[]` |  |
| worker.scheduler.initContainers | list | `[]` |  |
| worker.scheduler.livenessProbe.override | bool | `false` |  |
| worker.scheduler.livenessProbe.probe | object | `{}` |  |
| worker.scheduler.nodeSelector | object | `{}` |  |
| worker.scheduler.readinessProbe.override | bool | `false` |  |
| worker.scheduler.readinessProbe.probe | object | `{}` |  |
| worker.scheduler.replicaCount | int | `1` |  |
| worker.scheduler.resources | object | `{}` |  |
| worker.scheduler.sidecars | list | `[]` |  |
| worker.scheduler.tolerations | list | `[]` |  |
| worker.short.affinity | object | `{}` |  |
| worker.short.autoscaling.enabled | bool | `false` |  |
| worker.short.autoscaling.maxReplicas | int | `3` |  |
| worker.short.autoscaling.minReplicas | int | `1` |  |
| worker.short.autoscaling.targetCPU | int | `75` |  |
| worker.short.autoscaling.targetMemory | int | `75` |  |
| worker.short.envVars | list | `[]` |  |
| worker.short.initContainers | list | `[]` |  |
| worker.short.livenessProbe.override | bool | `false` |  |
| worker.short.livenessProbe.probe | object | `{}` |  |
| worker.short.nodeSelector | object | `{}` |  |
| worker.short.readinessProbe.override | bool | `false` |  |
| worker.short.readinessProbe.probe | object | `{}` |  |
| worker.short.replicaCount | int | `1` |  |
| worker.short.resources | object | `{}` |  |
| worker.short.sidecars | list | `[]` |  |
| worker.short.tolerations | list | `[]` |  |

----------------------------------------------

The above parameters map to the env variables defined in [frappe_docker](http://github.com/frappe/frappe_docker). For more information please refer to the [frappe_docker](http://github.com/frappe/frappe_docker) images documentation.

## Requirements

### Storage Class with ReadWriteMany access mode

Frappe framework sites are stored in shared volume that needs to be accessed by multiple pods. Read more about [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes). Here are some alternatives available for RWX volumes.

- [AWS EFS](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html): Managed shared filesystem by Amazon.
- [Google Filestore](https://cloud.google.com/filestore): Managed shared filesystem by Google.
- [AzureFile](https://docs.microsoft.com/en-us/azure/aks/azure-files-dynamic-pv): Managed shared filesystem by Microsoft.
- [External NFS Server](https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner): Provisioner based on NFS server setup outside cluster. Separately hosted NFS server is needed in this case.
- [In-cluster NFS Server](https://kubernetes-sigs.github.io/nfs-ganesha-server-and-external-provisioner): Provisioner based on in-cluster NFS server.
- [More Cloud Native Storage alternatives](https://landscape.cncf.io/card-mode?category=cloud-native-storage&grouping=category): Make sure the `storageclass` has `ReadWriteMany` access mode to use it as storage for sites.

> **Note**: If you are running a single-node cluster or deploying to a specific node using node affinity, you can use ReadWriteOnce (RWO) access mode if your storage class supports it. This is because all pods will be scheduled on the same node, eliminating the need for multi-node access.

### Database

By default it installs pre configured MariaDB that works with Frappe/ERPNext sites.

PostgreSQL works with custom frappe apps only. ERPNext needs MariaDB.

Recommended alternatives as per priority:

- [Managed DB](https://github.com/frappe/frappe/wiki/Using-Frappe-with-Amazon-RDS-(or-any-other-DBaaS)): Recommended AWS MariaDB RDS.
- [Self hosted MariaDB](https://github.com/frappe/frappe/wiki/Setup-MariaDB-Server): Self hosted mariadb server setup for Debian or Ubuntu.
- [In-cluster MariaDB](https://github.com/bitnami/charts/tree/main/bitnami/mariadb): It is used as sub-chart for this helm chart.

### Managed Redis

Managed Redis is not recommended. Redis is used as in-memory database and having it in the cluster will have least latency. Any managed Redis service with no auth and no ssl will work. It needs to be under VPC and protected by firewall. Check the [External Redis](#external-redis) section.

## Installation

Customize values for following alternatives.

### Existing Storage Class

Make following changes to `custom-values.yaml`:

```yaml
persistence:
  worker:
    storageClass: "rook-cephfs"
```

Make sure the storage class called `rook-cephfs` is available on the cluster.

### Existing PVC

Make following changes to `custom-values.yaml`:

```yaml
persistence:
  worker:
    existingClaim: existing-sites
```

Make sure the PVC called `existing-sites` exists in the namespace.

### Access Modes

Make following changes to custom-values.yaml:

```yaml
persistence:
  worker:
    accessModes:
      - ReadWriteMany  # default mode
```

You can configure this to use ReadWriteOnce (RWO) if you are running a single-node cluster or deploying to a specific node using node affinity.

### External Database

Make following changes to `custom-values.yaml`:

```yaml
dbHost: "1.2.3.4"
dbPort: "3306"
dbRootUser: "admin"
dbRootPassword: "secret"
```

Make sure the db host, db port and credentials are correct.

### External Redis

Make following changes to `custom-values.yaml`:

```yaml
redis-cache:
  enabled: false
  host: "redis://1.1.1.1:6379"
redis-queue:
  enabled: false
  host: "redis://2.2.2.2:6379"
```

Make sure the redis hosts are correct.

### Install Helm Chart

Create namespace for erpnext

```shell
kubectl create namespace erpnext
```

Add helm frappe helm repo

```shell
helm repo add frappe https://helm.erpnext.com
```

Install helm chart and create release

```shell
helm install frappe-bench -n erpnext -f custom-values.yaml frappe/erpnext
```

For rest of the document `frappe-bench` is treated as the helm release name and `custom-values.yaml` file will contain required values to override.

## Generate Additional Resources

These resources can be generated and created along with installation and upgrade of the helm release.
Instead of doing that we can have better control if we use `helm template` command and generate the required resources. That way we get yaml files that can also be committed to gitops repo. Generating same job multiple times will not cause any problem as the job names will have Unix timestamp.

Following sections discuss different resources that can be created using `helm template` command.

### Create new site

Make following changes to `custom-values.yaml`:

```yaml
jobs:
  createSite:
    enabled: true
    siteName: "erp.example.com"
    adminPassword: "secret"
```

Note: `erp.example.com` must be configured DNS entry and change the `adminPassword` to something more secure.

Generate Job YAML

```shell
helm template frappe-bench -n erpnext frappe/erpnext -f custom-values.yaml -s templates/job-create-site.yaml > create-new-site-job.yaml
```

Create Job resource

```shell
kubectl apply -f create-new-site-job.yaml
```

### Create Ingress

Make following changes to `custom-values.yaml`:

```yaml
ingress:
  enabled: true
  ingressName: "erp-example-com"
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
  hosts:
  - host: erp.example.com
    paths:
    - path: /
      pathType: ImplementationSpecific
  tls:
   - secretName: erp-example-com-tls
     hosts:
       - erp.example.com
```

Note:

- `erp.example.com` must be configured DNS entry.
- Change `annotations` as per requirement.
- Change `secretName` as per convenience.

Generate Ingress YAML

```shell
helm template frappe-bench -n erpnext frappe/erpnext -f custom-values.yaml -s templates/ingress.yaml > ingress.yaml
```

Create Ingress resource

```shell
kubectl apply -f ingress.yaml
```

### Backup site

Make following changes to `custom-values.yaml`:

```yaml
jobs:
  backup:
    enabled: true
    siteName: "erp.example.com"
    withFiles: true
    push:
      enabled: false
      bucket: "erpnext"
      region: "us-east-1"
      accessKey: "ACCESSKEY"
      secretKey: "SECRETKEY"
      endpoint: http://store.storage.svc.cluster.local
```

Note:

- Site `erp.example.com` must exist.
- To push backup to S3, enter S3 credentials and set `jobs.backup.push.enabled` to `true`.

Generate Job YAML

```shell
helm template frappe-bench -n erpnext frappe/erpnext -f custom-values.yaml -s templates/job-backup.yaml > job-backup.yaml
```

Create Job resource

```shell
kubectl apply -f job-backup.yaml
```

### Migrate site

Make following changes to `custom-values.yaml`:

```yaml
jobs:
  migrate:
    enabled: true
    siteName: "erp.example.com"
```

Note: Site `erp.example.com` must exist.

Generate Job YAML

```shell
helm template frappe-bench -n erpnext frappe/erpnext -f custom-values.yaml -s templates/job-migrate-site.yaml > job-migrate-site.yaml
```

Create Job resource

```shell
kubectl apply -f job-migrate-site.yaml
```

### Drop site

Make following changes to `custom-values.yaml`:

```yaml
jobs:
  dropSite:
    enabled: true
    siteName: "erp.example.com"
```

Note: Site `erp.example.com` must exist.

Generate Job YAML

```shell
helm template frappe-bench -n erpnext frappe/erpnext -f custom-values.yaml -s templates/job-drop-site.yaml > job-drop-site.yaml
```

Create Job resource

```shell
kubectl apply -f job-drop-site.yaml
```

### Configure service hosts

By default this job configures service hosts automatically as per name of the helm release.

To manually set hosts make following changes to `custom-values.yaml`:

```yaml
mariadb:
  enabled: false

dbHost: "db-instance.123456789012.us-east-1.rds.amazonaws.com"

dbPort: 3306

redis-cache:
  enabled: false
  host: redis://redis-cache.7abc2d.0001.usw2.cache.amazonaws.com:6379

redis-queue:
  enabled: false
  host: redis://redis-queue.7abc2d.0001.usw2.cache.amazonaws.com:6379

jobs:
  configure:
    enabled: true
    fixVolume: true
```

Notes:

- Change the hosts as per configuration
- If `jobs.configure.fixVolume` is set to `true` it will run command as root to change ownership of files and directories in volume.

Generate Job YAML

```shell
helm template frappe-bench -n erpnext frappe/erpnext -f custom-values.yaml -s templates/job-configure-bench.yaml > job-configure-bench.yaml
```

Create Job resource

```shell
kubectl apply -f job-configure-bench.yaml
```

### Fix volume permission

Make following changes to `custom-values.yaml`:

```yaml
jobs:
  volumePermissions:
    enabled: true
```

Generate Job YAML

```shell
helm template frappe-bench -n erpnext frappe/erpnext -f custom-values.yaml -s templates/job-fix-volume-permission.yaml > job-fix-volume-permission.yaml
```

Create Job resource

```shell
kubectl apply -f job-fix-volume-permission.yaml
```

## Uninstall the Chart

To uninstall/delete the `frappe-bench` release:

```shell
helm --namespace erpnext delete frappe-bench
```

The command removes all the Kubernetes components installed by the chart and deletes the release.

## Migrate from Helm Chart 3.x.x to 4.x.x

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
