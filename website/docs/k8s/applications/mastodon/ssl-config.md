---
title: Mastodon PostgreSQL SSL Configuration
---

This document addresses issues related to configuring SSL/TLS for Mastodon when using the Zalando PostgreSQL Operator.

### CA File Not Found in Mastodon Containers

*   **Symptom:** Mastodon Rails/Sidekiq/Streaming processes fail TLS handshakes due to an inability to locate the PostgreSQL CA certificate.
*   **Rationale:** Mastodon applications specifically look for their TLS bundle at `/opt/mastodon/.postgresql/root.crt`. Incorrect mount paths (e.g., `/etc/ssl/certs/pgbouncer-ca.crt`) are ignored by the application.
*   **Fix:** Mount the CA certificate at the expected Mastodon location (`/opt/mastodon/.postgresql/root.crt`). Ensure environment variables `DB_SSLMODE=verify-ca` and `DB_SSLROOTCERT=/opt/mastodon/.postgresql/root.crt` are correctly configured.

**Key configuration changes:**

*   **Environment Variable Update:**
    *   **Key line changed:** `DB_SSLROOTCERT=/opt/mastodon/.postgresql/root.crt`
    *   **Symptom:** TLS handshake failed.
    *   **Rationale:** Mastodon only reads `/opt/mastodon/.postgresql/root.crt`. This change updates the `DB_SSLROOTCERT` environment variable to point to Mastodon's expected CA certificate location, preventing "file not found" errors and ensuring proper TLS configuration.

*   **Explicit Environment Variable Injection:**
    *   **Key lines changed:**
        ```yaml
        env:
          - name: DB_SSLMODE
            value: verify-ca
          - name: DB_SSLROOTCERT
            value: /opt/mastodon/.postgresql/root.crt
        ```
    *   **Symptom:** Inconsistent database connection behavior across Mastodon replicas.
    *   **Rationale:** Explicitly injecting both `DB_SSLMODE=verify-ca` and `DB_SSLROOTCERT=/opt/mastodon/.postgresql/root.crt` into each Mastodon workload (web, Sidekiq, streaming, migrate) ensures consistent and secure database connections across all scaled replicas.

### Best Practices

*   **Align with Application Defaults:** Always verify where your application (e.g., Mastodon) expects TLS files to be located, rather than solely relying on where they're mounted. For Mastodon, the default location is `/opt/mastodon/.postgresql`.

### Checking Your Work

To validate your changes, run the following commands:

```shell
kustomize build applications/web/mastodon/
npm run build
```

### See also

*   [Mastodon Deployment Manifest](https://github.com/theepicsaxguy/homelab/k8s/blob/main/applications/web/mastodon/deployment.yaml)
*   [Mastodon Kustomization](http://github.com/theepicsaxguy/homelab/blob/main/applications/web/mastodon/kustomization.yaml)
