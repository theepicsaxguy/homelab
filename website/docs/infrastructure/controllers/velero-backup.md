---
sidebar_position: 4
title: Velero Backup Setup
description: Install Velero for cluster recovery using Minio and the CSI plugin
---

# Velero Installation and Usage

Velero manages cluster backups and restores. The configuration deploys the Helm chart in the `velero` namespace, pulls credentials from Bitwarden, and enables the node agent for volume snapshots.

## Key Points

- Velero is deployed via the Helm chart under `k8s/infrastructure/controllers/velero`.
- BackupStorageLocation and VolumeSnapshotLocation are configured by the Helm chart using `values.yaml` (the chart creates the CRs when `upgradeCRDs` is enabled).
- Credentials are provisioned via the `ExternalSecret` named `velero-minio-credentials` in the `velero` namespace; the chart is configured to use this secret.
- Backups are stored in the `velero` bucket on the cluster's MinIO/Truenas S3 endpoint as configured in the chart values.
- PVC data is backed up using Kopia filesystem backups (not CSI snapshots).
- Metrics are exposed via a ServiceMonitor for Prometheus.
- The `velero` namespace is labeled `pod-security.kubernetes.io/enforce: privileged` so the node agent can mount required host paths.

## Credentials Format

The `velero-minio-credentials` secret must expose three values:

- `MINIO_ACCESS_KEY`
- `MINIO_SECRET_KEY`
- `MINIO_ENDPOINT`

These values come from Bitwarden. The `ExternalSecret` assembles them into a
`cloud` file so Velero can read standard AWS credentials.

## Backup Configuration
