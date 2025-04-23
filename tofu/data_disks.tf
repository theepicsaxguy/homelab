// Data disks VM for persistent Longhorn storage
resource "proxmox_virtual_environment_vm" "data_disks" {
  name      = "talos-data-disks"
  node_name = var.disk_owner.node_name
  vm_id     = var.disk_owner.vm_id

  // minimal VM configuration—no network, no cloud-init
  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    size         = 1
    iothread     = true
    cache        = "writethrough"
  }

  dynamic "disk" {
    for_each = {
      for nk, n in var.nodes :
      nk => n.disks["longhorn"]
      if contains(keys(n.disks), "longhorn")
    }
    content {
      datastore_id = var.storage_pool
      size         = tonumber(replace(disk.value.size, "G", ""))
      interface    = disk.value.type == "scsi" ? "scsi${index(keys(var.nodes), each.key) + 1}" : "virtio${index(keys(var.nodes), each.key) + 1}"
      iothread     = true
      cache        = "writethrough"
    }
  }
}

// Detach disks from the data_disks VM
resource "null_resource" "detach_data_disks" {
  depends_on = [proxmox_virtual_environment_vm.data_disks]

  triggers = {
    // re-run if disk spec changes
    disks_hash = sha1(jsonencode(var.nodes))
  }

  provisioner "local-exec" {
    command = join("\n", [
      for d in slice(proxmox_virtual_environment_vm.data_disks.disk, 1, length(proxmox_virtual_environment_vm.data_disks.disk)) :
      "pvesh delete /nodes/${proxmox_virtual_environment_vm.data_disks.node_name}/qemu/${proxmox_virtual_environment_vm.data_disks.vm_id}/config/disks/${d.interface}"
    ])
  }
}
