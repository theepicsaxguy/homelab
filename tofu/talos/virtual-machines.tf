moved {
  from = proxmox_virtual_environment_vm.this
  to   = proxmox_virtual_environment_vm.k8s_node
}

resource "proxmox_virtual_environment_vm" "k8s_node" {
  for_each = var.nodes

  node_name = each.value.host_node

  name        = each.key
  description = each.value.machine_type == "controlplane" ? "Talos Control Plane" : "Talos Worker"
  tags        = each.value.machine_type == "controlplane" ? ["k8s", "control-plane"] : ["k8s", "worker"]
  on_boot     = true
  vm_id       = each.value.vm_id

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "seabios"

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cpu
    type  = "host"
  }

  memory {
    dedicated = each.value.ram_dedicated
  }

  network_device {
    bridge      = "vmbr0"
    vlan_id     = 150
    mac_address = each.value.mac_address
  }

  # Boot disk (assuming scsi0 is the boot disk, adjust if different)
  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    size         = 50 # Example boot disk size, adjust as needed
    iothread     = true
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    file_format  = "raw"
    file_id      = each.value.update == true ? proxmox_virtual_environment_download_file.update[0].id : proxmox_virtual_environment_download_file.this.id
  }

  # Combined dynamic block for additional data disks (original node disks + Longhorn)
  dynamic "disk" {
    # Combine original disks and Longhorn disks into a single map
    for_each = merge(
      # Original disks defined in var.nodes, starting interface index at 1
      { for k, disk_val in lookup(each.value, "disks", {}) :
        "node_${k}" => {
          datastore_id = var.storage_pool
          size         = tonumber(replace(disk_val.size, "G", ""))
          # Start index at 1 (scsi1/virtio1)
          interface = disk_val.type == "scsi" ? "scsi${index(keys(lookup(each.value, "disks", {})), k) + 1}" : "virtio${index(keys(lookup(each.value, "disks", {})), k) + 1}"
          iothread  = true
        }
      },
      # Longhorn disks for worker nodes, converting list to map and starting index after node disks
      each.value.machine_type == "worker" ? {
        for idx, lh_disk in var.longhorn_disks :
        "longhorn_${idx}" => {
          datastore_id      = lh_disk.datastore_id
          path_in_datastore = lh_disk.path_in_datastore
          # Ensure interface index doesn't clash with node disks, start after them
          interface = "scsi${length(lookup(each.value, "disks", {})) + idx + 1}"
          iothread  = true
        }
      } : {}
    )

    content {
      datastore_id      = disk.value.datastore_id
      size              = lookup(disk.value, "size", null)              # Only present for node disks
      path_in_datastore = lookup(disk.value, "path_in_datastore", null) # Only present for Longhorn disks
      interface         = disk.value.interface
      iothread          = disk.value.iothread
    }
  }

  boot_order = ["scsi0"]

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 6.X.
  }

  initialization {
    datastore_id = each.value.datastore_id
    dns {
      domain  = "kube.pc-tips.se"
      servers = ["10.25.150.1"]
    }
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.cluster.gateway
      }
    }
  }

  #################################################################
  # OPTIONAL GPU passthrough—only when igpu == true for the node #
  #################################################################
  dynamic "hostpci" {
    for_each = lookup(each.value, "igpu", false) ? [1] : []
    content {
      device  = "hostpci0"
      mapping = lookup(each.value, "gpu_id", "iGPU") # default mapping name
      pcie    = true
      rombar  = true
      xvga    = false
    }
  }
}
