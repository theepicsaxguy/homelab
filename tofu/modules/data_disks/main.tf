// tofu/data_disks.tf
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.76"
    }
  }
}

// Dedicated VM to hold Longhorn disks so they survive worker reprovision
resource "proxmox_virtual_environment_vm" "data_disks" {
  name      = "talos-data-disks"
  node_name = var.disk_owner.node_name
  vm_id     = var.disk_owner.vm_id

  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    size         = 1 // the VM’s OS disk (tiny)
    iothread     = true
    cache        = "writethrough"
  }

  // One disk per worker’s longhorn spec
  dynamic "disk" {
    for_each = {
      for node_name, node in var.nodes :
      node_name => node.disks["longhorn"]
      if contains(keys(node.disks), "longhorn")
    }
    content {
      datastore_id = var.storage_pool
      # Use each.key instead of node_name
      interface    = "scsi${index(sort(keys(var.nodes)), each.key) + 1}"
      size         = tonumber(replace(disk.value.size, "G", ""))
      iothread     = true
      cache        = "writethrough"
    }
  }

  lifecycle {
    prevent_destroy = true
    # Remove empty ignore_changes block
  }
  # ... ensure no other lifecycle blocks exist for this resource ...
}

// Before re-attaching disks to workers, detach them here
resource "null_resource" "detach_data_disks" {
  depends_on = [proxmox_virtual_environment_vm.data_disks]

  triggers = {
    // regenerate whenever the set of worker disks changes
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
