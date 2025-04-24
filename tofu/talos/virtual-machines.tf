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
          interface    = disk_val.type == "scsi" ? "scsi${index(keys(lookup(each.value, "disks", {})), k) + 1}" : "virtio${index(keys(lookup(each.value, "disks", {})), k) + 1}"
          iothread     = true
          # Add other relevant attributes for node-specific disks if needed (e.g., cache, ssd)
          cache   = "writethrough" # Example
          discard = "on"           # Example
          ssd     = true           # Example
        }
      },
      # Attach the dedicated Longhorn disk file for this worker node using file_id
      each.value.machine_type == "worker" ? {
        "longhorn_dedicated" = {
          datastore_id = var.storage_pool # Disk is in the same pool
          # Reference the file_id from the corresponding longhorn_data VM's disk[0]
          file_id = proxmox_virtual_environment_vm.longhorn_data[each.key].disk[0].file_id
          # Ensure interface index doesn't clash, start after node disks
          interface = "scsi${length(lookup(each.value, "disks", {})) + 1}"
          iothread  = true
          # No size needed when using file_id
          # No shared needed, as file_id implies attaching an existing disk exclusively (by default)
          # Add other relevant attributes if needed, matching the source disk if possible
          cache   = "writethrough" # Match source disk attributes if necessary
          discard = "on"           # Match source disk attributes if necessary
          ssd     = true           # Match source disk attributes if necessary
        }
      } : {}
    )

    content {
      datastore_id = disk.value.datastore_id
      size         = lookup(disk.value, "size", null)    # Only present for node disks created by size
      file_id      = lookup(disk.value, "file_id", null) # Only present for Longhorn disk attached by file_id
      interface    = disk.value.interface
      iothread     = disk.value.iothread
      # Pass other attributes defined in the for_each maps
      cache   = lookup(disk.value, "cache", null)
      discard = lookup(disk.value, "discard", null)
      ssd     = lookup(disk.value, "ssd", null)
      # Removed path_in_datastore and shared as they are not used/applicable here
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
