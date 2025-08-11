---
title: Mastodon PostgreSQL PgBouncer Rotation
---

This document addresses issues related to PgBouncer certificate rotation when using the Zalando Postgres Operator.

### PgBouncer Serving Stale Certificates

*   **Problem:** After rotating TLS secrets, PgBouncer continues to present its original, stale self-signed certificate.
*   **Rationale:** Unlike Spilo, the Zalando operator doesn't automatically redeploy or roll the PgBouncer connection pooler upon secret changes. Volume updates alone don't trigger a Pod restart for PgBouncer.
*   **Fix:** Manually restart the PgBouncer deployments (e.g., by deleting the pods or toggling `enableConnectionPooler`) to force a remount of the updated secret and ensure the correct certificate authority signed certificate becomes active.

### Best Practices

*   **Understand Operator Behavior:** Don't assume automatic secret reloads. Always test certificate rotation end-to-end using `openssl s_client` against PgBouncer and prepare to manually restart components if necessary.

### Checking Your Work

To validate your changes, run the following commands:

```shell
kustomize build applications/web/mastodon/
npm run build
```

### See also

*   [Mastodon Deployment Manifest](https://github.com/theepicsaxguy/homelab/k8s/blob/main/applications/web/mastodon/deployment.yaml)
*   [Mastodon Kustomization](http://github.com/theepicsaxguy/homelab/blob/main/applications/web/mastodon/kustomization.yaml)
