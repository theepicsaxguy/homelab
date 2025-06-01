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

## Simple Upgrade Process

### Configure Version

Set the version to upgrade to in `main.tf`. The `update_version` is only used when `update = true` is set for a node:

```hcl
image = {
  version         = "v1.10.2"
  update_version  = "v1.10.3" # renovate: github-releases=siderolabs/talos
  schematic       = file("${path.module}/talos/image/schematic.yaml")
}
```

> **Note:** You may commit and push this change if you're using GitOps automation, or run it locally via CLI if applying manually.

### Start Upgrade

```hcl
tofu apply -var 'upgrade_control={enabled=true,index=0}'
```

### Check Progress

```bash
tofu output upgrade_info
```

### Continue to Next Node

Use the exact command shown in the output above, or:

```bash
tofu apply -var 'upgrade_control={enabled=true,index=1}'
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
  version         = "v1.10.3"  # Changed from v1.10.2
  update_version  = "v1.10.3"
  schematic       = file("${path.module}/talos/image/schematic.yaml")
}

# Update the cluster Talos version
cluster = {
  name               = "talos"
  talos_version      = "v1.10.3"  # Changed from v1.10.2
  proxmox_cluster    = "kube"
  kubernetes_version = "1.33.1"
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
# Change: version = "v1.10.2" to version = "v1.10.3"
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
