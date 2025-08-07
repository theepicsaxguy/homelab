---
title: Mastodon PostgreSQL PgBouncer Rotation
---

This document addresses issues related to PgBouncer certificate rotation when using the Zalando Postgres Operator.

### PgBouncer Serving Stale Certificates

*   **Problem:** After rotating TLS secrets, PgBouncer continues to present its original, stale self-signed certificate.
*   **Rationale:** Unlike Spilo, the Zalando operator does not automatically redeploy or roll the PgBouncer connection pooler upon secret changes. Volume updates alone do not trigger a Pod restart for PgBouncer.
*   **Fix:** Manually restart the PgBouncer deployments (e.g., by deleting the pods or toggling `enableConnectionPooler`) to force a remount of the updated secret and ensure the correct CA-signed certificate is served.

### Best Practices

*   **Understand Operator Behavior:** Do not assume automatic secret reloads. Always test certificate rotation end-to-end (e.g., using `openssl s_client` against PgBouncer) and be prepared to manually restart components if necessary.

### Checking Your Work

To validate your changes, run the following commands:

```bash
kustomize build applications/web/mastodon/
npm run build
```

### See also

*   [Mastodon Deployment Manifest](https://github.com/your-repo/k8s/blob/main/applications/web/mastodon/deployment.yaml)
*   [Mastodon Kustomization](http://github.com/theepicsaxguy/homelab/blob/main/applications/web/mastodon/kustomization.yaml)
