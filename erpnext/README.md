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

| Parameter                                             | Description                                                                                                                | Default                                  |
|-------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|------------------------------------------|
| `dbHost`                                              | Database host for the bench to connect                                                                                     | `nil`                                    |
| `dbPort`                                              | Database port for the bench to connect                                                                                     | `3306`                                   |
| `dbRootUser`                                          | Database root user for the conneted database service                                                                       | `nil`                                    |
| `dbRootPassword`                                      | Database root password for the conneted database service                                                                   | `nil`                                    |
| `dbRds`                                               | Enable when using an RDS database                                                                                          | `false`                                  |
| `image.repository`                                    | Image repository deployment                                                                                                | `frappe/erpnext`                         |
| `image.tag`                                           | Image tag deployment                                                                                                       | `latest stable tag`                      |
| `image.pullPolicy`                                    | imagePullPolicy deployment                                                                                                 | `IfNotPresent`                           |
| `nginx.replicaCount`                                  | Replica count for nginx deployment                                                                                         | `1`                                      |
| `nginx.autoscaling.enabled`                           | Create HPA for nginx deployment                                                                                            | `false`                                  |
| `nginx.autoscaling.minReplicas`                       | Minimum Replica count for nginx deployment                                                                                 | `1`                                      |
| `nginx.autoscaling.maxReplicas`                       | Maximum Replica count for nginx deployment                                                                                 | `3`                                      |
| `nginx.autoscaling.targetCPU`                         | Target CPU to trigger auto scale for nginx deployment                                                                      | `75`                                     |
| `nginx.autoscaling.targetMemory`                      | Target Memory to trigger auto scale for nginx deployment                                                                   | `75`                                     |
| `nginx.config`                                        | Custom nginx config for /etc/nginx/conf.d/default.conf.                                                                    | `nil`                                    |
| `nginx.environment.upstreamRealIPAddress`             | http://nginx.org/en/docs/http/ngx_http_realip_module.html#set_real_ip_from                                                 | `127.0.0.1`                              |
| `nginx.environment.upstreamRealIPRecursive`           | http://nginx.org/en/docs/http/ngx_http_realip_module.html#real_ip_recursive                                                | `off`                                    |
| `nginx.environment.upstreamRealIPHeader`              | http://nginx.org/en/docs/http/ngx_http_realip_module.html#real_ip_header                                                   | `X-Forwarded-For`                        |
| `nginx.environment.frappeSiteNameHeader`              | Default value is `$host` which resolves site by host. Set it to name of the site to serve only that site                   | `$host`                                  |
| `nginx.livenessProbe`                                 | Liveness probe for nginx deployment                                                                                        | `Probe to ping port 8080`                |
| `nginx.readinessProbe`                                | Readiess probe for nginx deployment                                                                                        | `Probe to ping port 8080`                |
| `nginx.service.type`                                  | Service type for nginx service                                                                                             | `ClusterIP`                              |
| `nginx.service.port`                                  | Service port for nginx service                                                                                             | `8080`                                   |
| `nginx.resources`                                     | Container resources for nginx deployment pods                                                                              | `{}`                                     |
| `nginx.nodeSelector`                                  | Pod nodeSelector for nginx deployment pods                                                                                 | `{}`                                     |
| `nginx.tolerations`                                   | Pod tolerations for nginx deployment pods                                                                                  | `[]`                                     |
| `nginx.affinity`                                      | Pod affinity for nginx deployment pods                                                                                     | `{}`                                     |
| `nginx.envVars`                                       | Additional environment variables for nginx deployment pods                                                                 | `[]`                                     |
| `nginx.initContainers`                                | Additional initContainers for nginx deployment pods                                                                        | `[]`                                     |
| `nginx.sidecars`                                      | Additional sideCars for nginx deployment pods                                                                              | `[]`                                     |
| `worker.gunicorn.replicaCount`                        | Replica count for gunicorn deployment                                                                                      | `1`                                      |
| `worker.gunicorn.autoscaling.enabled`                 | Create HPA for gunicorn deployment                                                                                         | `false`                                  |
| `worker.gunicorn.autoscaling.minReplicas`             | Minimum Replica count for gunicorn deployment                                                                              | `1`                                      |
| `worker.gunicorn.autoscaling.maxReplicas`             | Maximum Replica count for gunicorn deployment                                                                              | `3`                                      |
| `worker.gunicorn.autoscaling.targetCPU`               | Target CPU to trigger auto scale for gunicorn deployment                                                                   | `75`                                     |
| `worker.gunicorn.autoscaling.targetMemory`            | Target Memory to trigger auto scale for gunicorn deployment                                                                | `75`                                     |
| `worker.gunicorn.livenessProbe`                       | Liveness probe for gunicorn deployment                                                                                     | `{}`                                     |
| `worker.gunicorn.readinessProbe`                      | Readiess probe for gunicorn deployment                                                                                     | `{}`                                     |
| `worker.gunicorn.service.type`                        | Service type for gunicorn service                                                                                          | `ClusterIP`                              |
| `worker.gunicorn.service.port`                        | Service port for gunicorn service                                                                                          | `8000`                                   |
| `worker.gunicorn.args`                                | Override container args for gunicorn deployment                                                                            | `Use gevent worker class`                |
| `worker.gunicorn.resources`                           | Container resources for gunicorn deployment pods                                                                           | `{}`                                     |
| `worker.gunicorn.nodeSelector`                        | Pod nodeSelector for gunicorn deployment pods                                                                              | `{}`                                     |
| `worker.gunicorn.tolerations`                         | Pod tolerations for gunicorn deployment pods                                                                               | `[]`                                     |
| `worker.gunicorn.affinity`                            | Pod affinity for gunicorn deployment pods                                                                                  | `{}`                                     |
| `worker.gunicorn.envVars`                             | Additional environment variables for gunicorn deployment pods                                                              | `[]`                                     |
| `worker.gunicorn.initContainers`                      | Additional initContainers for gunicorn deployment pods                                                                     | `[]`                                     |
| `worker.gunicorn.sidecars`                            | Additional sideCars for gunicorn deployment pods                                                                           | `[]`                                     |
| `worker.default.replicaCount`                         | Replica count for default worker deployment                                                                                | `1`                                      |
| `worker.default.autoscaling.enabled`                 | Create HPA for default worker deployment                                                                                    | `false`                                  |
| `worker.default.autoscaling.minReplicas`             | Minimum Replica count for default worker deployment                                                                         | `1`                                      |
| `worker.default.autoscaling.maxReplicas`             | Maximum Replica count for default worker deployment                                                                         | `3`                                      |
| `worker.default.autoscaling.targetCPU`               | Target CPU to trigger auto scale for default worker deployment                                                              | `75`                                     |
| `worker.default.autoscaling.targetMemory`            | Target Memory to trigger auto scale for default worker deployment                                                           | `75`                                     |
| `worker.default.livenessProbe.override`               | Enable liveness probe override for default worker deployment                                                               | `false`                                  |
| `worker.default.livenessProbe.probe`                  | Liveness probe for default worker deployment                                                                               | `{}`                                     |
| `worker.default.readinessProbe.override`              | Enable readiness probe override for default worker deployment                                                              | `false`                                  |
| `worker.default.readinessProbe.probe`                 | Readiess probe for default worker deployment                                                                               | `{}`                                     |
| `worker.default.resources`                            | Container resources for default worker deployment pods                                                                     | `{}`                                     |
| `worker.default.nodeSelector`                         | Pod nodeSelector for default worker deployment pods                                                                        | `{}`                                     |
| `worker.default.tolerations`                          | Pod tolerations for default worker deployment pods                                                                         | `[]`                                     |
| `worker.default.affinity`                             | Pod affinity for default worker deployment pods                                                                            | `{}`                                     |
| `worker.default.envVars`                              | Additional environment variables for default worker deployment pods                                                        | `[]`                                     |
| `worker.default.initContainers`                       | Additional initContainers for default worker deployment pods                                                               | `[]`                                     |
| `worker.default.sidecars`                             | Additional sideCars for default worker deployment pods                                                                     | `[]`                                     |
| `worker.short.replicaCount`                           | Replica count for short worker deployment                                                                                  | `1`                                      |
| `worker.short.autoscaling.enabled`                    | Create HPA for short worker deployment                                                                                     | `false`                                  |
| `worker.short.autoscaling.minReplicas`                | Minimum Replica count for short worker deployment                                                                          | `1`                                      |
| `worker.short.autoscaling.maxReplicas`                | Maximum Replica count for short worker deployment                                                                          | `3`                                      |
| `worker.short.autoscaling.targetCPU`                  | Target CPU to trigger auto scale for short worker deployment                                                               | `75`                                     |
| `worker.short.autoscaling.targetMemory`               | Target Memory to trigger auto scale for short worker deployment                                                            | `75`                                     |
| `worker.short.livenessProbe.override`                 | Enable liveness probe override for short worker deployment                                                                 | `false`                                  |
| `worker.short.livenessProbe.probe`                    | Liveness probe for short worker deployment                                                                                 | `{}`                                     |
| `worker.short.readinessProbe.override`                | Enable readiness probe override for short worker deployment                                                                | `false`                                  |
| `worker.short.readinessProbe.probe`                   | Readiess probe for short worker deployment                                                                                 | `{}`                                     |
| `worker.short.resources`                              | Container resources for short worker deployment pods                                                                       | `{}`                                     |
| `worker.short.nodeSelector`                           | Pod nodeSelector for short worker deployment pods                                                                          | `{}`                                     |
| `worker.short.tolerations`                            | Pod tolerations for short worker deployment pods                                                                           | `[]`                                     |
| `worker.short.affinity`                               | Pod affinity for short worker deployment pods                                                                              | `{}`                                     |
| `worker.short.envVars`                                | Additional environment variables for short worker deployment pods                                                          | `[]`                                     |
| `worker.short.initContainers`                         | Additional initContainers for short worker deployment pods                                                                 | `[]`                                     |
| `worker.short.sidecars`                               | Additional sideCars for short worker deployment pods                                                                       | `[]`                                     |
| `worker.long.replicaCount`                            | Replica count for long worker deployment                                                                                   | `1`                                      |
| `worker.long.autoscaling.enabled`                     | Create HPA for long worker deployment                                                                                      | `false`                                  |
| `worker.long.autoscaling.minReplicas`                 | Minimum Replica count for long worker deployment                                                                           | `1`                                      |
| `worker.long.autoscaling.maxReplicas`                 | Maximum Replica count for long worker deployment                                                                           | `3`                                      |
| `worker.long.autoscaling.targetCPU`                   | Target CPU to trigger auto scale for long worker deployment                                                                | `75`                                     |
| `worker.long.autoscaling.targetMemory`                | Target Memory to trigger auto scale for long worker deployment                                                             | `75`                                     |
| `worker.long.livenessProbe.override`                  | Enable liveness probe override for long worker deployment                                                                  | `false`                                  |
| `worker.long.livenessProbe.probe`                     | Liveness probe for long worker deployment                                                                                  | `{}`                                     |
| `worker.long.readinessProbe.override`                 | Enable readiness probe override for long worker deployment                                                                 | `false`                                  |
| `worker.long.readinessProbe.probe`                    | Readiess probe for long worker deployment                                                                                  | `{}`                                     |
| `worker.long.resources`                               | Container resources for long worker deployment pods                                                                        | `{}`                                     |
| `worker.long.nodeSelector`                            | Pod nodeSelector for long worker deployment pods                                                                           | `{}`                                     |
| `worker.long.tolerations`                             | Pod tolerations for long worker deployment pods                                                                            | `[]`                                     |
| `worker.long.affinity`                                | Pod affinity for long worker deployment pods                                                                               | `{}`                                     |
| `worker.long.envVars`                                 | Additional environment variables for long worker deployment pods                                                           | `[]`                                     |
| `worker.long.initContainers`                          | Additional initContainers for long worker deployment pods                                                                  | `[]`                                     |
| `worker.long.sidecars`                                | Additional sideCars for long worker deployment pods                                                                        | `[]`                                     |
| `worker.scheduler.replicaCount`                       | Replica count for scheduler deployment                                                                                     | `1`                                      |
| `worker.scheduler.livenessProbe.override`             | Enable liveness probe override for scheduler deployment                                                                    | `false`                                  |
| `worker.scheduler.livenessProbe.probe`                | Liveness probe for scheduler deployment                                                                                    | `{}`                                     |
| `worker.scheduler.readinessProbe.override`            | Enable readiness probe override for scheduler deployment                                                                   | `false`                                  |
| `worker.scheduler.readinessProbe.probe`               | Readiess probe for scheduler deployment                                                                                    | `{}`                                     |
| `worker.scheduler.resources`                          | Container resources for scheduler deployment pods                                                                          | `{}`                                     |
| `worker.scheduler.nodeSelector`                       | Pod nodeSelector for scheduler deployment pods                                                                             | `{}`                                     |
| `worker.scheduler.tolerations`                        | Pod tolerations for scheduler deployment pods                                                                              | `[]`                                     |
| `worker.scheduler.affinity`                           | Pod affinity for scheduler deployment pods                                                                                 | `{}`                                     |
| `worker.scheduler.envVars`                            | Additional environment variables for scheduler deployment pods                                                             | `[]`                                     |
| `worker.scheduler.initContainers`                     | Additional initContainers for scheduler deployment pods                                                                    | `[]`                                     |
| `worker.scheduler.sidecars`                           | Additional sideCars for scheduler deployment pods                                                                          | `[]`                                     |
| `worker.healthProbe`                                  | Helm template string for all worker deployments                                                                            | `YAML Template as string`                |
| `socketio.replicaCount`                               | Replica count for socketio deployment                                                                                      | `1`                                      |
| `socketio.autoscaling.enabled`                        | Create HPA for socketio deployment                                                                                         | `false`                                  |
| `socketio.autoscaling.minReplicas`                    | Minimum Replica count for socketio deployment                                                                              | `1`                                      |
| `socketio.autoscaling.maxReplicas`                    | Maximum Replica count for socketio deployment                                                                              | `3`                                      |
| `socketio.autoscaling.targetCPU`                      | Target CPU to trigger auto scale for socketio deployment                                                                   | `75`                                     |
| `socketio.autoscaling.targetMemory`                   | Target Memory to trigger auto scale for nginx deployment                                                                   | `75`                                     |
| `socketio.livenessProbe`                              | Liveness probe for socketio deployment                                                                                     | `{}`                                     |
| `socketio.readinessProbe`                             | Readiess probe for socketio deployment                                                                                     | `{}`                                     |
| `socketio.service.type`                               | Service type for socketio service                                                                                          | `ClusterIP`                              |
| `socketio.service.port`                               | Service port for socketio service                                                                                          | `9000`                                   |
| `socketio.resources`                                  | Container resources for socketio deployment pods                                                                           | `{}`                                     |
| `socketio.nodeSelector`                               | Pod nodeSelector socketio deployment pods                                                                                  | `{}`                                     |
| `socketio.tolerations`                                | Pod tolerations for socketio deployment pods                                                                               | `[]`                                     |
| `socketio.affinity`                                   | Pod affinity for socketio deployment pods                                                                                  | `{}`                                     |
| `socketio.envVars`                                    | Additional environment variables for socketio deployment pods                                                              | `[]`                                     |
| `socketio.initContainers`                             | Additional initContainers for socketio deployment pods                                                                     | `[]`                                     |
| `socketio.sidecars`                                   | Additional sideCars for socketio deployment pods                                                                           | `[]`                                     |
| `persistence.worker.enabled`                          | Enable volume persistence for all worker deployments                                                                       | `true`                                   |
| `persistence.worker.existingClaim`                    | Use existing RWX persistence volume claim for worker deployments                                                           | `nil`                                    |
| `persistence.worker.size`                             | Size of volume to be created for worker deployments                                                                        | `8Gi`                                    |
| `persistence.worker.storageClass`                     | Storage class to use to create volume for worker deployments. Must be RWX.                                                 | `nil`                                    |
| `persistence.logs.enabled`                            | Enable volume persistence for logs deployments                                                                             | `true`                                   |
| `persistence.logs.existingClaim`                      | Use existing RWX persistence volume claim for logs                                                                         | `nil`                                    |
| `persistence.logs.size`                               | Size of volume to be created for logs                                                                                      | `8Gi`                                    |
| `persistence.logs.storageClass`                       | Storage class to use to create volume for logs. Must be RWX.                                                               | `nil`                                    |
| `ingress.enabled`                                     | Enable ingress for site that will be created                                                                               | `false`                                  |
| `ingress.ingressName`                                 | Override name of the ingress to be created                                                                                 | `nil`                                    |
| `ingress.className`                                   | Class name of the ingress controller                                                                                       | `nil`                                    |
| `ingress.annotations`                                 | Ingress annotations. e.g. for cert-manager.io                                                                              | `{}`                                     |
| `ingress.hosts[0].host`                               | Ingress host                                                                                                               | `erp.cluster.local`                      |
| `ingress.hosts[0].paths[0].path`                      | Ingress path                                                                                                               | `/`                                      |
| `ingress.hosts[0].paths[0].pathType`                  | Ingress pathType                                                                                                           | `ImplementationSpecific`                 |
| `ingress.tls`                                         | Ingress tls                                                                                                                | `[]`                                     |
| `jobs.volumePermissions.enabled`                      | Enable job to fix volume permissions, runs `chown -R 1000:1000` on volumes                                                 | `false`                                  |
| `jobs.volumePermissions.backoffLimit`                 | Volume permission job backoff limit                                                                                        | `0`                                      |
| `jobs.volumePermissions.resources`                    | Container resources for fix volume pods                                                                                    | `{}`                                     |
| `jobs.volumePermissions.nodeSelector`                 | Pod nodeSelector for fix volume pods                                                                                       | `{}`                                     |
| `jobs.volumePermissions.tolerations`                  | Pod tolerations for fix volume pods                                                                                        | `[]`                                     |
| `jobs.volumePermissions.affinity`                     | Pod affinity for fix volume pods                                                                                           | `{}`                                     |
| `jobs.configure.enabled`                              | Enable job to configure common site config with db host and port, socketio port and redis hosts.                           | `true`                                   |
| `jobs.configure.fixVolume`                            | Enable initContainer to fix volume permission and set them to 1000:1000                                                    | `true`                                   |
| `jobs.configure.backoffLimit`                         | Configuration job backoff limit                                                                                            | `0`                                      |
| `jobs.configure.resources`                            | Container resources for configuration pods                                                                                 | `{}`                                     |
| `jobs.configure.nodeSelector`                         | Pod nodeSelector for configuration pods                                                                                    | `{}`                                     |
| `jobs.configure.tolerations`                          | Pod tolerations for configuration pods                                                                                     | `[]`                                     |
| `jobs.configure.affinity`                             | Pod affinity for configuration pods                                                                                        | `{}`                                     |
| `jobs.configure.envVars`                              | Additional environment variables for configuration pods                                                                    | `[]`                                     |
| `jobs.configure.command`                              | Override command for configuration pods                                                                                    | `[]`                                     |
| `jobs.configure.args`                                 | Override args for configuration pods                                                                                       | `[]`                                     |
| `jobs.createSite.enabled`                             | Enable job to create new site                                                                                              | `false`                                  |
| `jobs.createSite.forceCreate`                         | Use `bench new-site –force` and force create new site if site already exists                                               | `false`                                  |
| `jobs.createSite.siteName`                            | Name of the site to be created. Must be valid resolvable DNS entry in case of live setup.                                  | `erp.cluster.local`                      |
| `jobs.createSite.adminPassword`                       | Password for site `Administrator`                                                                                          | `admin`                                  |
| `jobs.createSite.installApps`                         | List of apps to be installed                                                                                               | `[“erpnext”]`                            |
| `jobs.createSite.dbType`                              | Database to use for the new site. Choose from `postgres\mariadb`. Use `mariadb` for ERPNext.                               | `mariadb`                                |
| `jobs.createSite.backoffLimit`                        | Site creation job backoff limit.                                                                                           | `0`                                      |
| `jobs.createSite.resources`                           | Container resources for site creation pods                                                                                 | `{}`                                     |
| `jobs.createSite.nodeSelector`                        | Pod nodeSelector for site creation pods                                                                                    | `{}`                                     |
| `jobs.createSite.tolerations`                         | Pod tolerations for site creation pods                                                                                     | `[]`                                     |
| `jobs.createSite.affinity`                            | Pod affinity for site creation pods                                                                                        | `{}`                                     |
| `jobs.dropSite.enabled`                               | Enable job to drop site                                                                                                    | `false`                                  |
| `jobs.dropSite.forced`                                | Use `bench frop-site –force`                                                                                               | `false`                                  |
| `jobs.dropSite.siteName`                              | Name of the site to be deleted. Must exist in the bench.                                                                   | `erp.cluster.local`                      |
| `jobs.dropSite.backoffLimit`                          | Drop site job backoff limit                                                                                                | `0`                                      |
| `jobs.dropSite.resources`                             | Container resources for drop site pods                                                                                     | `{}`                                     |
| `jobs.dropSite.nodeSelector`                          | Pod nodeSelector for drop site pods                                                                                        | `{}`                                     |
| `jobs.dropSite.tolerations`                           | Pod tolerations for drop site pods                                                                                         | `[]`                                     |
| `jobs.dropSite.affinity`                              | Pod affinity for drop site pods                                                                                            | `{}`                                     |
| `jobs.backup.enabled`                                 | Enable backup job                                                                                                          | `false`                                  |
| `jobs.backup.siteName`                                | Name of the site to backup                                                                                                 | `erp.cluster.local`                      |
| `jobs.backup.withFiles`                               | Enable backup with files. Uses `bench –site $SITE_NAME backup –with-files`.                                                | `true`                                   |
| `jobs.backup.backoffLimit`                            | Backup job backoff limit                                                                                                   | `0`                                      |
| `jobs.backup.resources`                               | Container resources for backup site pods                                                                                   | `{}`                                     |
| `jobs.backup.nodeSelector`                            | Pod nodeSelector for backup site pods                                                                                      | `{}`                                     |
| `jobs.backup.tolerations`                             | Pod tolerations for backup site pods                                                                                       | `[]`                                     |
| `jobs.backup.affinity`                                | Pod affinity for backup site pods                                                                                          | `{}`                                     |
| `jobs.migrate.enabled`                                | Enable migrate site job                                                                                                    | `false`                                  |
| `jobs.migrate.siteName`                               | Site name to migrate                                                                                                       | `erp.cluster.local`                      |
| `jobs.migrate.skipFailing`                            | Skip failing patches during migration                                                                                      | `false`                                  |
| `jobs.migrate.backoffLimit`                           | Migrate job backoff limit                                                                                                  | `0`                                      |
| `jobs.migrate.resources`                              | Container resources for migrate site pods                                                                                  | `{}`                                     |
| `jobs.migrate.nodeSelector`                           | Pod nodeSelector for migrate site pods                                                                                     | `{}`                                     |
| `jobs.migrate.tolerations`                            | Pod tolerations for migrate site pods                                                                                      | `[]`                                     |
| `jobs.migrate.affinity`                               | Pod affinity for migrate site pods                                                                                         | `{}`                                     |
| `jobs.custom.enabled`                                 | Enable custom job                                                                                                          | `false`                                  |
| `jobs.custom.jobName`                                 | Specify custom Job name                                                                                                    | `""`                                     |
| `jobs.custom.labels`                                  | Specify custom Job labels                                                                                                  | `{}`                                     |
| `jobs.custom.backoffLimit`                            | Custom job backoff limit                                                                                                   | `0`                                      |
| `jobs.custom.initContainers`                          | Custom job init containers                                                                                                 | `[]`                                     |
| `jobs.custom.containers`                              | Custom job containers                                                                                                      | `[]`                                     |
| `jobs.custom.restartPolicy`                           | Custom job restartPolicy                                                                                                   | `Never`                                  |
| `jobs.custom.volumes`                                 | Custom job volumes                                                                                                         | `[]`                                     |
| `jobs.custom.nodeSelector`                            | Pod nodeSelector for custom job pods                                                                                       | `{}`                                     |
| `jobs.custom.affinity`                                | Pod affinity for custom job pods                                                                                           | `{}`                                     |
| `jobs.custom.tolerations`                             | Pod tolerations for custom job pods                                                                                        | `[]`                                     |
| `imagePullSecrets`                                    | List of secret names containing registry credentials to pull images                                                        | `[]`                                     |
| `nameOverride`                                        | String to partially override common.names.fullname template with a string (will prepend the release name)                  | `nil`                                    |
| `fullnameOverride`                                    | String to fully override common.names.fullname template with a string                                                      | `nil`                                    |
| `serviceAccount.create`                               | Specify whether a ServiceAccount should be created                                                                         | `true`                                   |
| `podSecurityContext.supplementalGroups`               | List of supplemental groups for the containers                                                                             | ``[1000]``                               |
| `securityContext`                                     | Security Context for containers                                                                                            | ``capabilities: add: [“CAP_CHOWN”]``     |
| `redis-cache.enabled`                                 | Install redis-cache sub chart                                                                                              | `true`                                   |
| `redis-cache.architecture`                            | Architecture for sub-chart. Do not change.                                                                                 | `standalone`                             |
| `redis-cache.auth.enabled`                            | Authentication is disabled for use with frappe. Do not change.                                                             | `false`                                  |
| `redis-cache.auth.sentinal`                           | Sentinal auth is disabled for use with frappe. Do not change.                                                              | `false`                                  |
| `redis-cache.master.containerPorts.redis`             | Container port for redis-cache service                                                                                     | `6379`                                   |
| `redis-cache.master.persistence.enabled`              | Persistence is disabled for in-memory storage use case                                                                     | `false`                                  |
| `redis-queue.enabled`                                 | Install redis-queue sub chart                                                                                              | `true`                                   |
| `redis-queue.architecture`                            | Architecture for sub-chart. Do not change.                                                                                 | `standalone`                             |
| `redis-queue.auth.enabled`                            | Authentication is disabled for use with frappe. Do not change.                                                             | `false`                                  |
| `redis-queue.auth.sentinal`                           | Sentinal auth is disabled for use with frappe. Do not change.                                                              | `false`                                  |
| `redis-queue.master.containerPorts.redis`             | Container port for redis-queue service                                                                                     | `6379`                                   |
| `redis-queue.master.persistence.enabled`              | Persistence is disabled for in-memory storage use case                                                                     | `false`                                  |
| `mariadb.enabled`                                     | Install mariadb sub chart.                                                                                                 | `true`                                   |
| `mariadb.auth.rootPassword`                           | Root password for in-cluster mariadb setup                                                                                 | `changeit`                               |
| `mariadb.auth.username`                               | Initial database username for in-cluster mariadb setup                                                                     | `erpnext`                                |
| `mariadb.auth.password`                               | Initial database password for in-cluster mariadb setup                                                                     | `changeit`                               |
| `mariadb.auth.replicationPassword`                    | Required for sub chart setup                                                                                               | `changeit`                               |
| `mariadb.primary.service.ports.mysql`                 | Container port for mariadb service                                                                                         | `3306`                                   |
| `mariadb.primary.configuration`                       | Frappe related additional configuration for mariadb. Do not change                                                         | `Configuration required for frappe apps` |
| `postgresql.enabled`                                  | Install postgresql sub chart.                                                                                              | `false`                                  |
| `postgresql.auth.username`                            | Root username for in-cluster postgresql setup                                                                              | `postgres`                               |
| `postgresql.auth.postgresPassword`                    | Root password for in-cluster postgresql setup                                                                              | `changeit`                               |
| `postgresql.primary.service.ports.postgresql`         | Container port for postgresql service                                                                                      | `5432`                                   |

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
