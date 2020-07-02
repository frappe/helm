---
layout: page
---

{% include breadcrumbs.html %}

## Install MariaDB Helm Chart

Download and edit values.yaml for frappe related mariadb config.

```console
$ wget -c https://raw.githubusercontent.com/bitnami/charts/master/bitnami/mariadb/values-production.yaml

# Use editor of choice
$ code values-production.yaml
```

Set `rootUser.password`, `replication.password`, `db.user`, `db.name` and `db.password`.
It is required to successfully install the MariaDB Helm Chart.

```yaml
rootUser:
  password: super_secret_password

replication:
  password: super_secret_password

db:
  user: my_user
  password: super_secret_password
  name: my_database
```

Change `master.config` as follows:

```yaml
  config: |-
    [mysqld]
    character-set-client-handshake=FALSE
    skip-name-resolve
    explicit_defaults_for_timestamp
    basedir=/opt/bitnami/mariadb
    plugin_dir=/opt/bitnami/mariadb/plugin
    port=3306
    socket=/opt/bitnami/mariadb/tmp/mysql.sock
    tmpdir=/opt/bitnami/mariadb/tmp
    max_allowed_packet=16M
    bind-address=0.0.0.0
    pid-file=/opt/bitnami/mariadb/tmp/mysqld.pid
    log-error=/opt/bitnami/mariadb/logs/mysqld.log
    character-set-server=utf8mb4
    collation-server=utf8mb4_unicode_ci

    [client]
    port=3306
    socket=/opt/bitnami/mariadb/tmp/mysql.sock
    default-character-set=utf8mb4
    plugin_dir=/opt/bitnami/mariadb/plugin

    [manager]
    port=3306
    socket=/opt/bitnami/mariadb/tmp/mysql.sock
    pid-file=/opt/bitnami/mariadb/tmp/mysqld.pid
```

Change `slave.config` as follows:

```yaml
  config: |-
    [mysqld]
    character-set-client-handshake=FALSE
    skip-name-resolve
    explicit_defaults_for_timestamp
    basedir=/opt/bitnami/mariadb
    port=3306
    socket=/opt/bitnami/mariadb/tmp/mysql.sock
    tmpdir=/opt/bitnami/mariadb/tmp
    max_allowed_packet=16M
    bind-address=0.0.0.0
    pid-file=/opt/bitnami/mariadb/tmp/mysqld.pid
    log-error=/opt/bitnami/mariadb/logs/mysqld.log
    character-set-server=utf8mb4
    collation-server=utf8mb4_unicode_ci

    [client]
    port=3306
    socket=/opt/bitnami/mariadb/tmp/mysql.sock
    default-character-set=utf8mb4

    [manager]
    port=3306
    socket=/opt/bitnami/mariadb/tmp/mysql.sock
    pid-file=/opt/bitnami/mariadb/tmp/mysqld.pid
```


Create a namespace for mariadb and Install Helm Chart on it:

```console
$ kubectl create namespace mariadb

$ helm repo add bitnami https://charts.bitnami.com/bitnami
$ helm repo update
$ helm install mariadb -n mariadb bitnami/mariadb -f values-production.yaml
```
