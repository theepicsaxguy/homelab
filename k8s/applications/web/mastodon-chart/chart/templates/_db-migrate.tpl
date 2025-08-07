{{/* vim: set filetype=mustache: */}}
{{/*
Spec template for DB migration pre- and post-install/upgrade jobs.
*/}}
{{- define "mastodon.dbMigrateJob" -}}
apiVersion: batch/v1
kind: Job
metadata:
  {{- if .prepare }}
  name: {{ include "mastodon.fullname" . }}-db-prepare
  {{- else if .preDeploy }}
  name: {{ include "mastodon.fullname" . }}-db-pre-migrate
  {{- else }}
  name: {{ include "mastodon.fullname" . }}-db-post-migrate
  {{- end }}
  labels:
    {{- include "mastodon.labels" . | nindent 4 }}
  annotations:
    {{- if .prepare }}
    "helm.sh/hook": pre-install
    {{- else if .preDeploy }}
    "helm.sh/hook": pre-upgrade
    {{- else }}
    "helm.sh/hook": post-install,post-upgrade
    {{- end }}
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
    {{- if .prepare }}
    "helm.sh/hook-weight": "-3"
    {{- else }}
    "helm.sh/hook-weight": "-2"
    {{- end }}
spec:
  template:
    metadata:
      name: {{ include "mastodon.fullname" . }}-db-migrate
      {{- with .Values.jobAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      restartPolicy: Never
      containers:
        - name: {{ include "mastodon.fullname" . }}-db-migrate
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          command:
            - bundle
            - exec
            - rake
            {{- if .prepare }}
            - db:prepare
            {{- else }}
            - db:migrate
            {{- end }}
          envFrom:
            - secretRef:
                {{- if and .prepare (not .Values.mastodon.secrets.existingSecret) }}
                name: {{ template "mastodon.secretName" . }}-prepare
                {{- else }}
                name: {{ template "mastodon.secretName" . }}
                {{- end }}
          env:
            - name: "DB_HOST"
              value: {{ template "mastodon.postgres.direct.host" . }}
            - name: "DB_PORT"
              value: {{ template "mastodon.postgres.direct.port" . }}
            - name: "DB_NAME"
              value: {{ template "mastodon.postgres.direct.database" . }}
            - name: "DB_USER"
              value: {{ .Values.postgresql.auth.username }}
            - name: "DB_PASS"
              valueFrom:
                secretKeyRef:
                  name: {{ template "mastodon.postgresql.secretName" . }}
                  key: password
            - name: "REDIS_HOST"
              value: {{ template "mastodon.redis.host" . }}
            - name: "REDIS_PORT"
              value: {{ .Values.redis.port | default "6379" | quote }}
            {{- if .Values.redis.sidekiq.enabled }}
            {{- if .Values.redis.sidekiq.hostname }}
            - name: SIDEKIQ_REDIS_HOST
              value: {{ .Values.redis.sidekiq.hostname }}
            {{- end }}
            {{- if .Values.redis.sidekiq.port }}
            - name: SIDEKIQ_REDIS_PORT
              value: {{ .Values.redis.sidekiq.port | quote }}
            {{- end }}
            {{- end }}
            {{- if .Values.redis.cache.enabled }}
            {{- if .Values.redis.cache.hostname }}
            - name: CACHE_REDIS_HOST
              value: {{ .Values.redis.cache.hostname }}
            {{- end }}
            {{- if .Values.redis.cache.port }}
            - name: CACHE_REDIS_PORT
              value: {{ .Values.redis.cache.port | quote }}
            {{- end }}
            {{- end }}
            - name: "REDIS_DRIVER"
              value: "ruby"
            - name: "REDIS_PASSWORD"
              valueFrom:
                secretKeyRef:
                  {{- if and (.prepare) (not .Values.redis.enabled) (not .Values.redis.auth.existingSecret) (not .Values.redis.existingSecret) (.Values.redis.auth.password) }}
                  name: {{ template "mastodon.redis.secretName" . }}-pre-install
                  {{- else }}
                  name: {{ template "mastodon.redis.secretName" . }}
                  {{- end }}
                  key: redis-password
          {{- if .preDeploy }}
            - name: "SKIP_POST_DEPLOYMENT_MIGRATIONS"
              value: "true"
          {{- end }}
{{- end }}
