---
sidebar_position: 3
title: SABnzbd
description: Usenet download client configuration
---

# SABnzbd

SABnzbd downloads from Usenet and serves as the backend for the *arr applications.

## Secret management

Credentials are stored in Bitwarden. An `ExternalSecret` pulls the API key and Usenet login into a Kubernetes `Secret`.

## Configuration seeding

An init container renders `sabnzbd.ini` from a ConfigMap template. If the file already exists, the container skips seeding.
