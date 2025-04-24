resource "proxmox_virtual_environment_vm" "k8s_node" {
  for_each = var.nodes
  node_name = each.value.host_node
  name      = each.key
  tags      = each.value.tags
  pool_id   = var.pool_id

  agent {
    enabled = true
  }

  bios = "ovmf"
  efi_disk {
    datastore_id = var.storage_pool
    file_format  = "raw"
    type         = "4m"
  }

  dynamic "disk" {
    # <-- instead consume the passed-in var.longhorn_disk_files map
    for_each = var.longhorn_disk_files

    content {
      datastore_id = var.storage_pool
      file_id      = each.value
      interface    = "scsi${count.index + 1}" # Note: This assumes count.index starts at 0 and maps correctly. Verify if needed.
      iothread     = true
      cache        = "writethrough"
      discard      = "on"
      ssd          = true
    }
  }

  disk {
    datastore_id = var.storage_pool
    file_id      = local.os_disk_file_id
    interface    = "scsi0"
    size         = each.value.disk_size
    iothread     = true
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
  }

  initialization {
    datastore_id = var.storage_pool
    user_data_file_id = talos_image_factory_schematic.this[each.key].machine_config_iso_file_id

    ip_config {
      ipv4 {
        address = "${each.value.ip_address}/24"
        gateway = var.gateway_ip
      }
    }

    dns {
      servers = var.dns_servers
    }
  }

  machine = "q35"
  memory {
    dedicated = each.value.memory
  }

  network_device {
    bridge    = var.network_bridge
    firewall  = false
    mac_address = each.value.mac_address
    model     = "virtio"
    mtu       = var.network_mtu
    rate_limit_megabytes_per_second = 0
  }

  operating_system {
    type = "l26"
  }

  protection {
    delete = false
  }

  reboot_required = false
  scsi_hardware   = "virtio-scsi-single"
  cpu {
    architecture = "x86_64"
    cores        = each.value.cpu_cores
    sockets      = 1
    type         = "host"
  }

  dynamic "hostpci" {
    for_each = lookup(each.value, "igpu", false) ? [1] : []
    content {
      device_id = "0"
      mapping   = "intel-gvt-g"
      mdev      = "i915-GVTg_V5_4"
    }
  }

  dynamic "hostpci" {
    for_each = lookup(each.value, "igpu", false) ? [1] : []
    content {
      device_id = "1"
      mapping   = "intel-gvt-g"
      mdev      = "i915-GVTg_V5_4"
    }
  }
}
