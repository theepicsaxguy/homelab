locals {
  node_defaults = {
    worker       = var.defaults_worker
    controlplane = var.defaults_controlplane
  }


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

  # Prepare nodes configuration with upgrade flags
  nodes_with_upgrade = {
    for name, config in var.nodes_config :
    name => merge(
      try(
        local.node_defaults[config.machine_type],
        error("machine_type '${config.machine_type}' has no defaults")
      ),
      config,
      {
        update = var.upgrade_control.enabled && name == local.current_upgrade_node
      }
    )
  }
}

module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  talos_image = var.talos_image

  cilium = {
    values  = file("${path.module}/../k8s/infrastructure/network/cilium/values.yaml")
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
  }

  coredns = {
    install = file("${path.module}/talos/inline-manifests/coredns-install.yaml")
  }

  cluster_domain = local.cluster_domain

  cluster = {
    name               = "talos"
    endpoint           = "api.${local.cluster_domain}"
    gateway            = "10.25.150.1"  # Network gateway
    vip                = "10.25.150.10" # Control plane VIP
    talos_version      = "v1.10.3"
    proxmox_cluster    = "kube"
    kubernetes_version = "1.33.2" # renovate: github-releases=kubernetes/kubernetes
  }

  nodes = local.nodes_with_upgrade
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
