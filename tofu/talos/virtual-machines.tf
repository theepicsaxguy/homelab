resource "proxmox_virtual_environment_vm" "this" {
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

  disk {
    datastore_id = each.value.datastore_id
    interface    = "scsi0"
    iothread     = true
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    file_format  = "raw"
    size         = 40
    file_id = proxmox_virtual_environment_download_file.this[
      "${each.key}_${each.value.update == true ? "update" : "base"}"
    ].id
  }

  # Create additional disks defined in the node configuration
  dynamic "disk" {
    for_each = each.value.disks
    content {
      datastore_id = each.value.datastore_id
      interface    = "${disk.value.type}${disk.value.unit_number}"
      iothread     = true
      cache        = "writethrough"
      discard      = "on"
      ssd          = true
      file_format  = "raw"
      size         = tonumber(replace(disk.value.size, "G", ""))
    }
  }
  lifecycle {
    ignore_changes = [
      vga,                            # Ignore VGA changes (these are computed)
      network_device[0].disconnected, # Ignore network disconnected state
      # Add any other attributes causing issues
    ]
  }
  boot_order = ["scsi0"]

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 6.X.
  }

  initialization {
    datastore_id = each.value.datastore_id
    dns {
      domain  = var.cluster_domain
      servers = ["10.25.150.1"]
    }
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.cluster.gateway
      }
    }
  }

  dynamic "hostpci" {
    for_each = each.value.igpu ? [1] : []
    content {
      # Passthrough iGPU
      device  = "hostpci0"
      mapping = "iGPU"
      pcie    = true
      rombar  = true
      xvga    = false
    }
  }
}
