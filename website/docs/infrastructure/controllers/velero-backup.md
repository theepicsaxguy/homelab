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
- Snapshots are handled by Velero's built-in CSI plugin; `features: "EnableCSI,EnableCSISnapshotDataMover"` is enabled in chart values.
- Metrics are exposed via a ServiceMonitor for Prometheus.
- The `velero` namespace is labeled `pod-security.kubernetes.io/enforce: privileged` so the node agent can mount required host paths.
## Credentials Format

The `velero-minio-credentials` secret must expose three values:

- `MINIO_ACCESS_KEY`
- `MINIO_SECRET_KEY`
- `MINIO_ENDPOINT`

These values come from Bitwarden. The `ExternalSecret` assembles them into a
`cloud` file so Velero can read standard AWS credentials.

## CSI Snapshot Configuration

Velero uses CSI Volume Snapshots for backing up PVCs created with CSI storage drivers (Proxmox CSI, Longhorn).

### Required Components

1. **CSI Driver with Snapshot Support** (e.g., Proxmox CSI, Longhorn)
2. **External Snapshot Controller** (deployed by CSI driver or separately)
3. **VolumeSnapshotClass** with proper Velero discovery labels
4. **Velero Feature Flags**: `EnableCSI` and `EnableCSISnapshotDataMover`

### How It Works

1. Velero creates a `VolumeSnapshot` CRD object
2. External snapshot controller reconciles the snapshot
3. CSI driver creates storage-level snapshot (ZFS snapshot for Proxmox)
4. Velero node-agent uploads snapshot data to S3 (Kopia)
5. Local snapshot is cleaned up after successful upload
6. **Result**: All PV data in S3, ready for full disaster recovery

### Proxmox CSI Specific Requirements

**Important**: Proxmox CSI driver requires additional permissions for snapshot functionality. See [Proxmox CSI Storage](../storage/proxmox-csi.md#required-proxmox-permissions) for setup instructions.

The `kubernetes-csi@pve` user must have `VM.Snapshot` permission in Proxmox, otherwise Velero backups will fail with:

```
Error: Timed out awaiting reconciliation of volumesnapshot
Failed to wait for VolumeSnapshot to become ReadyToUse
rpc error: code = Internal desc = not authorized to access endpoint
```

### Verification

Test CSI snapshot creation:

```bash
# Create a test backup with data movement
velero backup create test-csi \
  --include-namespaces <namespace-with-proxmox-pvc> \
  --snapshot-move-data \
  --wait

# Check for CSI snapshots in backup output
velero backup describe test-csi --details | grep -A 5 "CSI Volume Snapshots"
```

Successful output should show:
- `CSI Volume Snapshots: Completed` with PVC names
- `Data Mover Backups: Completed` (indicates data uploaded to S3)

### Feature Flags Explained

- `EnableCSI`: Enables Velero to use CSI Volume Snapshot API instead of provider-specific snapshots
- `EnableCSISnapshotDataMover`: Enables data upload to S3 for disaster recovery (vs. local snapshots only)
- `snapshotMoveData: true`: Applied on Backup/Schedule to force data movement


**Note on CSI Plugin Version:**
Velero v1.17.1 and later includes CSI functionality built-in. Do NOT add a separate `velero-plugin-for-csi` initContainer to the Helm values - this will cause plugin registration conflicts and crash the Velero server.
