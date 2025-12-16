---
title: Talos Upgrade Process
---

## Overview

<<<<<<< Updated upstream
Talos upgrades are handled through OpenTofu using a **marker-based system**. Two versions are defined:

- `talos_image.version` - Current deployed version
- `talos_image.update_version` - Target version (updated by Renovate)

You control which nodes upgrade by setting `upgrade = true` in their node config.

## How It Works

1. Renovate updates `talos_image.update_version` to the new version
2. You set `upgrade = true` on individual nodes in `nodes_config`
3. Nodes with `upgrade = true` use `update_version`, others stay at `version`
4. Run `tofu apply` - only marked nodes upgrade
5. After all nodes are done, update `version` to match and set all `upgrade = false`

```hcl
talos_image.version        = "v1.10.3"  # current base
talos_image.update_version = "v1.11.5"  # target

# In nodes_config:
"ctrl-00" = { ..., upgrade = true }   →  uses v1.11.5 (upgrade/stay upgraded)
"ctrl-01" = { ..., upgrade = false }  →  uses v1.10.3 (stay at base)
```

:::tip Key Rule Once a node has `upgrade = true`, **keep it true** until you update the base `version` to match. Setting
`upgrade = false` before updating the base version triggers a downgrade! :::

## Upgrade Process

### Step 1: Check Current Status

```bash
cd tofu
tofu plan
```

The `upgrade_sequence` output shows:

- `recommended_order` - Suggested upgrade sequence (control plane first, then workers)
- `current_version` - Base version
- `target_version` - Target version
- `nodes_marked_for_upgrade` - Nodes with `upgrade = true`
- `node_versions` - Effective version per node

### Step 2: Mark First Node for Upgrade

Edit `tofu/nodes.auto.tfvars`:

```hcl
nodes_config = {
  "ctrl-00" = {
    machine_type = "controlplane"
    ip           = "10.25.150.10"
    # ... other config ...
    upgrade      = true  # Mark for upgrade
  }
  "ctrl-01" = {
    # ... config ...
    upgrade      = false  # Keep at current version
  }
  # ...
}
```

### Step 3: Apply First Upgrade

```bash
tofu apply
```

Only `ctrl-00` will be replaced. Wait for it to become Ready:

```bash
kubectl get nodes -w
```

### Step 4: Continue Sequentially

Set `upgrade = true` on the next node:

```hcl
"ctrl-01" = {
  # ... config ...
  upgrade = true  # Now mark ctrl-01
}
```

```bash
tofu apply
```

Repeat for all nodes in the recommended order:

1. Control plane: `ctrl-00`, `ctrl-01`, `ctrl-02`
2. Workers: `work-00`, `work-01`, `work-02`, `work-03`

### Step 5: Finalize Upgrade

:::warning Important **Keep `upgrade = true`** on nodes that have been upgraded until you finalize. Setting
`upgrade = false` before updating the base version will trigger a downgrade! :::

After **all nodes** are upgraded:

1. **First**, update `talos_image.version` to match `update_version`:

```hcl
# tofu/talos_image.auto.tfvars
talos_image = {
  version        = "v1.11.5"  # Updated from v1.10.3
  update_version = "v1.11.5"
  schematic_path = "talos/image/schematic.yaml.tftpl"
}
```

2. **Then**, set all nodes to `upgrade = false`:

```hcl
# tofu/nodes.auto.tfvars
nodes_config = {
  "ctrl-00" = { ..., upgrade = false }
  "ctrl-01" = { ..., upgrade = false }
  # ...
}
```

3. Apply to clean up state:

```bash
tofu apply
```

This is safe because `upgrade = false` now means "use version" which is `v1.11.5`.

## Bulk Upgrades

To upgrade all nodes at once, set `upgrade = true` on all nodes, then run `tofu apply`.

## Monitoring

During upgrades:

