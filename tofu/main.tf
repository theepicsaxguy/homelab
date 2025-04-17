module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  image = {
    version = "v1.9.5"
    update_version = "v1.9.5" # renovate: github-releases=siderolabs/talos
    schematic = file("${path.module}/talos/image/schematic.yaml")
  }

  cilium = {
    values = file("${path.module}/../k8s/infrastructure/network/cilium/values.yaml")
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
  }

  coredns = {
    install = file("${path.module}/talos/inline-manifests/coredns-install.yaml")
  }

  cluster = {
    name            = "talos"
    endpoint        = "api.kube.pc-tips.se"
    gateway         = "10.25.150.1"     # Network gateway
    vip             = "10.25.150.10"    # Control plane VIP
    talos_version   = "v1.9.5"
    proxmox_cluster = "kube"
    kubernetes_version = "1.32.3"  # renovate: github-releases=kubernetes/kubernetes
  }

  nodes = {
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
  }
  "work-00" = {
    host_node     = "host3"
    machine_type  = "worker"
    ip            = "10.25.150.21"
    mac_address   = "bc:24:11:64:5b:cb"
    vm_id         = 8201
    cpu           = 4
    ram_dedicated = 5120
    update        = false
    disks = {
      longhorn = {
        device = "/dev/sdb"
        size   = "100G"
        type   = "scsi"
      }
    }
  }
  "work-01" = {
    host_node     = "host3"
    machine_type  = "worker"
    ip            = "10.25.150.22"
    mac_address   = "bc:24:11:c9:22:c3"
    vm_id         = 8202
    cpu           = 4
    ram_dedicated = 5120
    update        = false
    disks = {
      longhorn = {
        device = "/dev/sdb"
        size   = "100G"
        type   = "scsi"
      }
    }
  }
  "work-02" = {
    host_node     = "host3"
    machine_type  = "worker"
    ip            = "10.25.150.23"
    mac_address   = "bc:24:11:6f:20:03"
    vm_id         = 8203
    cpu           = 4
    ram_dedicated = 5120
    update        = false
    disks = {
      longhorn = {
        device = "/dev/sdb"
        size   = "100G"
        type   = "scsi"
      }
    }
  }
}
}

