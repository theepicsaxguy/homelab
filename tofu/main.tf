locals {
  node_defaults = {
    worker       = var.defaults_worker
    controlplane = var.defaults_controlplane
  }

  nodes_with_upgrade = {
    for name, config in var.nodes_config : name => merge(
      try(
        local.node_defaults[config.machine_type],
        error("machine_type '${config.machine_type}' has no defaults")
      ),
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
}
module "talos" {
  source = "./talos"

  providers = {
    proxmox           = proxmox
    proxmox.secondary = proxmox.secondary
  }

  proxmox_datastore = var.proxmox_datastore
  proxmox_secondary = var.proxmox_secondary

  talos_image = var.talos_image

  cilium = {
    values  = file("${path.module}/../k8s/infrastructure/network/cilium/values.yaml")
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
  }

  coredns = {
    # CHANGE: Convert the coredns manifest to a template
    install = templatefile("${path.module}/talos/inline-manifests/coredns-install.yaml.tftpl", {
      cluster_domain = var.cluster_domain
      dns_forwarders = join(" ", var.network.dns_servers)
    })
  }

  cluster_domain = var.cluster_domain

  # CHANGE: Replace the hardcoded cluster block with variables
  cluster = {
    name               = var.cluster_name
    endpoint           = "api.${var.cluster_domain}"
    gateway            = var.network.gateway
    vip                = var.network.vip
    talos_version      = var.versions.talos
    proxmox_cluster    = var.proxmox_cluster
    kubernetes_version = var.versions.kubernetes
  }

  # Pass network config to the module
  network = var.network

  # Pass OIDC config to the module
  oidc = var.oidc

  nodes = local.nodes_with_upgrade
}
