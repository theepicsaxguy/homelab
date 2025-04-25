resource "proxmox_virtual_environment_vm" "worker" {
  for_each        = var.nodes
  stop_on_destroy = true
  node_name       = each.value.host_node
  name            = each.key
  on_boot         = true
  machine         = "q35"
  bios            = "seabios"
  scsi_hardware   = "virtio-scsi-single"
  tags            = lookup(local.default_tags, each.value.machine_type, [])

  agent { enabled = true }

  cpu {
    cores = each.value.cpu
    type  = "host"
  }

  memory {
    dedicated = each.value.ram_dedicated
  }

  network_device {
    bridge      = var.cluster.bridge
    vlan_id     = var.cluster.vlan_id
    mac_address = each.value.mac_address
  }

  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    size         = 20
    file_format  = "raw"
    # single-line ternary for file_id
    file_id      = each.value.update ? proxmox_virtual_environment_download_file.update[0].id : proxmox_virtual_environment_download_file.this.id
    iothread     = true
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
  }

  dynamic "disk" {
    for_each = local.worker_disks
    content {
      datastore_id = "velocity" # explicitly correct datastore
      interface    = disk.value.interface
      file_id      = local.longhorn_disk_files[disk.value.node]
      size         = 150 # explicitly set back to 150GB
      iothread     = true
      cache        = "writethrough"
      discard      = "on"
      ssd          = true
      file_format  = "raw"
    }
  }

  initialization {
    datastore_id = var.storage_pool
    dns {
      domain  = var.cluster.domain
      servers = [ var.cluster.gateway ]
    }
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.cluster.gateway
      }
    }
  }

  dynamic "hostpci" {
    for_each = lookup(each.value, "igpu", false) ? [1] : []
    content {
      device  = "hostpci0"
      mapping = "iGPU"
      pcie    = true
      rombar  = true
      xvga    = false
    }
  }

  boot_order = ["scsi0"]
  description = "Talos Worker"
  operating_system { type = "l26" }
}
