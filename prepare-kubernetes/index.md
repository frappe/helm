---
title: Prepare K8
layout: page
---

### Before we begin

- It is assumed that you have access to a Kubernetes cluster with admin roles.
- Make sure you have `kubectl` and `helm` installed.
- Confirm that you can access the cluster using `kubectl`.


### Requirements

1. **LoadBalancer Service** is required to allow and redirect access to services on the Kubernetes cluster. Install any ingress controller of your choice. Note this will create a load balancer resource with the cloud provider.
    - [kubernetes/nginx-ingress](https://kubernetes.github.io/ingress-nginx/deploy): Documentation examples are based on this ingress controller.

2. **Certificate Management** is required to manage TLS/SSL Certificates, ACME, and Letsencrypt related management. Install any certificate management tool of your choice.
    - [cert-manager.io](https://cert-manager.io/docs/installation/kubernetes/): Documentation to create ingress yamls is based on [cert-manager](https://cert-manager.io)

3. **MariaDB** can be installed on the Kubernetes cluster and shared across multiple ERPNext deployments. Refer to the [MariaDB Installation](mariadb) to install MariaDB Helm Chart on your Kubernetes cluster. After the completion of this step, note down the `mariadbHost`. It is the cluster hostname or the hostname provided by managed database provider. For HA installations, use Managed DB.

4. **Shared Filesystem**, i.e. Persistent Volume with Access Mode `ReadWriteMany` is required to store sites. There are many choices out there. After completion of this step note down the `storageClass`. It is required during the ERPNext installation as a value for `persistence.storageClass`.

    - [NFS](https://github.com/helm/charts/tree/master/stable/nfs-server-provisioner):
Simple and easy setup for small clusters with less number of sites deployed. Note: Remember to enable `persistence` for PVC to be created. If not, the data will not persist on any volume.
    - [Rook/Ceph](https://rook.io/docs/rook/master/ceph-quickstart.html):
Complex and distributed storage for huge clusters with multiple site deployments.
