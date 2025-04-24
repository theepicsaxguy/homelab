resource "proxmox_virtual_environment_vm" "this" {
  for_each = var.nodes

  node_name = each.value.host_node
  name      = each.key
  vm_id     = each.value.vm_id
  on_boot   = true
  started   = true
  template  = false

  agent {
    enabled = true
    fs_trim = true
  }

  network_device {
    bridge      = "vmbr0"
    firewall    = false
    mac_address = each.value.mac_address
  }

  // Boot disk (assuming scsi0 is the boot disk, adjust if different)
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

  // Attach Longhorn disks from data_disks VM
  dynamic "disk" {
    for_each = {
      for idx, d in proxmox_virtual_environment_vm.data_disks.disk :
      idx => d if idx > 0  // skip scsi0
    }
    content {
      datastore_id = proxmox_virtual_environment_vm.data_disks.disk[0].datastore_id
      file_id      = proxmox_virtual_environment_vm.data_disks.disk[disk.key].file_id
      interface    = "scsi${disk.key}"       // aligns: data_disks scsi1 → worker scsi1
      iothread     = true
      cache        = "writethrough"
      discard      = "on"
      ssd          = true
    }
  }

  cpu {
    architecture = "x86_64"
    cores        = each.value.cpu
    sockets      = 1
    type         = "host"
  }

  memory {
    dedicated = each.value.ram_dedicated
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 6.x
  }

  serial_device {}

  vga {
    memory = 64
    type   = "qxl"
  }

  #################################################################
  # OPTIONAL GPU passthrough—only when igpu == true for the node #
  #################################################################
  dynamic "hostpci" {
    # Correctly reference the outer 'each' for the node
    for_each = lookup(each.value, "igpu", false) ? [1] : []
    content {
      device = "hostpci0"
      # Correctly reference the outer 'each' for the node
      mapping = lookup(each.value, "gpu_id", "iGPU")
      pcie    = true
      rombar  = true
      xvga    = false
    }
  }

  lifecycle {
    ignore_changes = [
      network_device,
      disk[0].file_id, # Ignore changes to the boot disk file_id after creation
    ]
  }

  depends_on = [
    proxmox_virtual_environment_download_file.this,
    proxmox_virtual_environment_download_file.update,
    null_resource.detach_data_disks # Ensure disks are detached before attaching here
  ]
}
