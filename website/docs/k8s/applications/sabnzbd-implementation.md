---
title: 'SABnzbd Deployment Notes'
---

SABnzbd runs as a StatefulSet and keeps its own `sabnzbd.ini`. Environment variables override any option at boot using the `SABNZBD__SECTION__OPTION` pattern.

## Image

The image builds SABnzbd from the official release tarball in a Python virtual environment. It runs on a minimal base image as user 2501. Dependencies from `requirements.txt`, including `CherryPy`, install during the build. The build copies a default `sabnzbd.ini` into `/config` only when that directory is empty.

## Configuration

`sabnzbd-env-config` ships baseline defaults that avoid secrets. `sabnzbd-secrets` pulls API keys and Usenet credentials from Bitwarden. Update either and redeploy to apply changes without manual edits.

## Storage

`/config` lives on a 6 Gi Longhorn PersistentVolumeClaim (PVC). `/downloads/incomplete` mounts the StatefulSet-managed `incomplete-downloads` claim, which provisions 50 Gi on Longhorn so partial files survive restarts without orphaned PVCs. `/downloads/nzb-backup` keeps 1 Gi on Longhorn for `.nzb` archives. Completed jobs land on the shared `media-share` network file system (NFS) claim at `/app/data/complete`. `/tmp` stays ephemeral for scratch space inside the container.

## Network

`SABNZBD__MISC__HOST_WHITELIST` holds allowed hostnames. Add entries to the ConfigMap to expose new names.

## Upgrades

Bump the `SAB_VERSION` build argument or push a `sabnzbd-x.y.z` tag. The image build workflow publishes new tags, and Flux or ArgoCD roll them out. Existing PVCs keep their configs, and environment variables still take precedence.

## Debug

The image has no shell or package manager. Use `kubectl debug` if you need an interactive session.
