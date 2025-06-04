---
title: Talos Upgrade Process
---

## Overview

This upgrade process uses a controlled index-based approach to upgrade Talos nodes sequentially. The upgrade system ensures only one node is upgraded at a time, maintaining cluster stability.

## Upgrade Sequence

The upgrade sequence is automatically derived from your node configuration:

1. **Control Plane Nodes** (upgraded first for quorum safety)
   - `ctrl-00` (index 0)
   - `ctrl-01` (index 1)
   - `ctrl-02` (index 2)

2. **Worker Nodes** (upgraded after control plane)
   - `work-00` (index 3)
   - `work-01` (index 4)
   - `work-02` (index 5)

## Pre-Upgrade Checklist

Before upgrading any node ensure:

1. **Recent etcd snapshot** exists. You can create one with:

   ```bash
   talosctl etcd snapshot -n ctrl-00 -o etcd-backup-$(date +%Y%m%d).db
   ```

2. **Longhorn volumes are healthy** and fully replicated:

   ```bash
   kubectl -n longhorn-system get volumes.longhorn.io
   ```

3. **Cluster is healthy**:

   ```bash
   talosctl health --wait
   kubectl get nodes
   ```

## Simple Upgrade Process

### Configure Version

Set the version to upgrade to in `main.tf`. The `update_version` is only used when `update = true` is set for a node:

```hcl
image = {
  version         = "<see https://github.com/siderolabs/talos/releases>"
  update_version  = "<see https://github.com/siderolabs/talos/releases>" # renovate: github-releases=siderolabs/talos
  schematic       = file("${path.module}/talos/image/schematic.yaml")
}
```

> **Note:** You may commit and push this change if you're using GitOps automation, or run it locally via CLI if applying manually.

### Start Upgrade

Run the helper script to automatically drain the node, snapshot etcd, and apply the upgrade:

```bash
scripts/upgrade_talos.sh 0
```

### Check Progress

```bash
tofu output upgrade_info
```

### Safety Checks Before Continuing

1. **Create an etcd snapshot** on a control-plane node:

   ```bash
   talosctl etcd snapshot -n ctrl-00 -o etcd-backup-$(date +%Y%m%d).db
   ```

2. **Verify Longhorn volume health**:

   ```bash
   kubectl -n longhorn-system get volumes.longhorn.io -o json | jq '.items[].status.robustness'
   ```

3. **Ensure cluster health**:

   ```bash
   talosctl health --wait
   kubectl get nodes
   ```

### Continue to Next Node

Use the exact command shown in the output above, or:

```bash
scripts/upgrade_talos.sh 1
```

### Finish Upgrade

```bash
tofu apply -var 'upgrade_control={enabled=false,index=-1}'
```

### Finalize Versions

After all nodes have been upgraded, update your cluster configuration in `main.tf`:

```hcl
# Update the base image version to match update_version
image = {
  version         = "<see https://github.com/siderolabs/talos/releases>"  # Updated base image version
  update_version  = "<see https://github.com/siderolabs/talos/releases>"
  schematic       = file("${path.module}/talos/image/schematic.yaml")
}

# Update the cluster Talos version
cluster = {
  name               = "talos"
  talos_version      = "<see https://github.com/siderolabs/talos/releases>"
  proxmox_cluster    = "kube"
  kubernetes_version = "<see https://github.com/kubernetes/kubernetes/releases>"
}
```

## Detailed Steps

### Monitor Node Upgrade

```bash
# Check Talos version
talosctl version --nodes 10.25.150.11

# Check Kubernetes node status
kubectl get nodes ctrl-00

# Wait for node to be Ready
kubectl wait --for=condition=Ready node/ctrl-00 --timeout=300s
```

### Update Base Version

After completing all upgrades, update the base version in `main.tf`:

```hcl
# Update version references to the new release
```

## Emergency Rollback

If issues occur during upgrade, disable upgrade mode immediately:

```bash
# This will stop the upgrade and prevent unintended changes
tofu apply -var 'upgrade_control={enabled=false,index=-1}'
```

## Monitoring Commands

```bash
# Check all node versions
talosctl version --nodes 10.25.150.11,10.25.150.12,10.25.150.13,10.25.150.21,10.25.150.22,10.25.150.23

# Check cluster health
kubectl get nodes -o wide

# Check upgrade progress
tofu output upgrade_info
```

## Notes

- Never skip nodes in the sequence - always upgrade sequentially
- Wait for each node to be fully Ready before proceeding
- Control plane nodes are upgraded first to maintain quorum
- The upgrade system prevents multiple nodes from upgrading simultaneously
