---
title: Prepare K8
layout: page
---

### Before we begin

- It is assumed that you have access to a Kubernetes cluster with admin roles.
- Make sure you have `kubectl` and `helm` installed.
- Confirm that you can access the cluster using `kubectl`.
- Ensure that you also refer to the documentation of the requirements listed below.
- You are welcome to share your individual install recipes and steps for your favourite cloud provider


### Requirements

1. **LoadBalancer Service** 
Required to allow and redirect access to services on the Kubernetes cluster. Install any ingress controller of your choice. Note this will create a load balancer resource with the cloud provider.
    - [kubernetes/nginx-ingress](https://kubernetes.github.io/ingress-nginx/deploy): Documentation examples are based on this ingress controller.
 

2. **Certificate Management** 
Required to manage TLS/SSL Certificates, ACME, and Letsencrypt related management. Install any certificate management tool of your choice.
    - [cert-manager.io](https://cert-manager.io/docs/installation/kubernetes/): Documentation to create ingress yamls is based on [cert-manager](https://cert-manager.io). You need to create [`ClusterIssuer`](https://cert-manager.io/docs/configuration/acme/#creating-a-basic-acme-issuer) named `letsencrypt-prod` after installation to start using cert-manager. Remember to use correct letsencrypt production server. e.g. `https://acme-v02.api.letsencrypt.org/directory`

        ***Tl;DR***
        Install cert-manager
        ```console
        kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml
        ````
        Copy below yaml to certman.yaml - change your email as wel
        ```yaml
        apiVersion: cert-manager.io/v1
        kind: ClusterIssuer
        metadata:
          name: letsencrypt-prod
        spec:
          acme:
            # You must replace this email address with your own.
            # Let's Encrypt will use this to contact you about expiring
            # certificates, and issues related to your account.
            email: <youremail>
            server: https://acme-v02.api.letsencrypt.org/directory
            privateKeySecretRef:
            # Secret resource that will be used to store the account's private key.
              name: mugen-kube-issuer-account-key
            # Add a single challenge solver, HTTP01 using nginx
            solvers:
            - http01:
                ingress:
                  class: nginx
        ```

        Apply yaml file
        ```console
        kubectl apply -f certman.yaml 
        kubectl get clusterissuer # to verufy this tep
        #NAME               READY   AGE
        #letsencrypt-prod   True    24h
        ````

3. **MariaDB** 
Can be installed on the Kubernetes cluster and shared across multiple ERPNext deployments. Refer to the [MariaDB Installation](mariadb) to install MariaDB Helm Chart on your Kubernetes cluster. After the completion of this step, note down the `mariadbHost`. It is the cluster hostname or the hostname provided by managed database provider. For HA installations, use Managed DB.

4. **Shared Filesystem**
Persistent Volume with `ReadWriteMany` Access Mode is required to store sites. There are many choices out there. After completion of this step note down the `storageClass`. It is required during the ERPNext installation as a value for `persistence.storageClass`.

    - [NFS](https://github.com/kubernetes-sigs/nfs-ganesha-server-and-external-provisioner):
Simple and easy setup for small clusters with less number of sites deployed. Note: Remember to enable `persistence` for PVC to be created. If not, the data will not persist on any volume.
    - [Rook/Ceph](https://rook.io/docs/rook/master/ceph-quickstart.html):
Complex and distributed storage for huge clusters with multiple site deployments.
