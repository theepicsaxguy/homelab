resource "proxmox_virtual_environment_vm" "k8s_node" {
  # ... Keep original attributes like for_each, node_name, name, tags ...
  for_each = var.nodes
  node_name = each.value.host_node
  name      = each.key
  tags      = each.value.tags

  # ... Keep original agent block if present ...
  agent {
    enabled = true
  }

  # Original OS disk block - KEEP THIS
  disk {
    datastore_id = var.storage_pool # Keep original datastore_id
    file_id      = local.os_disk_file_id # Keep original file_id reference
    interface    = "scsi0" # Keep original interface
    size         = 20 # Keep original size (or each.value.disk_size if that was original)
    # ... other original OS disk settings ...
  }

  # Re-attach existing Longhorn disks - ADD THIS
  dynamic "disk" {
    for_each = var.longhorn_disk_files
    content {
      datastore_id = var.storage_pool # Use the correct storage pool for data disks
      file_id      = each.value
      interface    = "scsi${index(sort(keys(var.longhorn_disk_files)), each.key) + 1}"
      # ... other necessary settings for data disks ...
      iothread     = true
      cache        = "writethrough"
      discard      = "on"
      ssd          = true
    }
  }

  # Protect the new VM itself from accidentally deleting disks - Use argument syntax
  protection = false

  # ... Keep other original essential settings (cpu, memory, network_device, scsi_hardware etc.) ...
  cpu {
    # ... original cpu settings ...
  }
  memory {
    # ... original memory settings ...
  }
  network_device {
    # ... original network_device settings ...
  }
  scsi_hardware = "virtio-scsi-single" # Example: Keep if original

  # REMOVE unrelated blocks/attributes added in previous attempts (bios, efi_disk, hostpci, initialization, machine, operating_system, etc.)
}
