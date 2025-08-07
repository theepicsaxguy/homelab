{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "mastodon.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mastodon.fullname" -}}
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
{{- define "mastodon.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Labels added on every Mastodon resource
*/}}
{{- define "mastodon.globalLabels" -}}
{{- range $k, $v := .Values.mastodon.labels }}
{{ $k }}: {{ quote $v }}
{{- end -}}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mastodon.labels" -}}
helm.sh/chart: {{ include "mastodon.chart" . }}
{{ include "mastodon.selectorLabels" . }}
{{ include "mastodon.globalLabels" . }}
{{- if .Values.image.tag }}
app.kubernetes.io/version: {{ regexReplaceAll "@(\\w+:\\w{0,7})\\w*" .Values.image.tag "@${1}" | quote }}
{{- else if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mastodon.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mastodon.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Rolling pod annotations
*/}}
{{- define "mastodon.rollingPodAnnotations" -}}
{{- if .Values.revisionPodAnnotation }}
rollme: {{ .Release.Revision | quote }}
{{- end }}
checksum/config-secrets: {{ include ( print $.Template.BasePath "/secrets.yaml" ) . | sha256sum | quote }}
checksum/config-configmap: {{ include ( print $.Template.BasePath "/configmap-env.yaml" ) . | sha256sum | quote }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mastodon.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mastodon.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the assets persistent volume to use
*/}}
{{- define "mastodon.pvc.assets" -}}
{{- if .Values.mastodon.persistence.assets.existingClaim }}
    {{- printf "%s" (tpl .Values.mastodon.persistence.assets.existingClaim $) -}}
{{- else -}}
    {{- printf "%s-assets" (include "mastodon.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the system persistent volume to use
*/}}
{{- define "mastodon.pvc.system" -}}
{{- if .Values.mastodon.persistence.system.existingClaim }}
    {{- printf "%s" (tpl .Values.mastodon.persistence.system.existingClaim $) -}}
{{- else -}}
    {{- printf "%s-system" (include "mastodon.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified name for dependent services.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "mastodon.elasticsearch.fullname" -}}
{{- printf "%s-%s" .Release.Name "elasticsearch" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mastodon.redis.fullname" -}}
{{- printf "%s-%s" .Release.Name "redis" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mastodon.postgresql.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Establish which values we will use for remote connections
*/}}
{{- define "mastodon.postgres.host" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s" (include "mastodon.postgresql.fullname" .) -}}
{{- else }}
{{- printf "%s" (required "When the postgresql chart is disabled .Values.postgresql.postgresqlHostname is required" .Values.postgresql.postgresqlHostname) -}}
{{- end }}
{{- end }}

{{- define "mastodon.postgres.port" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%d" 5432 | int | quote -}}
{{- else }}
{{- printf "%d" | default 5432 .Values.postgresql.postgresqlPort | int | quote -}}
{{- end }}
{{- end }}

{{/*
Establish which values we will use for direct remote DB connections
*/}}
{{- define "mastodon.postgres.direct.host" -}}
{{- if .Values.postgresql.direct.hostname }}
{{- printf "%s" .Values.postgresql.direct.hostname -}}
{{- else }}
{{- printf "%s" (include "mastodon.postgres.host" .) -}}
{{- end }}
{{- end }}

{{- define "mastodon.postgres.direct.port" -}}
{{- if .Values.postgresql.direct.port }}
{{- printf "%d" (int .Values.postgresql.direct.port) | quote -}}
{{- else }}
{{- printf "%s" (include "mastodon.postgres.port" .) -}}
{{- end }}
{{- end }}

{{- define "mastodon.postgres.direct.database" -}}
{{- if .Values.postgresql.direct.database }}
{{- printf "%s" .Values.postgresql.direct.database -}}
{{- else }}
{{- printf "%s" .Values.postgresql.auth.database -}}
{{- end }}
{{- end }}

{{- define "mastodon.redis.host" -}}
{{- if .Values.redis.enabled }}
{{- printf "%s-%s" (include "mastodon.redis.fullname" .) "master" -}}
{{- else }}
{{- printf "%s" (required "When the redis chart is disabled .Values.redis.hostname is required" .Values.redis.hostname) -}}
{{- end }}
{{- end }}

{{/*
Get the mastodon secret.
*/}}
{{- define "mastodon.secretName" -}}
{{- if .Values.mastodon.secrets.existingSecret }}
    {{- printf "%s" (tpl .Values.mastodon.secrets.existingSecret $) -}}
{{- else -}}
    {{- printf "%s" (include "mastodon.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get the smtp secrets.
*/}}
{{- define "mastodon.smtp.secretName" -}}
{{- if .Values.mastodon.smtp.existingSecret }}
    {{- printf "%s" (tpl .Values.mastodon.smtp.existingSecret $) -}}
{{- else -}}
    {{- printf "%s-smtp" (include "mastodon.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "mastodon.smtp.bulk.secretName" -}}
{{- if .Values.mastodon.smtp.bulk.existingSecret }}
    {{- printf "%s" (tpl .Values.mastodon.smtp.bulk.existingSecret $) -}}
{{- else -}}
    {{- printf "%s-smtp-bulk" (include "mastodon.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get the postgresql secret.
*/}}
{{- define "mastodon.postgresql.secretName" -}}
{{- if (and (or .Values.postgresql.enabled .Values.postgresql.postgresqlHostname) .Values.postgresql.auth.existingSecret) }}
    {{- printf "%s" (tpl .Values.postgresql.auth.existingSecret $) -}}
{{- else if .Values.postgresql.enabled -}}
    {{- printf "%s-postgresql" (tpl .Release.Name $) -}}
{{- else -}}
    {{- printf "%s" (include "mastodon.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get the redis secret.
*/}}
{{- define "mastodon.redis.secretName" -}}
{{- if .Values.redis.auth.existingSecret }}
    {{- printf "%s" (tpl .Values.redis.auth.existingSecret $) -}}
{{- else if .Values.redis.existingSecret }}
    {{- printf "%s" (tpl .Values.redis.existingSecret $) -}}
{{- else if .Values.redis.enabled -}}
    {{- printf "%s-redis" (tpl .Release.Name $) -}}
{{- else -}}
    {{- printf "%s-redis" (include "mastodon.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get the redis secret (sidekiq).
*/}}
{{- define "mastodon.redis.sidekiq.secretName" -}}
{{- if .Values.redis.sidekiq.auth.existingSecret }}
    {{- printf "%s" (tpl .Values.redis.sidekiq.auth.existingSecret $) -}}
{{- else if .Values.redis.auth.existingSecret }}
    {{- printf "%s" (tpl .Values.redis.auth.existingSecret $) -}}
{{- else if .Values.redis.existingSecret }}
    {{- printf "%s" (tpl .Values.redis.existingSecret $) -}}
{{- else -}}
    {{- printf "%s-redis" (tpl .Release.Name $) -}}
{{- end -}}
{{- end -}}

{{/*
Get the redis secret (cache).
*/}}
{{- define "mastodon.redis.cache.secretName" -}}
{{- if .Values.redis.cache.auth.existingSecret }}
    {{- printf "%s" (tpl .Values.redis.cache.auth.existingSecret $) -}}
{{- else if .Values.redis.auth.existingSecret }}
    {{- printf "%s" (tpl .Values.redis.auth.existingSecret $) -}}
{{- else if .Values.redis.existingSecret }}
    {{- printf "%s" (tpl .Values.redis.existingSecret $) -}}
{{- else -}}
    {{- printf "%s-redis" (tpl .Release.Name $) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a mastodon secret object should be created
*/}}
{{- define "mastodon.createSecret" -}}
{{- if (or
    (and .Values.mastodon.s3.enabled (not .Values.mastodon.s3.existingSecret))
    (not .Values.mastodon.secrets.existingSecret )
    (and (not .Values.postgresql.enabled) (not .Values.postgresql.auth.existingSecret))
    ) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Full hostname for a custom Elasticsearch cluster
*/}}
{{- define "mastodon.elasticsearch.fullHostname" -}}
{{- if not .Values.elasticsearch.enabled }}
    {{- if .Values.elasticsearch.tls }}
        {{- printf "https://%s" (tpl .Values.elasticsearch.hostname $) -}}
    {{- else -}}
        {{- printf "%s" (tpl .Values.elasticsearch.hostname $) -}}
    {{- end }}
{{- end -}}
{{- end -}}
