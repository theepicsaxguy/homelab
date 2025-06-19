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

Set the version to upgrade to in `main.tf` under the `talos_image` block. The
`update_version` value only applies when `update = true` is set for a node in
`tofu/nodes.auto.tfvars`. Nodes with `freeze = true` keep their current image
during the rollout:

```hcl
talos_image = {
  version         = "<see https://github.com/siderolabs/talos/releases>"
  update_version  = "<see https://github.com/siderolabs/talos/releases>" # renovate: github-releases=siderolabs/talos
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
# Update the base `talos_image` version to match `update_version`
talos_image = {
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