```bash
# Watch Kubernetes node status
kubectl get nodes -w

# Check Talos version on specific node
talosctl version --nodes <NODE_IP>

# Verify cluster health
kubectl get pods --all-namespaces
```

## Rollback

If a node upgrade fails **immediately** (before other nodes are upgraded), you can set `upgrade = false` to revert to
the base version:

```hcl
"ctrl-01" = {
  # ... config ...
  upgrade = false  # Revert to base version (v1.10.3)
}
```

```bash
tofu apply
```

:::note This only works if `talos_image.version` is still the old version. Once you've updated the base version, rolling
back requires setting `version` back to the old value. :::

## Configuration Reference

### `talos_image.auto.tfvars`

```hcl
talos_image = {
  version        = "v1.10.3"  # Current deployed version
  update_version = "v1.11.5"  # Target version (updated by Renovate)
=======
The Talos upgrade process is **fully automated**. Simply change the version and run `tofu apply` once - all nodes will upgrade sequentially with automatic health checks.

## Automated Upgrade Flow

The upgrade system automatically:

1. ✓ Upgrades control plane nodes first (sorted alphabetically: `ctrl-00` → `ctrl-01` → `ctrl-02`)
2. ✓ Runs health checks after each control plane node
3. ✓ Upgrades worker nodes sequentially (`work-00` → `work-01` → `work-02`)
4. ✓ Runs health checks after each worker node
5. ✓ Ensures only one node upgrades at a time via dependency chaining

**No manual intervention required!**

## Upgrade Process

### 1. Change Version

Edit `tofu/talos_image.auto.tfvars` and update the version:

```hcl
talos_image = {
  version        = "v1.10.0"  # Change this to your target version
>>>>>>> Stashed changes
  schematic_path = "talos/image/schematic.yaml.tftpl"
}
```

<<<<<<< Updated upstream
### `nodes.auto.tfvars`

```hcl
nodes_config = {
  "ctrl-00" = {
    machine_type = "controlplane"
    ip           = "10.25.150.10"
    mac_address  = "bc:24:11:6f:10:01"
    vm_id        = 8100
    upgrade      = false  # Set to true to upgrade
  }
  # ...
}
```

## Best Practices

1. **Follow the recommended order** - Control plane nodes first, then workers
2. **One node at a time** - Wait for each node to be Ready before continuing
3. **Monitor closely** - Watch `kubectl get nodes` during each upgrade
4. **Keep backups current** - Ensure Longhorn backups are up to date
5. **Keep `upgrade = true`** - Don't set `upgrade = false` on upgraded nodes until finalization
6. **Update base version last** - Only update `talos_image.version` after ALL nodes are upgraded
7. **Finalize in order** - First update `version`, then set all `upgrade = false`

## Troubleshooting

### Node Stuck After Replacement

```bash
kubectl describe node <node-name>
talosctl --nodes <NODE_IP> services
talosctl --nodes <NODE_IP> dmesg
```

### Check Effective Versions

```bash
tofu output -json | jq '.upgrade_sequence.value.node_versions'
```

### Partial Upgrade State

```bash
tofu refresh
tofu plan
```
=======
### 2. Run Apply Once

```shell
tofu apply
```

That's it! OpenTofu will:
- Upgrade each node sequentially
- Run `talosctl health` after each node
- Automatically proceed to the next node when health checks pass

### 3. Monitor Progress (Optional)

While the upgrade is running, you can monitor in another terminal:

```shell
# Watch all node versions
watch -n 5 "talosctl version --nodes 10.25.150.11,10.25.150.12,10.25.150.13,10.25.150.21,10.25.150.22,10.25.150.23"

# Watch Kubernetes nodes
watch -n 5 "kubectl get nodes -o wide"

# Watch Longhorn volumes
kubectl get volumes.longhorn.io -n longhorn-system -o wide
```

### 4. Verify Completion

```shell
# Check all nodes are on the new version
talosctl version --nodes 10.25.150.11,10.25.150.12,10.25.150.13,10.25.150.21,10.25.150.22,10.25.150.23

