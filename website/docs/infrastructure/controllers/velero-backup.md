---
sidebar_position: 4
title: Velero Backup Setup
description: Install Velero for cluster recovery using Minio and the CSI plugin
---

# Velero Installation and Usage

Velero manages cluster backups and restores. The configuration deploys the Helm chart in the `velero` namespace, pulls credentials from Bitwarden, and enables the node-agent for volume snapshots.

## Key Points

- Credentials come from the `ExternalSecret` named `velero-minio-credentials`.
- Backups are stored in the `velero` bucket on the cluster's Minio instance.
- Snapshots are handled by the Velero CSI plugin.
- Metrics are exposed via a ServiceMonitor for Prometheus.
- The `velero` namespace is labeled `pod-security.kubernetes.io/enforce: privileged` so the node-agent can mount required host paths.

Once ArgoCD syncs the manifests, verify pods are running in `velero` before creating backups.

## Credentials Format

The `velero-minio-credentials` secret must expose three values:

- `MINIO_ACCESS_KEY`
- `MINIO_SECRET_KEY`
- `MINIO_ENDPOINT`

These values come from Bitwarden. The `ExternalSecret` assembles them into a
`cloud` file so Velero can read standard AWS-style credentials.
