{{/* vim: set filetype=mustache: */}}
{{/*
Spec template for mastodon secrets object.
*/}}
{{- define "mastodon.secrets.object" -}}
apiVersion: v1
kind: Secret
metadata:
  {{- if .prepare }}
  name: {{ template "mastodon.fullname" . }}-prepare
  {{- else }}
  name: {{ template "mastodon.fullname" . }}
  {{- end }}
  labels:
    {{- include "mastodon.labels" . | nindent 4 }}
  annotations:
    {{- if .prepare }}
    "helm.sh/hook": pre-install
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
    "helm.sh/hook-weight": "-3"
    {{- end }}
type: Opaque
data:
  {{- if .Values.mastodon.s3.enabled }}
  {{- if not .Values.mastodon.s3.existingSecret }}
  AWS_ACCESS_KEY_ID: "{{ .Values.mastodon.s3.access_key | b64enc }}"
  AWS_SECRET_ACCESS_KEY: "{{ .Values.mastodon.s3.access_secret | b64enc }}"
  {{- end }}
  {{- end }}
  {{- if not .Values.mastodon.secrets.existingSecret }}
  {{- if not (empty .Values.mastodon.secrets.secret_key_base) }}
  SECRET_KEY_BASE: "{{ .Values.mastodon.secrets.secret_key_base | b64enc }}"
  {{- else }}
  SECRET_KEY_BASE: {{ required "secret_key_base is required" .Values.mastodon.secrets.secret_key_base }}
  {{- end }}
  {{- if not (empty .Values.mastodon.secrets.otp_secret) }}
  OTP_SECRET: "{{ .Values.mastodon.secrets.otp_secret | b64enc }}"
  {{- else }}
  OTP_SECRET: {{ required "otp_secret is required" .Values.mastodon.secrets.otp_secret }}
  {{- end }}
  {{- if not (empty .Values.mastodon.secrets.vapid.private_key) }}
  VAPID_PRIVATE_KEY: "{{ .Values.mastodon.secrets.vapid.private_key | b64enc }}"
  {{- else }}
  VAPID_PRIVATE_KEY: {{ required "vapid.private_key is required" .Values.mastodon.secrets.vapid.private_key }}
  {{- end }}
  {{- if not (empty .Values.mastodon.secrets.vapid.public_key) }}
  VAPID_PUBLIC_KEY: "{{ .Values.mastodon.secrets.vapid.public_key | b64enc }}"
  {{- else }}
  VAPID_PUBLIC_KEY: {{ required "vapid.public_key is required" .Values.mastodon.secrets.vapid.public_key }}
  {{- end }}
  {{- if not (empty .Values.mastodon.secrets.activeRecordEncryption.primaryKey) }}
  ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY: "{{ .Values.mastodon.secrets.activeRecordEncryption.primaryKey | b64enc }}"
  {{- else }}
  ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY: {{ required "activeRecordEncryption.primaryKey is required" .Values.mastodon.secrets.activeRecordEncryption.primaryKey }}
  {{- end }}
  {{- if not (empty .Values.mastodon.secrets.activeRecordEncryption.deterministicKey) }}
  ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY: "{{ .Values.mastodon.secrets.activeRecordEncryption.deterministicKey | b64enc }}"
  {{- else }}
  ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY: {{ required "activeRecordEncryption.deterministicKey is required" .Values.mastodon.secrets.activeRecordEncryption.deterministicKey }}
  {{- end }}
  {{- if not (empty .Values.mastodon.secrets.activeRecordEncryption.keyDerivationSalt) }}
  ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT: "{{ .Values.mastodon.secrets.activeRecordEncryption.keyDerivationSalt | b64enc }}"
  {{- else }}
  ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT: {{ required "activeRecordEncryption.keyDerivationSalt is required" .Values.mastodon.secrets.activeRecordEncryption.keyDerivationSalt }}
  {{- end }}
  {{- end }}
  {{- if not .Values.postgresql.enabled }}
  {{- if not .Values.postgresql.auth.existingSecret }}
  password: "{{ .Values.postgresql.auth.password | b64enc }}"
  {{- end }}
  {{- end }}
{{- end }}
