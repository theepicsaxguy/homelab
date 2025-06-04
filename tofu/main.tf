locals {
  # Default disk setup for worker nodes
  default_worker_disks = {
    longhorn = {
      device     = "/dev/sdb"
      size       = "180G"
      type       = "scsi"
      mountpoint = "/var/lib/longhorn"
    }
  }

  # Define base node configurations (without worker disk duplication)
  nodes_config_raw = {
    "ctrl-00" = {
      host_node     = "host3"
      machine_type  = "controlplane"
      ip            = "10.25.150.11"
      mac_address   = "bc:24:11:e6:ba:07"
      vm_id         = 8101
      cpu           = 6
      ram_dedicated = 7168
    }
    "ctrl-01" = {
      host_node     = "host3"
      machine_type  = "controlplane"
      ip            = "10.25.150.12"
      mac_address   = "bc:24:11:44:94:5c"
      vm_id         = 8102
      cpu           = 6
      ram_dedicated = 6144
    }
    "ctrl-02" = {
      host_node     = "host3"
      machine_type  = "controlplane"
      ip            = "10.25.150.13"
      mac_address   = "bc:24:11:1e:1d:2f"
      vm_id         = 8103
      cpu           = 6
      ram_dedicated = 6144
    }
    "work-00" = {
      host_node     = "host3"
      machine_type  = "worker"
      ip            = "10.25.150.21"
      mac_address   = "bc:24:11:64:5b:cb"
      vm_id         = 8201
      cpu           = 8
      ram_dedicated = 10240
      igpu          = false
    }
    "work-01" = {
      host_node     = "host3"
      machine_type  = "worker"
      ip            = "10.25.150.22"
      mac_address   = "bc:24:11:c9:22:c3"
      vm_id         = 8202
      cpu           = 8
      ram_dedicated = 10240
      igpu          = false
    }
    "work-02" = {
      host_node     = "host3"
      machine_type  = "worker"
      ip            = "10.25.150.23"
      mac_address   = "bc:24:11:6f:20:03"
      vm_id         = 8203
      cpu           = 8
      ram_dedicated = 10240
      igpu          = false
    }
  }

  # Add default worker disks and merge with any overrides
  # Values defined under nodes_config_raw.disks take precedence
  nodes_config = {
    for name, cfg in local.nodes_config_raw :
    name => merge(
      cfg,
      cfg.machine_type == "worker" ?
      { disks = merge(local.default_worker_disks, lookup(cfg, "disks", {})) } :
      {}
    )
  }

  # Mark a single node for upgrade when upgrade_control is enabled
  # This merges the computed nodes_config with an update flag
  nodes_with_upgrade = {
    for name, config in local.nodes_config :
    name => merge(config, {
      update = var.upgrade_control.enabled && name == local.current_upgrade_node
    })
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

  cluster = {
    name               = "talos"
    endpoint           = "api.kube.pc-tips.se"
    gateway            = "10.25.150.1"  # Network gateway
    vip                = "10.25.150.10" # Control plane VIP
    talos_version      = "v1.10.3"
    proxmox_cluster    = "kube"
    kubernetes_version = "1.33.1" # renovate: github-releases=kubernetes/kubernetes
  }

  nodes = local.nodes_with_upgrade
}

