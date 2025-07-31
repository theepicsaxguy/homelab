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

