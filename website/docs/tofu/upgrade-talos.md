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
