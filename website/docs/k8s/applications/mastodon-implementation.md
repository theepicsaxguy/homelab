---
title: 'Mastodon Deployment Notes'
---

This note summarizes the Mastodon configuration relevant for the Kubernetes manifests in `/k8s/applications/web/mastodon`.

## Database Connection

Sidekiq fails to start when `PGSSLMODE` is set to `require`. The manifests disable SSL to align with the Zalando Postgres Operator:

```yaml
# k8s/applications/web/mastodon/kustomization.yaml
configMapGenerator:
  - name: mastodon-env
    literals:
      - PGSSLMODE=disable
```

## Email Configuration

Mastodon sends emails through an SMTP server. The credentials and settings come from the `mastodon-app-secrets` ExternalSecret:

```yaml
# k8s/applications/web/mastodon/externalsecret.yaml
data:
  - secretKey: SMTP_SERVER
    remoteRef: { key: app-mastodon-smtp-server }
  - secretKey: SMTP_PORT
    remoteRef: { key: app-mastodon-smtp-port }
  - secretKey: SMTP_LOGIN
    remoteRef: { key: app-mastodon-smtp-login }
  - secretKey: SMTP_PASSWORD
    remoteRef: { key: app-mastodon-smtp-password }
  - secretKey: SMTP_FROM_ADDRESS
    remoteRef: { key: app-mastodon-smtp-from-address }
```

Rails is configured to use implicit TLS on port 465 and to avoid STARTTLS:

```yaml
# k8s/applications/web/mastodon/kustomization.yaml
configMapGenerator:
  - name: mastodon-common-env
    literals:
      - SMTP_DELIVERY_METHOD=smtp
      - SMTP_AUTH_METHOD=login
      - SMTP_SSL=true
      - SMTP_TLS=false
      - SMTP_ENABLE_STARTTLS_AUTO=false
  - SMTP_ENABLE_STARTTLS=never
```

## Media Storage

Attachments are stored on a Persistent Volume Claim named `mastodon-public-pvc`.
The claim requests 30Gi from Longhorn:

```yaml
# k8s/applications/web/mastodon/pvc-public.yaml
spec:
  accessModes: [ "ReadWriteMany" ]
  resources:
    requests:
      storage: 30Gi
  storageClassName: longhorn
```

## Sidekiq Resources

Sidekiq processes background jobs. A larger instance benefits from more
CPU and memory:

```yaml
# k8s/applications/web/mastodon/sidekiq-deployment.yaml
resources:
  requests:
    cpu: "200m"
    memory: "512Mi"
  limits:
    cpu: "1000m"
    memory: "2Gi"
```

