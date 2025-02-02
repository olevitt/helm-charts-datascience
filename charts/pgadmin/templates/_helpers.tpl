{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "pgadmin.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pgadmin.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "pgadmin.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pgadmin.labels" -}}
helm.sh/chart: {{ include "pgadmin.chart" . }}
{{ include "pgadmin.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pgadmin.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pgadmin.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "pgadmin.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "pgadmin.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
ingress annotations 
*/}}
{{- define "pgadmin.ingress.annotations" -}}
{{- with .Values.ingress.annotations }}
    {{- toYaml . }}
{{- end }}
{{- if .Values.security.whitelist.enable }}
nginx.ingress.kubernetes.io/whitelist-source-range: {{ .Values.security.whitelist.ip }}
{{- end }}
{{- end }}

{{- define "pgadmin.configmap" -}}
{{ printf "{" }}
{{ printf "\"Servers\": {" | indent 2 }} 
{{- $virgule := 0 }}      
{{ range $index, $service := (lookup "v1" "Service" .Release.Namespace "").items }}
{{- if (index $service "metadata" "labels") }}
{{- if (index $service "metadata" "labels" "helm.sh/chart") }}
{{- if hasPrefix "postgres" (index $service "metadata" "labels" "helm.sh/chart") }}
{{- if $virgule }}
{{ printf "," }}
{{- end }}
{{ printf "\"%d\" :{" $index | indent 4}}
{{ printf "\"Name\": \"%s\"," $service.metadata.name | indent 6}}
{{ printf "\"Group\": \"Autodiscovery\"," | indent 6}}
{{ printf "\"Port\": %d," (index $service.spec.ports 0).port | indent 6}}
{{ printf "\"Host\": \"%s\"," $service.metadata.name | indent 6}}
{{ printf "\"Username\": \"%s\"," (trimPrefix "user-" $service.metadata.namespace) | indent 6}}
{{ printf "\"SSLMode\": \"prefer\"," | indent 6 }}
{{ printf "\"MaintenanceDB\": \"postgres\"" | indent 6}}
{{- $virgule = 1}}
{{ printf "}" | indent 4}}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{ printf "}" | indent 2}}
{{ printf "}" }}
{{- end }}
