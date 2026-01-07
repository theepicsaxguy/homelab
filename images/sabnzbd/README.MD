# sabnzbd (custom image)

This is a custom Kubernetes-ready container image for [SABnzbd](https://sabnzbd.org/), built from source and designed
for GitOps-style deployments. It replaces the typical LinuxServer.io / hotio style wrappers with a deterministic Python
entrypoint that generates `sabnzbd.ini` from environment variables at startup.

---

## Key differences from upstream images

- **Config generation in Python** The included `entrypoint.py` always builds `sabnzbd.ini` deterministically from env
  vars. No shell glue, no partial merges, no surprises.

- **Environment variable convention** This image does **not** use the LSIO `SABNZBD__...` format. Instead it expects
  variables in the form:

SAB**<section>**<option>=<value>

Both `<section>` and `<option>` must be lowercase to match SAB’s INI schema.

Example:

```yaml
- SAB__misc__host_whitelist="sabnzbd,sabnzbd.media,sabnzbd.peekoff.com"
- SAB__misc__port="8080"
- SAB__servers__newsnewshostingcom__host="news.newshosting.com"

Default folders

SAB_DOWNLOAD_DIR → /downloads

SAB_INCOMPLETE_DIR → /downloads/incomplete

SAB_COMPLETE_DIR → /downloads/complete
These are created automatically on startup. Mount them as appropriate in your cluster (e.g. emptyDir for incomplete, NFS/PVC for complete).


User mapping
PUID and PGID envs control the runtime UID/GID (similar to LSIO). Defaults to 1000 but should be set to match your volume permissions.



---

Example Kubernetes ConfigMap

configMapGenerator:
  - name: sabnzbd-env-config
    literals:
      - PUID="2501"
      - PGID="2501"
      - SAB_DOWNLOAD_DIR="/downloads"
      - SAB_INCOMPLETE_DIR="/downloads/incomplete"
      - SAB_COMPLETE_DIR="/downloads/complete"
      - SAB__misc__host_whitelist="sabnzbd,sabnzbd.media,sabnzbd.peekoff.com"
      - SAB__misc__port="8080"
      - SAB__servers__newsnewshostingcom__host="news.newshosting.com"
      - SAB__servers__newsnewshostingcom__port="563"


---

Volumes

/config – persistent SABnzbd config

/downloads – parent dir for incomplete + complete

/downloads/incomplete → temp downloads (emptyDir recommended)

/downloads/complete → final downloads (PVC/NFS recommended)




---

Why this approach?

The goal was to make SABnzbd deployments predictable under GitOps:

All configuration is defined declaratively in env vars.

Startup is deterministic: you always know what ends up in sabnzbd.ini.

No reliance on hidden translation layers from upstream wrapper scripts.


This ensures reproducible behavior in Kubernetes, especially when combined with ArgoCD or Flux.
```
