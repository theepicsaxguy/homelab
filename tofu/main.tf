locals {
  node_defaults = {
    worker       = var.defaults_worker
    controlplane = var.defaults_controlplane
  }


  # Prepare nodes configuration with upgrade flags
  nodes_with_upgrade = {
    for name, config in var.nodes_config :
    name => merge(
      try(
        local.node_defaults[config.machine_type],
        error("machine_type '${config.machine_type}' has no defaults")
      ),
      { for k, v in config : k => v if v != null },
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

