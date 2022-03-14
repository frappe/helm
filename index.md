---
title: Install ERPNext
layout: default
---

## Getting Started

{{ site.description }}

You can add this repository to your local helm configuration as follows:

```console
$ helm repo add {{ site.repo_name }} {{ site.url }}
$ helm repo update
```

## Charts

{% for helm_chart in site.data.index.entries %}
{% assign title = helm_chart[0] | upcase %}
{% assign all_charts = helm_chart[1] | sort: 'created' | reverse %}
{% assign latest_chart = all_charts[0] %}

<h3>
  {% if latest_chart.icon %}
  <img src="{{ latest_chart.icon }}" style="height:1.2em;vertical-align: middle;" />
  {% endif %}
  {{ title }}
</h3>

[Home]({{ latest_chart.home }}) \| [Source]({{ site.git_repo }})

{{ latest_chart.description }}

Use valid storage class with access mode ReadWriteMany instead of `nfs`

```console
$ kubectl create namespace erpnext
$ helm repo add frappe https://helm.erpnext.com
$ helm upgrade --install frappe-bench --namespace erpnext frappe/erpnext --set persistence.worker.storageClass=nfs
```

For evaluation, setup simple in-cluster NFS server to make the `nfs` storage class with RWX capabilities available for use.

```console
$ kubectl create namespace nfs
$ helm repo add nfs-ganesha-server-and-external-provisioner https://kubernetes-sigs.github.io/nfs-ganesha-server-and-external-provisioner
$ helm upgrade --install -n nfs in-cluster nfs-ganesha-server-and-external-provisioner/nfs-server-provisioner --set 'storageClass.mountOptions={vers=4.1}' --set persistence.enabled=true --set persistence.size=8Gi
```

[Read]({{ site.git_repo }}/blob/main/erpnext/README.md) more about helm chart configuration values.

| Chart Version | App Version | Date |
|---------------|-------------|------|
{% for chart in all_charts -%}
| [{{ chart.name }}-{{ chart.version }}]({{ chart.urls[0] }}) | {{ chart.appVersion }} | {{ chart.created | date_to_rfc822 }} |
{% endfor -%}

{% endfor %}
