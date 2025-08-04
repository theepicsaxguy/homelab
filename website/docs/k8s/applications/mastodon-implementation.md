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
The claim now requests 50Gi from Longhorn:

```yaml
# k8s/applications/web/mastodon/pvc-public.yaml
spec:
  accessModes: [ "ReadWriteMany" ]
  resources:
    requests:
      storage: 50Gi
  storageClassName: longhorn
```

## Content Delivery

Media and static assets are served from `cdn.goingdark.social` through an internal Nginx proxy backed by MinIO. Mastodon trusts this host via the `EXTRA_MEDIA_HOSTS` variable; `CDN_HOST` stays unset so Rails keeps serving its own compiled assets:

```yaml
# k8s/applications/web/mastodon/base/kustomization.yaml
configMapGenerator:
  - name: mastodon-env
    literals:
      - EXTRA_MEDIA_HOSTS=https://cdn.goingdark.social
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

## Container Images

This deployment uses the Glitch-soc variant of Mastodon for additional features.
All components reference the `nightly.2025-07-31` tag:

```yaml
# k8s/applications/web/mastodon/web-deployment.yaml
image: ghcr.io/glitch-soc/mastodon:nightly.2025-07-31

# k8s/applications/web/mastodon/sidekiq-deployment.yaml
image: ghcr.io/glitch-soc/mastodon:nightly.2025-07-31

# k8s/applications/web/mastodon/streaming-deployment.yaml
image: ghcr.io/glitch-soc/mastodon-streaming:nightly.2025-07-31
```

