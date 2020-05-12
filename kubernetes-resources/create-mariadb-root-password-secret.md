---
layout: default
---

{% include breadcrumbs.html %}

## Create MariaDB Root Password Secret

Create a file named `mariadb-secret.yaml` with following content.

```yaml
apiVersion: v1
data:
  password: ${BASE64_PASSWORD}
kind: Secret
metadata:
  name: mariadb-root-password
type: Opaque
```

Change the following properties:

- `data.password`: mariadb root password encoded as base64

Note down the `metadata.name`. It is required create Jobs to add new sites or to restore backups.

Create the resource using:

```console
$ kubectl create -n <namespace> -f mariadb-secret.yaml
```

Note that the `<namespace>` in here should be the ERPNext deployment namespace and not the MariaDB namespace.
