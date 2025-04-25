resource "proxmox_virtual_environment_vm" "this" {
  for_each        = var.nodes
  stop_on_destroy = true
  node_name       = each.value.host_node
  name            = each.key
  tags            = []

  agent {
    enabled = true
  }
  disk {
    interface    = "scsi0"
    datastore_id = var.storage_pool
    size         = 20
    file_format  = "raw"
    iothread     = true
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    file_id      = "${var.storage_pool}:vm-${each.value.vm_id}-os"
  }
  dynamic "disk" {
    for_each = {
      for k, spec in local.worker_disk_specs :
      k => spec if spec.vm_id == each.value.vm_id
    }
    content {
      interface    = disk.value.interface
      datastore_id = var.storage_pool
      file_id      = local.longhorn_disk_files[disk.value.node]
      iothread     = true
      cache        = "writethrough"
      discard      = "on"
      ssd          = true
    }
  }
  cpu {
    cores = each.value.cpu
  }
  memory {
    dedicated = each.value.ram_dedicated
  }
  network_device {
    mac_address = each.value.mac_address
  }
  scsi_hardware = "virtio-scsi-single"
}
