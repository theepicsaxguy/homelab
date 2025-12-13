# Sequential Node Upgrade Mechanism - Declarative OpenTofu
#
# Uses two versions: talos_image.version (current) and talos_image.update_version (target).
# Nodes with upgrade = true get the update_version, others stay at version.
#
# Upgrade workflow:
# 1. Renovate updates talos_image.update_version to "v1.11.5"
# 2. Set upgrade = true on ctrl-00 in nodes_config
# 3. Run tofu apply -> only ctrl-00 upgrades
# 4. Set upgrade = true on ctrl-01
# 5. Run tofu apply -> only ctrl-01 upgrades
# 6. Continue for all nodes
# 7. Finally, set talos_image.version = update_version and set all upgrade = false
#
# For bulk upgrades, set upgrade = true on all nodes at once.

locals {
  # Build upgrade sequence: control planes first, then workers (sorted alphabetically)
  upgrade_sequence = concat(
    sort([for name, config in var.nodes : name if config.machine_type == "controlplane"]),
    sort([for name, config in var.nodes : name if config.machine_type == "worker"])
  )

  # Note: target_version and node_effective_versions are defined in image.tf
  # to avoid duplication. They're used here via local.target_version and
  # local.node_effective_versions.

  # Nodes marked for upgrade
  nodes_marked_for_upgrade = [
    for name, config in var.nodes : name if coalesce(config.upgrade, false)
  ]

  # Nodes that will actually change (marked AND versions differ)
  nodes_pending_upgrade = [
    for name in local.nodes_marked_for_upgrade : name
    if local.target_version != var.talos_image.version
  ]
}

# Per-node upgrade trigger - fires when the node's effective version changes
resource "terraform_data" "node_upgrade_trigger" {
  for_each = var.nodes

  triggers_replace = {
    effective_version = local.node_effective_versions[each.key]
    node_name         = each.key
  }
}

# Output upgrade information
output "upgrade_sequence" {
  value = {
    recommended_order        = local.upgrade_sequence
    total_nodes              = length(local.upgrade_sequence)
    current_version          = var.talos_image.version
    target_version           = local.target_version
    nodes_marked_for_upgrade = local.nodes_marked_for_upgrade
    pending_upgrades         = local.nodes_pending_upgrade
    node_versions            = local.node_effective_versions
  }
  description = "Upgrade status and recommended order for sequential upgrades"
}
