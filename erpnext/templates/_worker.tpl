{{/*
Normalize worker.custom into a JSON object mapping worker names to their
configuration. Supported forms:

  worker.custom.<name>: {...}   # multiple named workers
  worker.custom: {...}         # single worker named "custom"

The template output is consumed with fromJson.
*/}}
{{- define "erpnext.customWorkers" -}}
{{- $workers := dict -}}
{{- $custom := .Values.worker.custom -}}
{{- if kindIs "map" $custom -}}
{{- $singleWorkerKeys := list "name" "containerName" "enabled" "queue" "queues" "replicaCount" "autoscaling" "resources" "nodeSelector" "tolerations" "affinity" "topologySpreadConstraints" "podAnnotations" "podLabels" "labels" "annotations" "livenessProbe" "readinessProbe" "startupProbe" "lifecycle" "envVars" "envFrom" "initContainers" "sidecars" "extraVolumes" "extraVolumeMounts" "command" "args" "extraArgs" "image" "imagePullSecrets" "serviceAccountName" "podSecurityContext" "securityContext" "priorityClassName" "terminationGracePeriodSeconds" "ports" "dnsPolicy" "schedulerName" "hostAliases" "strategy" "revisionHistoryLimit" -}}
{{- $singleWorker := false -}}
{{- range $key, $value := $custom -}}
{{- if has $key $singleWorkerKeys -}}
{{- $singleWorker = true -}}
{{- end -}}
{{- end -}}
{{- if $singleWorker -}}
{{- $name := $custom.name | default "custom" -}}
{{- $_ := set $workers $name $custom -}}
{{- else -}}
{{- range $name, $worker := $custom -}}
{{- if kindIs "map" $worker -}}
{{- $_ := set $workers $name $worker -}}
{{- else if not $worker -}}
{{- $_ := set $workers $name dict -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $seen := dict -}}
{{- range $name, $worker := $workers -}}
{{- $workerName := include "erpnext.customWorkerName" $name -}}
{{- if hasKey $seen $workerName -}}
{{- fail (printf "worker.custom.%s: custom worker name resolves to %q, which conflicts with worker.custom.%s. Choose unique worker names." $name $workerName (get $seen $workerName)) -}}
{{- end -}}
{{- $_ := set $seen $workerName $name -}}
{{- if has $workerName (list "d" "s" "l") -}}
{{- $reservedWorkers := dict "d" "worker-d/default" "s" "worker-s/short" "l" "worker-l/long" -}}
{{- fail (printf "worker.custom.%s: custom worker name resolves to %q, which is reserved for the built-in worker deployment (%s). Choose a different worker name." $name $workerName (get $reservedWorkers $workerName)) -}}
{{- end -}}
{{- end -}}
{{- toJson $workers -}}
{{- end -}}

{{/*
Sanitize the name of a custom worker so it can be used in Kubernetes
resource names and labels.
*/}}
{{- define "erpnext.customWorkerName" -}}
{{- $name := . | default "custom" | lower -}}
{{- regexReplaceAll "[^a-z0-9-]" $name "-" | trimAll "-" | trunc 63 | trimSuffix "-" | default "custom" -}}
{{- end -}}

