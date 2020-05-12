---
layout: default
---

{% include breadcrumbs.html %}

## Create Site Ingress

Create a file named `ingress.yaml` with following content.

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ${INGRESS_NAME}
  # Optional Labels
  labels:
    app.kubernetes.io/instance: ${FRAPPE_SERVICE}
  annotations:
    # required for cert-manager letsencrypt
    cert-manager.io/cluster-issuer: letsencrypt-prod
    # other annotations as needed, e.g timestamp
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
spec:
  rules:
  - host: ${SITE_NAME}
    http:
      paths:
      - backend:
          serviceName: ${FRAPPE_SERVICE}
          servicePort: 80
        path: /
  tls:
  - hosts:
    - ${SITE_NAME}
    secretName: ${TLS_SECRET_NAME}
```

Change the following properties:

- `metadata.name`: name of ingress e.g. erp.example.com
- `metadata.labels.app\.kubernetes\.io/instance}`: service that runs erpnext e.g. `<release-name>-erpnext`.
- `spec.rules[0].host`: name of site e.g. erp.example.com
- `spec.rules[0].http.paths[0].backend.serviceName`: service that runs erpnext e.g. `<release-name>-erpnext`.
- `spec.tls[0].hosts[0]`: name of site e.g. erp.example.com
- `spec.tls[0].secretName`: name of the secret to save letsencrypt certificate.

Create the resource using:

```console
$ kubectl create -n <namespace> -f ingress.yaml
```
