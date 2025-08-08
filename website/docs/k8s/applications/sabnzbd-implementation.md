---
title: 'SABnzbd Deployment Notes'
---

SABnzbd runs as a StatefulSet and manages its own `sabnzbd.ini` from environment variables.

## Image

The image builds SABnzbd in a Python 3.12 virtualenv and runs on `distroless` as user `2501`.

## Configuration

Settings come from `sabnzbd-env-config` and Bitwarden secrets. Update values and apply; no files need edits.

## Storage

Configuration uses a 5 Gi PVC. Incomplete downloads stay on an `emptyDir` volume. Finished downloads write to the shared media PVC.

## Network

`SABNZBD__MISC__HOST_WHITELIST` lists allowed hostnames. Add entries to the ConfigMap to expose new names.

## Secrets

API keys and usenet credentials live in Bitwarden and sync through an ExternalSecret.
