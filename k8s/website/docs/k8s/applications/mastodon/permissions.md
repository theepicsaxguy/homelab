---
title: Mastodon PostgreSQL Permissions
---

This document addresses permission issues encountered when deploying Mastodon with the Zalando Postgres Operator.

### Replica Startup Permission Errors

*   **Problem:** Postgres replica pods crash on startup with "Permission denied" errors when attempting to load server certificate files from `/tls`.
*   **Rationale:** The `/tls` directory and its contents are owned by `root`, but the Spilo container runs as a non-root user (UID 1000, GID 101), lacking necessary permissions.
*   **Fix:** Grant Postgres pods group-ownership of TLS files by setting `spiloFSGroup: 103` so non-root containers can read them.

**Key configuration changes:**

*   **`spiloFSGroup` setting:**
    *   **Key line changed:** `spiloFSGroup: 103`
    *   **Symptom:** Postgres replica pods crash with "Permission denied" errors.
    *   **Rationale:** This configures Kubernetes to change the group ownership of mounted TLS files to GID 103 (the default Postgres group in the Spilo image), resolving the permission issue.

### Best Practices

*   **Verify File Ownership:** When mounting secrets for non-root containers, inspect the container's UID/GID and use mechanisms like `spiloFSGroup` to ensure appropriate file permissions.

### Checking Your Work

To validate your changes, run the following commands:

```bash
kustomize build applications/web/mastodon/
npm run build
```

### See also

*   [Mastodon Deployment Manifest](https://github.com/your-repo/k8s/blob/main/applications/web/mastodon/deployment.yaml)
*   [Mastodon Kustomization](http://github.com/theepicsaxguy/homelab/blob/main/applications/web/mastodon/kustomization.yaml)
