---
title: Mastodon PostgreSQL Secrets Management
---

This document addresses issues related to managing secrets for Mastodon with the Zalando PostgreSQL Operator, including consistent naming conventions.

**Bitwarden Naming Convention Reminder:** For consistency, use conventions like `mastodon-postgresql-ca` for secret names.

### CA in Separate Secret Not Mounted

*   **Problem:** Postgres continues to report issues finding the CA bundle, and clients experience untrusted issuer errors, even when a separate CA Kubernetes secret is defined.
*   **Rationale:** The Zalando operator only mounts a separate CA secret if `tls.caSecretName` is explicitly specified in addition to `tls.secretName`. Simply defining `tls.caFile` is insufficient.
*   **Fix:** Ensure both `secretName:` (for the server key and certificate) and `caSecretName:` (for the CA bundle) are specified in the operator manifest. This ensures both secrets are mounted in `/tls`, providing the full certificate chain to Spilo.

**Key configuration changes:**

*   **TLS Secret Specification:**
    *   **Key lines changed:**
        ```yaml
        tls:
          secretName: mastodon-postgresql-server
          caSecretName: mastodon-postgresql-ca
          caFile: ca.crt
        ```
    *   **Symptom:** Postgres reports issues finding the CA bundle; clients experience untrusted issuer errors.
    *   **Rationale:** This modification explicitly defines `secretName` and `caSecretName` to ensure both server certificates and the CA bundle are mounted, enforcing encrypted connections.

*   **Kustomization File Update:**
    *   **Key lines changed:**
        ```yaml
        - db-secrets.yaml
        - postgresql-server-cert.yaml
        - mastodon-postgresql-ca.yaml
        ```
    *   **Symptom:** Cert-manager issued certificates are not being managed or renewed.
    *   **Rationale:** Adding `postgresql-server-cert.yaml` and `mastodon-postgresql-ca.yaml` ensures that cert-manager-issued server and CA certificates are automatically managed and renewed, which is crucial for a scalable and secure cluster.

### Inconsistent Naming Leading to Secret Mount Confusion

*   **Problem:** Varied volume names (e.g., `pgbouncer-ca` vs. `db-ca`) and subPaths (e.g., `pgbouncer-ca.crt` vs. `ca.crt`) across multiple manifests cause confusion and errors in mounting the correct certificate files.
*   **Rationale:** Lack of standardization in naming conventions for volumes and certificate files across different Kubernetes manifests.
*   **Fix:** Consolidate and standardize naming conventions. Use a single, consistent volume name (e.g., `db-ca`) and a single key name (e.g., `ca.crt`) for all certificate-related secrets and mounts across all workloads.

**Key configuration changes:**

*   **Volume Mount Standardization:**
    *   **Key lines changed:**
        ```yaml
        volumeMounts:
          - name: db-ca
            mountPath: /opt/mastodon/.postgresql/root.crt
            subPath: ca.crt
        ```
    *   **Symptom:** Incorrect certificate files are mounted, leading to errors.
    *   **Rationale:** This change standardizes the volume name from `pgbouncer-ca` to `db-ca` and ensures the CA certificate is mounted at the correct `mountPath` and `subPath` for Mastodon, reducing ambiguity across multiple workloads.

### Best Practices

*   **Simplify Naming Conventions:** Implement a consistent naming strategy for secrets, volumes, and certificate keys across all Kubernetes manifests to minimize ambiguity and errors.

### Checking Your Work

To validate your changes, run the following commands:

```bash
kustomize build applications/web/mastodon/
npm run build
```

### See also

*   [Mastodon Deployment Manifest](https://github.com/theepicsaxguy/homelab/k8s/blob/main/applications/web/mastodon/deployment.yaml)
*   [Mastodon Kustomization](http://github.com/theepicsaxguy/homelab/blob/main/applications/web/mastodon/kustomization.yaml)
