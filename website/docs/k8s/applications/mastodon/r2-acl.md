---
title: Mastodon Cloudflare R2 access control
---
This document covers access control list (ACL) errors when Mastodon uses Cloudflare R2 for object storage.

### R2 rejects access control lists

*   **Problem:** Mastodon tries to set a `public-read` access control list and R2 returns an error.
*   **Rationale:** R2 speaks the S3 API but ignores access control lists.
*   **Fix:** Leave `S3_PERMISSION` blank so Mastodon skips ACL calls.

**Key configuration change:**

```yaml
- S3_PERMISSION=
```

### Best practices

*   Leave `S3_PERMISSION` unset when the object store doesn't support access control lists.

### Checking your work

To validate your changes, run the following commands:

```shell
kustomize build applications/web/mastodon/
npm run build
```

### See also

*   [Mastodon Kustomization](https://github.com/theepicsaxguy/homelab/blob/main/k8s/applications/web/mastodon/kustomization.yaml)

