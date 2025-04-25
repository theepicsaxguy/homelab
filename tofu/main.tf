#####################################
# Static defaults kept in this file
#####################################

locals {
  # ---- cluster-wide constants (edit to taste) ----
  cluster_defaults = {
    name               = "talos"
    endpoint           = "api.kube.pc-tips.se"
    gateway            = "10.25.150.1"
    vip                = "10.25.150.10"
    domain             = "kube.pc-tips.se"
    bridge             = "vmbr0"
    vlan_id            = 150
    talos_version      = "v1.9.5"
    proxmox_cluster    = "kube"
    kubernetes_version = "1.33.0"
  }

  # ---- Talos image to use ----
  image_defaults = {
    version        = "v1.9.5"
    update_version = "v1.9.5"
    schematic      = file("${path.module}/talos/image/schematic.yaml")
  }

  # ---- packaged inline manifests ----
  cilium_defaults = {
    values  = file("${path.module}/../k8s/infrastructure/network/cilium/values.yaml")
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
  }

  coredns_defaults = {
    install = file("${path.module}/talos/inline-manifests/coredns-install.yaml")
  }

  # baked‐in node map (only used if you don't pass -var nodes)
  nodes_defaults = {
    "ctrl-00" = {
      host_node     = "host3"
      machine_type  = "controlplane"
      ip            = "10.25.150.11"
      mac_address   = "bc:24:11:e6:ba:07"
      vm_id         = 8101
      cpu           = 6
      ram_dedicated = 6150
      update        = false
      igpu          = false
    }
    "ctrl-01" = {
      host_node     = "host3"
      machine_type  = "controlplane"
      ip            = "10.25.150.12"
      mac_address   = "bc:24:11:44:94:5c"
      vm_id         = 8102
      cpu           = 6
      ram_dedicated = 6150
      update        = false
      igpu          = false
    }
    "ctrl-02" = {
      host_node     = "host3"
      machine_type  = "controlplane"
      ip            = "10.25.150.13"
      mac_address   = "bc:24:11:1e:1d:2f"
      vm_id         = 8103
      cpu           = 4
      ram_dedicated = 6150
      update        = false
      igpu          = false
    }
    "work-00" = {
      host_node     = "host3"
      machine_type  = "worker"
      ip            = "10.25.150.21"
      mac_address   = "bc:24:11:64:5b:cb"
      vm_id         = 8201
      cpu           = 8
      ram_dedicated = 6120
      update        = false
      disks = {
        longhorn = {
          device     = "/dev/sdb"
          size       = "150G"
          type       = "scsi"
          mountpoint = "/var/lib/longhorn"
        }
      }
    }
    "work-01" = {
      host_node     = "host3"
      machine_type  = "worker"
      ip            = "10.25.150.22"
      mac_address   = "bc:24:11:c9:22:c3"
      vm_id         = 8202
      cpu           = 8
      ram_dedicated = 6120
      update        = false
      disks = {
        longhorn = {
          device     = "/dev/sdb"
          size       = "150G"
          type       = "scsi"
          mountpoint = "/var/lib/longhorn"
        }
      }
    }
    "work-02" = {
      host_node     = "host3"
      machine_type  = "worker"
      ip            = "10.25.150.23"
      mac_address   = "bc:24:11:6f:20:03"
      vm_id         = 8203
      cpu           = 8
      ram_dedicated = 5120
      update        = false
      disks = {
        longhorn = {
          device     = "/dev/sdb"
          size       = "150G"
          type       = "scsi"
          mountpoint = "/var/lib/longhorn"
        }
      }
    }
  }

  effective_cluster = merge(local.cluster_defaults, var.cluster != null ? var.cluster : {})
}

#####################################
# Talos module invocation
#####################################

module "talos" {
  source = "./talos"

  storage_pool = var.storage_pool

  cluster = local.effective_cluster
  image   = coalesce(var.image, local.image_defaults)
  cilium  = coalesce(var.cilium, local.cilium_defaults)
  coredns = coalesce(var.coredns, local.coredns_defaults)
  nodes   = coalesce(var.nodes, local.nodes_defaults)

  longhorn_disk_files = local.longhorn_disk_files
  worker_disk_specs   = local.worker_disk_specs
  os_disk_file_id     = local.os_disk_file_id
}
