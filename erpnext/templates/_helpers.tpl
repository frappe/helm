{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "erpnext.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "erpnext.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "erpnext.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "erpnext.labels" -}}
helm.sh/chart: {{ include "erpnext.chart" . }}
{{ include "erpnext.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "erpnext.selectorLabels" -}}
app.kubernetes.io/name: {{ include "erpnext.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "erpnext.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "erpnext.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create redis host name
*/}}
{{- define "redis.fullname" -}}
{{- printf "%s-%s" .Release.Name "redis" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Gets the mariadb host name
*/}}
{{- define "erpnext.mariadbHost" -}}
{{ .Values.mariadbHost }}
{{- end -}}

{{/*
Gets the redis socketio host name
*/}}
{{- define "erpnext.redisSocketIOHost" -}}
{{ .Values.redisSocketIOHost }}
{{- end -}}

{{/*
Gets the redis queue host name
*/}}
{{- define "erpnext.redisQueueHost" -}}
{{ .Values.redisQueueHost }}
{{- end -}}

{{/*
Gets the redis cache host name
*/}}
{{- define "erpnext.redisCacheHost" -}}
{{ .Values.redisCacheHost }}
{{- end -}}

{{/*
Init container that creates and chowns the persistence subPath directories, so
a fresh subPath (otherwise created root-owned by the kubelet) is writable by
the non-root frappe user before the main containers start. Renders nothing
unless a subPath is set. Takes a dict with "root" (the chart context) and
"logs" (whether the pod mounts the logs volume).
*/}}
{{- define "erpnext.subPathInitContainer" -}}
{{- $root := .root -}}
{{- $p := $root.Values.persistence -}}
{{- if $p.subPathPermissions.enabled -}}
{{- $uid := default 1000 $root.Values.securityContext.runAsUser -}}
{{- $withLogs := and .logs $p.logs.subPath -}}
{{- if or $p.worker.subPath $withLogs }}
- name: fix-subpath-permissions
  image: {{ $root.Values.image.repository }}:{{ $root.Values.image.tag }}
  imagePullPolicy: {{ $root.Values.image.pullPolicy }}
  command: ['/bin/sh', '-c', 'mkdir -p "$@" && chown {{ $uid }}:{{ $uid }} "$@"', 'sh']
  {{- /* Dirs are passed as positional args so subPath values are never parsed by the shell. */}}
  args:
    {{- if $p.worker.subPath }}
    - {{ printf "/mnt/sites/%s" (toString $p.worker.subPath) | quote }}
    {{- end }}
    {{- if $withLogs }}
    - {{ printf "/mnt/logs/%s" (toString $p.logs.subPath) | quote }}
    {{- end }}
  securityContext:
    # run as root to set ownership
    runAsNonRoot: false
    runAsUser: 0
  volumeMounts:
    {{- if $p.worker.subPath }}
    - name: sites-dir
      mountPath: /mnt/sites
    {{- end }}
    {{- if $withLogs }}
    - name: logs
      mountPath: /mnt/logs
    {{- end }}
{{- end }}
{{- end }}
{{- end -}}
