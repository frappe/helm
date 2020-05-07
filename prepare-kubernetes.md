---
title: Prepare Kubernetes
layout: default
---

## Prepare Kubernetes

### Before we begin

- It is assumed that you have access to kubernetes cluster with admin roles.
- Make sure you have `kubectl` and `helm` installed.
- Confirm you can access the cluster using `kubectl` command.


### Requirements

1. **LoadBalancer Service** is required to allow and redirect access to services on kubernetes cluster. Install any ingress controller of choice. Note this will create a load balancer resource with cloud provider.

    - [kubernetes/nginx-ingress](https://kubernetes.github.io/ingress-nginx/deploy):
The [k8-resources]({{ site.git_repo }}/tree/master/k8-resources) directory has scripts to create ingress yamls that are based on [kubernetes/ingress-nginx](https://kubernetes.github.io/ingress-nginx)

2. **Certificate Management** is required to manage TLS/SSL Certificates, ACME and Letsencrypt related management. Install any certificate management tool of choice.

    - [cert-manager.io](https://cert-manager.io/docs/installation/kubernetes/):
The [k8-resources]({{ site.git_repo }}/tree/master/k8-resources) directory has scripts to create ingress yamls that are based on [cert-manager](https://cert-manager.io)

3. **MariaDB** for HA installations use Managed DB. MariaDB can be installed on kubernetes cluster and can be shared across multiple erpnext deployments. Refer [MariaDB Installation](mariadb) to install MariaDB Helm Chart on kubernetes cluster. After completion of this step note down the `mariadbHost`. It is hostname on cluster or hostname provided by managed database provider.

4. **Shared Filesystem**, i.e. Persistent Volume with Access Mode `ReadWriteMany` is required to store sites. There are many choices out there. After completion of this step note down the `storageClass`. It is required during ERPNext installation as value for `persistence.storageClass`.

    - [NFS](https://github.com/helm/charts/tree/master/stable/nfs-server-provisioner):
Simple and easy for small clusters with less number of benches deployed. Note: Remember to enable `persistence` for PVC to be created. If not the data will not be persisted on any volume.
    - [Rook/Ceph](https://rook.io/docs/rook/master/ceph-quickstart.html):
Complex and distributed storage for huge clusters with many bench deployments.
