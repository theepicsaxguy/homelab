---
title: 'SABnzbd Deployment Notes'
---

SABnzbd runs as a StatefulSet and keeps its own `sabnzbd.ini`. Environment variables override any option at boot using the `SABNZBD__SECTION__OPTION` pattern.

## Image

The image builds SABnzbd from the official release tarball in a Python 3.12 virtual environment. It runs on a distroless base as UID 2501. A default `sabnzbd.ini` is generated during the build and copied to `/config` only when that directory is empty.

## Configuration

`sabnzbd-env-config` sets non‑secret defaults. `sabnzbd-secrets` pulls API keys and usenet credentials from Bitwarden. Update either and redeploy; no manual edits are needed.

## Storage

`/config` uses a 5 Gi PVC. `/downloads/incomplete` is an `emptyDir`. Completed files write to the existing `media-share` PVC under `/app/data`.

## Network

`SABNZBD__MISC__HOST_WHITELIST` holds allowed hostnames. Add entries to the ConfigMap to expose new names.

## Upgrades

Bump the `SAB_VERSION` ARG or push a `sabnzbd-x.y.z` tag. The image build workflow publishes new tags, and Flux or ArgoCD rolls them out. Existing PVCs keep their configs, and env vars still take precedence.

## Debug

The image has no shell or package manager. Use `kubectl debug` if you need an interactive session.
