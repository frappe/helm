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

[Prepare Kubernetes](prepare-kubernetes) before installing ERPNext helm chart. The `mariadbHost` and `persistence.storageClass` values are generated as part of kubernetes preparation process.

```console
$ helm install frappe-bench-0001 --namespace erpnext {{ site.repo_name }}/{{ latest_chart.name }} \
    --version {{ latest_chart.version }} \
    --set mariadbHost=mariadb.mariadb.svc.cluster.local \
    --set persistence.storageClass=rook-cephfs
```

[Read]({{ site.git_repo }}/tree/master/README.md) more about helm chart configuration values

| Chart Version | App Version | Date |
|---------------|-------------|------|
{% for chart in all_charts -%}
| [{{ chart.name }}-{{ chart.version }}]({{ chart.urls[0] }}) | {{ chart.appVersion }} | {{ chart.created | date_to_rfc822 }} |
{% endfor -%}

{% endfor %}
