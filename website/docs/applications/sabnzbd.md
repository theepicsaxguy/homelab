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

An init container renders `sabnzbd.ini` from a ConfigMap template and always copies it into the config volume, applying any updated settings on every start.
