{{/*
Render a worker HorizontalPodAutoscaler.

Accepts a dict with:
  root   - root chart context
  name   - worker name suffix, e.g. "d", "s" or "l"
  config - worker values, e.g. .Values.worker.default

The caller is responsible for checking whether autoscaling is enabled.
*/}}
{{- define "erpnext.workerHpa" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- $config := .config | default dict -}}
{{- $autoscaling := $config.autoscaling | default dict -}}
{{- $fullName := printf "%s-worker-%s" (include "erpnext.fullname" $root) $name | trunc 63 | trimSuffix "-" -}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ $fullName }}
  {{- with $config.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- include "erpnext.labels" $root | nindent 4 }}
    {{- with $config.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ $fullName }}
  minReplicas: {{ $autoscaling.minReplicas | default 1 }}
  maxReplicas: {{ $autoscaling.maxReplicas | default 3 }}
  metrics:
    {{- if $autoscaling.metrics }}
    {{- toYaml $autoscaling.metrics | nindent 4 }}
    {{- else }}
    {{- if $autoscaling.targetCPU }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ $autoscaling.targetCPU }}
    {{- end }}
    {{- if $autoscaling.targetMemory }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ $autoscaling.targetMemory }}
    {{- end }}
    {{- end }}
  {{- with $autoscaling.behavior }}
  behavior:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
