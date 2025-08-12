---
sidebar_position: 3
title: SABnzbd
description: Usenet download client configuration
---

# SABnzbd

<!-- vale off -->
SABnzbd downloads from Usenet and serves as the backend for the *arr applications.
<!-- vale on -->

## Secret management

Credentials are stored in Bitwarden. An `ExternalSecret` pulls the API key and Usenet login into a Kubernetes `Secret`.

## Configuration seeding

An init container uses `envsubst` to render `sabnzbd.ini` from a ConfigMap template. The file is copied into the config volume on every start so new settings take effect without manual steps.

## Persistent data

The image stores its configuration under `/config/sabnzbd` to keep system directories like `lost+found` out of the SABnzbd search path. This avoids permission warnings when the PVC already contains `lost+found`.
