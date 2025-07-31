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