{{/*
Render a worker Deployment.

Accepts a dict with:
  root          - root chart context
  name          - deployment suffix, e.g. "d", "s" or "l"
  containerName - container name
  queue         - comma separated list of queues
  config        - worker values, e.g. .Values.worker.default
*/}}
{{- define "erpnext.workerDeployment" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- $containerName := .containerName -}}
{{- $queue := .queue -}}
{{- $config := .config | default dict -}}
{{- $fullName := printf "%s-worker-%s" (include "erpnext.fullname" $root) $name | trunc 63 | trimSuffix "-" -}}
{{- $selectorName := printf "%s-worker-%s" (include "erpnext.name" $root) $name -}}
{{- $selectorInstance := printf "%s-worker-%s" $root.Release.Name $name -}}
{{- $autoscaling := $config.autoscaling | default dict -}}
{{- $livenessProbe := $config.livenessProbe | default dict -}}
{{- $readinessProbe := $config.readinessProbe | default dict -}}
{{- $image := deepCopy $root.Values.image -}}
{{- with $config.image -}}
{{- $image = merge (deepCopy .) $image -}}
{{- end -}}
{{- $imagePullSecrets := $config.imagePullSecrets | default $root.Values.imagePullSecrets -}}
{{- $args := list "bench" "worker" "--queue" $queue -}}
{{- if $config.args -}}
{{- $args = $config.args -}}
{{- end -}}
{{- with $config.extraArgs -}}
{{- $args = concat $args . -}}
{{- end -}}
apiVersion: apps/v1
kind: Deployment
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
  {{- if not $autoscaling.enabled }}
  replicas: {{ $config.replicaCount | default 1 }}
  {{- end }}
  {{- with $config.revisionHistoryLimit }}
  revisionHistoryLimit: {{ . }}
  {{- end }}
  {{- with $config.strategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ $selectorName }}
      app.kubernetes.io/instance: {{ $selectorInstance }}
  template:
    metadata:
      {{- with $config.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        app.kubernetes.io/name: {{ $selectorName }}
        app.kubernetes.io/instance: {{ $selectorInstance }}
        app.kubernetes.io/app: frappe
        {{- with $config.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
    {{- with $imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
    {{- end }}
      serviceAccountName: {{ $config.serviceAccountName | default (include "erpnext.serviceAccountName" $root) }}
      securityContext:
        {{- toYaml ($config.podSecurityContext | default $root.Values.podSecurityContext) | nindent 8 }}
    {{- with $config.priorityClassName }}
      priorityClassName: {{ . }}
    {{- end }}
    {{- with $config.terminationGracePeriodSeconds }}
      terminationGracePeriodSeconds: {{ . }}
    {{- end }}
    {{- with $config.dnsPolicy }}
      dnsPolicy: {{ . }}
    {{- end }}
    {{- with $config.schedulerName }}
      schedulerName: {{ . }}
    {{- end }}
    {{- with $config.hostAliases }}
      hostAliases:
        {{- toYaml . | nindent 8 }}
    {{- end }}
    {{- if $config.initContainers }}
      initContainers:
        {{- toYaml $config.initContainers | nindent 8 }}
    {{- end }}
      containers:
        - name: {{ $containerName }}
          {{- with $config.command }}
          command:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          args:
            {{- toYaml $args | nindent 10 }}
          {{- if $config.envVars }}
          env:
            {{- toYaml $config.envVars | nindent 12 }}
          {{- end }}
          {{- with $config.envFrom }}
          envFrom:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          image: "{{ $image.repository }}:{{ $image.tag }}"
          imagePullPolicy: {{ $image.pullPolicy }}
          {{- with $config.ports }}
          ports:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- if ne (toString $livenessProbe.enabled) "false" }}
          livenessProbe:
            {{- if $livenessProbe.override }}
            {{- toYaml $livenessProbe.probe | nindent 12 }}
            {{- else }}
            {{ tpl $root.Values.worker.healthProbe $root | nindent 12 }}
            {{- end }}
          {{- end }}
          {{- if ne (toString $readinessProbe.enabled) "false" }}
          readinessProbe:
            {{- if $readinessProbe.override }}
            {{- toYaml $readinessProbe.probe | nindent 12 }}
            {{- else }}
            {{ tpl $root.Values.worker.healthProbe $root | nindent 12 }}
            {{- end }}
          {{- end }}
          {{- with $config.startupProbe }}
          startupProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $config.lifecycle }}
          lifecycle:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          resources:
            {{- toYaml ($config.resources | default dict) | nindent 12 }}
          securityContext:
            {{- toYaml ($config.securityContext | default $root.Values.securityContext) | nindent 12 }}
          volumeMounts:
          - name: sites-dir
            mountPath: /home/frappe/frappe-bench/sites
          - name: logs
            mountPath: /home/frappe/frappe-bench/logs
          {{- with $config.extraVolumeMounts }}
            {{- toYaml . | nindent 10 }}
          {{- end }}
      {{- if $config.sidecars }}
        {{- toYaml $config.sidecars | nindent 8 }}
      {{- end }}
      volumes:
        - name: sites-dir
          {{- if $root.Values.persistence.worker.enabled }}
          persistentVolumeClaim:
            {{- if $root.Values.persistence.worker.existingClaim }}
            claimName: {{ $root.Values.persistence.worker.existingClaim }}
            {{- else }}
            claimName: {{ include "erpnext.fullname" $root }}
            {{- end }}
            readOnly: false
          {{- else }}
          emptyDir: {}
          {{- end }}
        - name: logs
          {{- if $root.Values.persistence.logs.enabled }}
          persistentVolumeClaim:
            {{- if $root.Values.persistence.logs.existingClaim }}
            claimName: {{ $root.Values.persistence.logs.existingClaim }}
            {{- else }}
            claimName: {{ include "erpnext.fullname" $root }}-logs
            {{- end }}
            readOnly: false
          {{- else }}
          emptyDir: {}
          {{- end }}
        {{- with $config.extraVolumes }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- with $config.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    {{- with $config.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
    {{- end }}
    {{- with $config.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
    {{- end }}
    {{- with $config.topologySpreadConstraints }}
      topologySpreadConstraints:
        {{- toYaml . | nindent 8 }}
    {{- end }}
{{- end -}}

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