# Check all nodes are Ready
kubectl get nodes

# Check Longhorn health
kubectl get volumes.longhorn.io -n longhorn-system
```

### 5. Update Cluster Version Variable

After all nodes are upgraded, update the cluster version in `tofu/config.auto.tfvars`:

```hcl
versions = {
  talos      = "v1.10.0"  # Update to match talos_image.version
  kubernetes = "1.32.0"   # Update if also upgrading Kubernetes
}
```

Then apply:

```shell
tofu apply
```

## Upgrade Sequence

The upgrade sequence is automatically determined:

1. **Control Plane Nodes** (sorted alphabetically)
   - `ctrl-00`
   - `ctrl-01`
   - `ctrl-02`

2. **Worker Nodes** (sorted alphabetically)
   - `work-00`
   - `work-01`
   - `work-02`

Each node waits for the previous node's health check before starting.

## Health Checks

After each node upgrades, OpenTofu runs:

```shell
talosctl health --nodes <node-ip> --wait-timeout=10m
```

This verifies:
- Talos API is responding
- Kubernetes node is Ready
- All system services are healthy

The next node won't start upgrading until the current node passes health checks.

## View Upgrade Configuration

```shell
# See the upgrade sequence and current version
tofu output upgrade_sequence
```

Output:
```hcl
{
  "current_version" = "v1.10.0"
  "sequence" = [
    "ctrl-00",
    "ctrl-01",
    "ctrl-02",
    "work-00",
    "work-01",
    "work-02",
  ]
  "total_nodes" = 6
}
```

## Emergency: Cancel In-Progress Upgrade

If you need to stop an upgrade in progress:

1. Press `Ctrl+C` to interrupt `tofu apply`
2. The current node will finish its upgrade
3. Subsequent nodes will not upgrade
4. Run `tofu apply` again when ready to resume

To roll back a completed node, you'll need to manually revert:

```shell
# Revert to previous version (manual process)
# 1. Change talos_image.version back to previous version
# 2. Run tofu apply to downgrade
```

## Troubleshooting

### Node Health Check Timeout

If a node health check times out:

```shell
# Check node status
kubectl get node <node-name>

# Check Talos services
talosctl services --nodes <node-ip>

# Check Talos logs
talosctl logs --nodes <node-ip>

# If node is healthy but check failed, run tofu apply again to retry
```

### Upgrade Stuck

If the upgrade appears stuck:

1. Check the OpenTofu output - it shows which node is currently upgrading
2. Verify that node is actually upgrading: `talosctl version --nodes <node-ip>`
3. Check health: `talosctl health --nodes <node-ip>`
4. If stuck for >10 minutes, press `Ctrl+C` and investigate

## Comparison: Old vs New Process

### Before (Manual)
```shell
# Multiple applies, manual health checks
vim tofu/talos_image.auto.tfvars  # Change version
tofu apply -var 'upgrade_control={enabled=true,index=0}'
# Manually check: kubectl get nodes, talosctl version
# Manually verify: Longhorn UI
tofu apply -var 'upgrade_control={enabled=true,index=1}'
# Repeat for each node...
tofu apply -var 'upgrade_control={enabled=false,index=-1}'
```

### After (Automated)
```shell
# One apply, automatic health checks
vim tofu/talos_image.auto.tfvars  # Change version
tofu apply  # Done! All nodes upgrade automatically
```

## Notes

- **GitOps Ready**: Commit version changes to git, let automation handle the rest
- **Safe**: Talos health checked after each node upgrade
- **Sequential**: Dependency chain ensures one-at-a-time upgrades
- **No Manual Steps**: Zero manual health verification or index changes needed
- **Control Plane First**: Control planes upgrade before workers to maintain quorum
- **Deterministic**: Always upgrades in the same order (alphabetical within node type)
>>>>>>> Stashed changes
