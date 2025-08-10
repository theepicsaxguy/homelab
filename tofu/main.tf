locals {
  node_defaults = {
    worker       = var.defaults_worker
    controlplane = var.defaults_controlplane
  }

  nodes_with_upgrade = {
    for name, config in var.nodes_config : name => merge(
      try(local.node_defaults[config.machine_type], error("machine_type '${config.machine_type}' has no defaults")),
      { for k, v in config : k => v if v != null },
      {
        disks = {
          for disk_name, disk_defaults in try(local.node_defaults[config.machine_type].disks, {}) :
          disk_name => merge(disk_defaults, coalesce(lookup(coalesce(config.disks, {}), disk_name, null), {}))
        }
      },
      {
        # Fallback only when a single-cluster object is supplied; with a map, host_node must be provided.
        host_node    = coalesce(config.host_node, try(nonsensitive(var.proxmox.name), null))
        update       = var.upgrade_control.enabled && name == local.current_upgrade_node
        datastore_id = coalesce(lookup(config, "datastore_id", null), var.proxmox_datastore)
      }
    )
  }

  # Partition dynamically by cluster key. (Provider alias names themselves are static)
  nodes_by_cluster = {
    for k in(can(var.proxmox.endpoint) ? [] : keys(var.proxmox)) :
    k => { for n, v in local.nodes_with_upgrade : n => v if v.host_node == k && !lookup(v, "is_external", false) }
  }
}

# Cluster-owner (host3). Manages bootstrap, kubeconfig, etc.
module "talos_owner" {
  source    = "./talos"
  providers = { proxmox = proxmox.host3 }

  manage_cluster    = true
  proxmox_datastore = var.proxmox_datastore

  talos_image    = var.talos_image
  cluster_domain = var.cluster_domain

  cluster = {
    name               = var.cluster_name
    endpoint           = "api.${var.cluster_domain}"
    talos_version      = var.versions.talos
    proxmox_cluster    = var.proxmox_cluster
    kubernetes_version = var.versions.kubernetes
  }

  network = var.network
  oidc    = var.oidc

  # Keep Proxmox actions scoped to host3 only
  nodes = try(local.nodes_by_cluster["host3"], {})
}

# Worker(s) on nuc. No cluster-wide actions here.
module "talos_nuc" {
  count     = contains(keys(local.nodes_by_cluster), "nuc") ? 1 : 0
  source    = "./talos"
  providers = { proxmox = proxmox.nuc }

  manage_cluster    = false
  proxmox_datastore = var.proxmox_datastore

  talos_image    = var.talos_image
  cluster_domain = var.cluster_domain

  cluster = {
    name               = var.cluster_name
    endpoint           = "api.${var.cluster_domain}"
    talos_version      = var.versions.talos
    proxmox_cluster    = var.proxmox_cluster
    kubernetes_version = var.versions.kubernetes
  }

  network = var.network
  oidc    = var.oidc

  # Proxmox resources here act only on nuc’s nodes
  nodes = local.nodes_by_cluster["nuc"]
}
