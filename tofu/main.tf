locals {
  node_defaults = {
    controlplane = var.defaults_controlplane
    worker       = var.defaults_worker
  }

  # Primary cluster nodes (backward compatible)
  nodes_with_upgrade = {
    for name, config in var.nodes_config : name => merge(
      try(local.node_defaults[config.machine_type], error("machine_type '${config.machine_type}' has no defaults")),
      { for k, v in config : k => v if v != null },
      {
        disks = {
          for disk_name, disk_defaults in try(local.node_defaults[config.machine_type].disks, {}) :
          disk_name => merge(
            disk_defaults,
            coalesce(lookup(coalesce(config.disks, {}), disk_name, null), {})
          )
        }
      },
      {
        host_node    = coalesce(config.host_node, nonsensitive(var.proxmox.name))
        update       = var.upgrade_control.enabled && name == local.current_upgrade_node
        datastore_id = coalesce(lookup(config, "datastore_id", null), var.proxmox_datastore)
      }
    )
  }

  # Optional second cluster nodes; count-guarded module below
  nodes_with_upgrade_extra = {
    for name, config in var.nodes_config_extra : name => merge(
      try(local.node_defaults[config.machine_type], error("machine_type '${config.machine_type}' has no defaults")),
      { for k, v in config : k => v if v != null },
      {
        disks = {
          for disk_name, disk_defaults in try(local.node_defaults[config.machine_type].disks, {}) :
          disk_name => merge(
            disk_defaults,
            coalesce(lookup(coalesce(config.disks, {}), disk_name, null), {})
          )
        }
      },
      {
        host_node    = coalesce(config.host_node, nonsensitive(var.proxmox.name))
        update       = false
        datastore_id = coalesce(lookup(config, "datastore_id", null), var.proxmox_datastore)
      }
    )
  }
}

module "talos" {
  source = "./talos"

  proxmox_datastore = var.proxmox_datastore
  talos_image       = var.talos_image
  cluster_domain    = var.cluster_domain

  cilium = {
    values  = file("${path.module}/../k8s/infrastructure/network/cilium/values.yaml")
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
  }

  coredns = {
    install = templatefile("${path.module}/talos/inline-manifests/coredns-install.yaml.tftpl", {
      cluster_domain = var.cluster_domain
      dns_forwarders = join(" ", var.network.dns_servers)
    })
  }

  cluster = {
    name               = var.cluster_name
    endpoint           = "api.${var.cluster_domain}"
    talos_version      = var.versions.talos
    proxmox_cluster    = var.proxmox_cluster
    kubernetes_version = var.versions.kubernetes
  }

  network = var.network
  oidc    = var.oidc
  nodes   = local.nodes_with_upgrade
}

# Optional second cluster (only if nodes_config_extra is non-empty)
module "talos_extra" {
  count  = length(var.nodes_config_extra) > 0 ? 1 : 0
  source = "./talos"

  proxmox_datastore = var.proxmox_datastore
  talos_image       = var.talos_image
  cluster_domain    = var.cluster_domain_extra

  cilium = {
    values  = file("${path.module}/../k9s/../k8s/infrastructure/network/cilium/values.yaml")
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
  }

  coredns = {
    install = templatefile("${path.module}/talos/inline-manifests/coredns-install.yaml.tftpl", {
      cluster_domain = var.cluster_domain_extra
      dns_forwarders = join(" ", var.network.dns_servers)
    })
  }

  cluster = {
    name               = var.cluster_name_extra
    endpoint           = "api.${var.cluster_domain_extra}"
    talos_version      = var.versions.talos
    proxmox_cluster    = var.proxmox_cluster
    kubernetes_version = var.versions.kubernetes
  }

  network = var.network
  oidc    = var.oidc
  nodes   = local.nodes_with_upgrade_extra
}
