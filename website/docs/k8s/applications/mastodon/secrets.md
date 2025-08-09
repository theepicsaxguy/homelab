---
title: Mastodon PostgreSQL Secrets Management
---

This document addresses issues related to managing secrets for Mastodon with the Zalando PostgreSQL Operator, including consistent naming conventions.

**Bitwarden Naming Convention Reminder:** for consistency, use conventions like `mastodon-postgresql-ca` for secret names.

### CA in separate secret not mounted

*   **Problem:** Postgres reports issues finding the CA bundle, and clients experience untrusted issuer errors, even when a separate CA Kubernetes secret is defined.
*   **Rationale:** The Zalando operator mounts a separate CA secret only if `tls.caSecretName` is explicitly specified along with `tls.secretName`. Defining `tls.caFile` alone doesn't work.
*   **Fix:** Specify both `secretName:` (for the server key and certificate) and `caSecretName:` (for the CA bundle) in the operator manifest. This ensures both secrets are mounted in `/tls`, providing the full certificate chain to Spilo.

**Key configuration changes:**

*   **TLS secret specification:**
    *   **Key lines changed:**
        ```yaml
        tls:
          secretName: mastodon-postgresql-ca
          caSecretName: mastodon-postgresql-ca
          caFile: ca.crt
        ```
    *   **Symptom:** Postgres reports issues finding the CA bundle; clients experience untrusted issuer errors.
    *   **Rationale:** This modification explicitly defines `secretName` and `caSecretName` to ensure both server certificates and the CA bundle are mounted, enforcing encrypted connections.

*   **Kustomization file update:**
    *   **Key lines changed:**
        ```yaml
        - db-secrets.yaml
        - postgresql-server-cert.yaml
        - mastodon-postgresql-ca.yaml
        ```
    *   **Symptom:** Cert-manager issued certificates aren't managed or renewed.
    *   **Rationale:** Adding `postgresql-server-cert.yaml` and `mastodon-postgresql-ca.yaml` ensures that certificates issued by cert-manager for servers and certificate authorities are automatically managed and renewed, which is crucial for a scalable and secure cluster.

### Inconsistent naming leading to secret mount confusion

*   **Problem:** Varied volume names (for example, `pgbouncer-ca` versus `db-ca`) and path values (for example, `pgbouncer-ca.crt` versus `ca.crt`) across manifests cause confusion and errors in mounting the correct certificate files.
*   **Rationale:** Lack of standardization in naming conventions for volumes and certificate files across different Kubernetes manifests.
*   **Fix:** Standardize naming conventions. Use a single, consistent volume name (for example, `db-ca`) and a single key name (for example, `ca.crt`) for all certificate secrets and mounts across all workloads.

**Key configuration changes:**

*   **Volume mount standardization:**
    *   **Key lines changed:**
        ```yaml
        volumeMounts:
          - name: db-ca
            mountPath: /opt/mastodon/.postgresql/root.crt
            subPath: ca.crt
        ```
    *   **Symptom:** Wrong certificate files are mounted, leading to errors.
    *   **Rationale:** This change standardizes the volume name from `pgbouncer-ca` to `db-ca` and ensures the CA certificate is mounted at the correct `mountPath` and `subPath` for Mastodon, reducing ambiguity across multiple workloads.

### Best practices

*   **Simplify naming conventions:** Implement a consistent naming strategy for secrets, volumes, and certificate keys across all Kubernetes manifests to minimize ambiguity and errors.

### Checking your work

To validate your changes, run the following commands:

```shell
kustomize build applications/web/mastodon/
npm run build
```

### See also

*   [Mastodon Deployment Manifest](https://github.com/theepicsaxguy/homelab/k8s/blob/main/applications/web/mastodon/deployment.yaml)
*   [Mastodon Kustomization](http://github.com/theepicsaxguy/homelab/blob/main/applications/web/mastodon/kustomization.yaml)
