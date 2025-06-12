---
sidebar_position: 4
title: Velero Backup Setup
description: Install Velero for cluster recovery using Minio and Longhorn
---

# Velero Installation and Usage

Velero manages cluster backups and restores. The configuration deploys the Helm chart in the `velero` namespace, pulls credentials from Bitwarden, and enables the node-agent for volume snapshots.

## Key Points

- Credentials come from the `ExternalSecret` named `velero-minio-credentials`.
- Backups are stored in the `velero` bucket on the cluster's Minio instance.
- Longhorn snapshots are handled by the Longhorn Velero plugin.
- Metrics are exposed via a ServiceMonitor for Prometheus.

Once ArgoCD syncs the manifests, verify pods are running in `velero` before creating backups.
