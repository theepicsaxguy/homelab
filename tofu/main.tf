locals {
  # Common configuration for worker nodes
  defaults_worker = {
    host_node     = "host3"
    machine_type  = "worker"
    cpu           = 8
    ram_dedicated = 10240
    igpu          = false
    disks = {
      longhorn = {
        device     = "/dev/sdb"
        size       = "180G"
        type       = "scsi"
        mountpoint = "/var/lib/longhorn"
      }
    }
  }

  # Common configuration for control plane nodes
  defaults_controlplane = {
    host_node     = "host3"
    machine_type  = "controlplane"
    cpu           = 6
    ram_dedicated = 6144
  }

  node_defaults = {
    worker       = local.defaults_worker
    controlplane = local.defaults_controlplane
  }

  # Define per-node settings
  nodes_config = {
    "ctrl-00" = {
      machine_type  = "controlplane"
      ip            = "10.25.150.11"
      mac_address   = "bc:24:11:e6:ba:07"
      vm_id         = 8101
      ram_dedicated = 7168
    }
    "ctrl-01" = {
      machine_type = "controlplane"
      ip           = "10.25.150.12"
      mac_address  = "bc:24:11:44:94:5c"
      vm_id        = 8102
    }
    "ctrl-02" = {
      machine_type = "controlplane"
      ip           = "10.25.150.13"
      mac_address  = "bc:24:11:1e:1d:2f"
      vm_id        = 8103
    }
    "work-00" = {
      machine_type = "worker"
      ip           = "10.25.150.21"
      mac_address  = "bc:24:11:64:5b:cb"
      vm_id        = 8201
    }
    "work-01" = {
      machine_type = "worker"
      ip           = "10.25.150.22"
      mac_address  = "bc:24:11:c9:22:c3"
      vm_id        = 8202
    }
    "work-02" = {
      machine_type = "worker"
      ip           = "10.25.150.23"
      mac_address  = "bc:24:11:6f:20:03"
      vm_id        = 8203
    }
  }

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

  # Prepare nodes configuration with upgrade flags
  nodes_with_upgrade = {
    for name, config in local.nodes_config :
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

  cluster = {
    name               = "talos"
    endpoint           = "api.kube.pc-tips.se"
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
      ip       = try(local.nodes_config[local.current_upgrade_node].ip, null)
    } : null
  }
  description = "Structured upgrade state information for external automation and monitoring"
}
