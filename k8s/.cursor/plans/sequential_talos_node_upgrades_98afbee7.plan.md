---
name: Sequential Talos Node Upgrades
overview: Fix the incomplete upgrade-nodes.tf to implement automatic sequential node upgrades with proper health checks, eliminating the need for manual talosctl upgrade commands.
todos:
  - id: replace-upgrade-nodes
    content: Replace upgrade-nodes.tf with declarative terraform_data + talos_cluster_health resources (no scripts)
    status: completed
  - id: update-vm-triggers
    content: Update virtual-machines.tf replace_triggered_by to reference per-node terraform_data triggers
    status: completed
  - id: remove-health-file
    content: Remove or simplify upgrade-health.tf as per-node health checks replace it
    status: completed
  - id: update-docs
    content: Update upgrade-talos.md documentation to reflect declarative sequential upgrades
    status: completed
---

# Sequential Talos Node Upgrade - Declarative OpenTofu

## Current State

The current implementation has issues:

- `tofu/talos/virtual-machines.tf`: All VMs replace simultaneously via `replace_triggered_by = [terraform_data.image_version]`
- `tofu/talos/upgrade-nodes.tf`: Attempts sequential upgrades with incomplete shell scripts in `local-exec` provisioners
- `tofu/upgrade-health.tf`: Single cluster-wide health check after simultaneous upgrades

## Target State - Pure Declarative OpenTofu

Sequential VM replacement using only OpenTofu resources and dependencies - no scripts, no `local-exec` provisioners.

## Implementation Approach

### Key Pattern: Per-Node Health Checks + Dependency Chain

Use `talos_cluster_health` data sources to check individual nodes (by passing only that node's IP), combined with `terraform_data` resources that form a dependency chain.

### 1. Create Per-Node Health Check Data Sources

In `tofu/talos/upgrade-nodes.tf`:

```hcl
# Per-node health check - verifies this specific node is healthy
data "talos_cluster_health" "node" {
  for_each = var.nodes

  depends_on = [
    proxmox_virtual_environment_vm.this,
    talos_machine_configuration_apply.this
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  
  # Check only this specific node
  control_plane_nodes = each.value.machine_type == "controlplane" ? [each.value.ip] : []
  worker_nodes        = each.value.machine_type == "worker" ? [each.value.ip] : []
  
  # Use all control plane nodes as endpoints
  endpoints = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]

  timeouts = {
    read = "10m"
  }
}
```

### 2. Create Sequential terraform_data Triggers

Create individual (non-for_each) `terraform_data` resources for each node position in the upgrade sequence:

```hcl
locals {
  upgrade_sequence = concat(
    sort([for name, cfg in var.nodes : name if cfg.machine_type == "controlplane"]),
    sort([for name, cfg in var.nodes : name if cfg.machine_type == "worker"])
  )
}

# First node - depends only on image version change
resource "terraform_data" "upgrade_node_0" {
  triggers_replace = {
    version   = var.talos_image.version
    node_name = local.upgrade_sequence[0]
  }
}

# Second node - depends on first node's health check
resource "terraform_data" "upgrade_node_1" {
  triggers_replace = {
    version   = var.talos_image.version
    node_name = local.upgrade_sequence[1]
  }
  
  depends_on = [data.talos_cluster_health.node[local.upgrade_sequence[0]]]
}

# ... continue for each node position
```

### 3. Update VM replace_triggered_by

In `tofu/talos/virtual-machines.tf`, change:

```hcl
# FROM:
lifecycle {
  replace_triggered_by = [terraform_data.image_version]
}

# TO:
lifecycle {
  replace_triggered_by = [
    terraform_data.upgrade_node_0,  # For first node
    # or terraform_data.upgrade_node_1 for second, etc.
  ]
}
```

### 4. Use Dynamic Node Count with Count Meta-Argument

To avoid hardcoding node count, use a module or count-based approach:

```hcl
resource "terraform_data" "node_upgrade" {
  count = length(local.upgrade_sequence)

  triggers_replace = {
    version   = var.talos_image.version
    node_name = local.upgrade_sequence[count.index]
  }

  # First node has no dependency, others depend on previous health
  depends_on = count.index == 0 ? [] : [
    data.talos_cluster_health.node[local.upgrade_sequence[count.index - 1]]
  ]
}
```

Note: This requires Terraform 1.8+ for `depends_on` with dynamic references.

## Files to Modify

1. **`tofu/talos/upgrade-nodes.tf`** - Replace with declarative resources:

   - Remove all `local-exec` provisioners
   - Add `data "talos_cluster_health" "node"` for per-node health checks
   - Add `terraform_data` resources with sequential dependencies

2. **`tofu/talos/virtual-machines.tf`** - Update `replace_triggered_by`:

   - Reference per-node `terraform_data` triggers instead of global `image_version`

3. **`tofu/upgrade-health.tf`** - Remove or simplify:

   - The per-node health checks in `upgrade-nodes.tf` replace this file's purpose

4. **`website/docs/tofu/upgrade-talos.md`** - Update documentation

## Dependency Flow

```
var.talos_image.version changes
    ↓
terraform_data.node_upgrade[0] triggers
    ↓
proxmox_virtual_environment_vm.this["ctrl-00"] replaces
    ↓
talos_machine_configuration_apply.this["ctrl-00"] applies
    ↓
data.talos_cluster_health.node["ctrl-00"] waits until healthy
    ↓
terraform_data.node_upgrade[1] triggers
    ↓
proxmox_virtual_environment_vm.this["ctrl-01"] replaces
    ↓
... continues sequentially
```

## OpenTofu Version Requirement

This approach may require OpenTofu 1.8+ for dynamic `depends_on` in count-based resources. Verify compatibility.