# a disks VM for persistent Longhorn storage
resource "proxmox_virtual_environment_vm" "data_disks" {
  name      = "talos-data-disks"
  node_name = var.disk_owner.node_name
  vm_id     = var.disk_owner.vm_id

  # minimal VM configuration—no network, no cloud-init
  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    size         = 10
    iothread     = true
    cache        = "writethrough"
  }

  # Attach all longhorn disks for all worker nodes
  dynamic "disk" {
    for_each = {
      for nk, n in coalesce(var.nodes, local.nodes_defaults) :
      nk => n.disks["longhorn"]
      if contains(keys(lookup(n, "disks", {})), "longhorn")
    }
    content {
      datastore_id = var.storage_pool
      size         = tonumber(replace(disk.value.size, "G", ""))
      interface    = disk.value.type == "scsi" ? "scsi${index(keys(coalesce(var.nodes, local.nodes_defaults)), disk.key) + 1}" : "virtio${index(keys(coalesce(var.nodes, local.nodes_defaults)), disk.key) + 1}"
      iothread     = true
      cache        = "writethrough"
    }
  }
}

# detach disks from the data_disks VM once created
resource "null_resource" "detach_data_disks" {
  depends_on = [proxmox_virtual_environment_vm.data_disks]

  triggers = {
    disks_hash = sha1(jsonencode(var.nodes))
  }

  provisioner "local-exec" {
    command = join("\n", [
      for d in slice(
        proxmox_virtual_environment_vm.data_disks.disk,
        1,
        length(proxmox_virtual_environment_vm.data_disks.disk)
      ) :
      "pvesh delete /nodes/${proxmox_virtual_environment_vm.data_disks.node_name}/qemu/${proxmox_virtual_environment_vm.data_disks.vm_id}/config/disks/${d.interface}"
    ])
  }
}
