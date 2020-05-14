---
layout: default
---

{% include breadcrumbs.html %}

## Create Cluster Issuer for SSL Certificates

To generate SSL Certificates for your instance, you first need to have a Certificate Manager set up. Then, you require a cluster issuer to solve challenges, generate and manage certificates for your cluster. This example assumes you have cert-manager.io set up in one of the namespaces in your cluster. We'll be using the LetsEncrypt based ACME issuer as our cluster issuer.

Create a file named `cluster-issuer.yaml` with following content.

```yaml
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # You must replace this email address with your own.
    # Let's Encrypt will use this to contact you about expiring
    # certificates, and issues related to your account.
    email: ${EMAIL_ADDRESS}
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: letsencrypt-secret-ref
    # Add a single challenge solver, HTTP01 using nginx
    solvers:
    - http01:
        ingress:
          class: nginx
```

Change the following properties:

- `spec.acme.email`: email address to notify certificate renewals

Create the resource using:

```console
$ kubectl create -n <namespace> -f cluster-issuer.yaml
```
