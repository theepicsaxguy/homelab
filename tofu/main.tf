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
        datastore_id = coalesce(lookup(config, "datastore_id", null), var.proxmox_datastore)
      }
    )
  }
}
module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  proxmox_datastore = var.proxmox_datastore

  talos_image = var.talos_image
  versions    = var.versions

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

  external_api_endpoint = var.external_api_endpoint

  cluster = {
    name               = var.cluster_name
    endpoint           = coalesce(var.external_api_endpoint, "api.${var.cluster_domain}")
    gateway            = var.network.gateway
    vip                = var.network.vip
    talos_version      = var.versions.talos
    proxmox_cluster    = var.proxmox_cluster
    kubernetes_version = var.versions.kubernetes
  }

  network = var.network

  # Pass OIDC config to the module
  oidc = var.oidc

  nodes = local.nodes_with_upgrade
}

module "lb" {
  count  = var.enable_lb ? 1 : 0
  source = "./lb"
  providers = {
    proxmox = proxmox
  }
  proxmox           = var.proxmox
  cluster_domain    = var.cluster_domain
  auth_pass         = var.auth_pass
  proxmox_datastore = var.lb_store
  network           = var.network
  control_plane_ips = [for name, n in var.nodes_config : n.ip if n.machine_type == "controlplane"]
  lb_nodes          = var.lb_nodes
}

module "bootstrap_kubernetes" {
  source = "./bootstrap/kubernetes"

  cert_manager_version     = var.bootstrap_cert_manager_version
  external_secrets_version = var.bootstrap_external_secrets_version
  argocd_version           = var.bootstrap_argocd_version

  bitwarden_token    = var.bitwarden_token
  git_repository_url = var.git_repository_url
}
