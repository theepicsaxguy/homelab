# Upgrade sequencing and state management

locals {
  # Derive upgrade sequence from machine types
  control_plane_nodes = [
    for name, config in local.nodes_config : name
    if config.machine_type == "controlplane"
  ]
  worker_nodes = [
    for name, config in local.nodes_config : name
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

  # Mark node being upgraded so module.talos knows which VM to update
  nodes_with_upgrade = {
    for name, config in local.nodes_config :
    name => merge(config, {
      update = var.upgrade_control.enabled && name == local.current_upgrade_node
    })
  }
}

# Health verification after apply
# Runs after module.talos to ensure cluster is healthy post-upgrade

data "talos_cluster_health" "upgrade" {
  depends_on           = [module.talos]
  client_configuration = module.talos.client_configuration.client_configuration
  control_plane_nodes  = [for name, cfg in local.nodes_config : cfg.ip if cfg.machine_type == "controlplane"]
  worker_nodes         = [for name, cfg in local.nodes_config : cfg.ip if cfg.machine_type == "worker"]
  endpoints            = module.talos.client_configuration.endpoints
  timeouts = {
    read = "3m"
  }
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
      ip       = try(local.nodes_config[local.current_upgrade_node].ip, null)
    } : null
    health = data.talos_cluster_health.upgrade
  }
  description = "Structured upgrade state information for external automation and monitoring"
  sensitive   = true
}
