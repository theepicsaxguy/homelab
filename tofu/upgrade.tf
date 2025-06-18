locals {
  # Derive upgrade sequence from machine types
  control_plane_nodes = [
    for name, config in var.nodes_config : name
    if config.machine_type == "controlplane"
  ]
  worker_nodes = [
    for name, config in var.nodes_config : name
    if config.machine_type == "worker"
  ]

  # Derive upgrade sequence automatically
  upgrade_sequence = concat(sort(local.control_plane_nodes), sort(local.worker_nodes))

  # Calculate current upgrade node
  current_upgrade_node = (
    var.upgrade_control.enabled &&
    var.upgrade_control.index >= 0 &&
    var.upgrade_control.index < length(local.upgrade_sequence)
  ) ? local.upgrade_sequence[var.upgrade_control.index] : ""
}

output "upgrade_info" {
  value = {
    state = {
      enabled     = var.upgrade_control.enabled
      index       = var.upgrade_control.index
      total_nodes = length(local.upgrade_sequence)
      sequence    = local.upgrade_sequence
    }
    current = var.upgrade_control.enabled ? {
      node     = local.current_upgrade_node
      progress = "${var.upgrade_control.index + 1}/${length(local.upgrade_sequence)}"
      valid    = local.current_upgrade_node != ""
      ip       = try(var.nodes_config[local.current_upgrade_node].ip, null)
    } : null
  }
  description = "Structured upgrade state information for external automation and monitoring"
}
