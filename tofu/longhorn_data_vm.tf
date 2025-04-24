resource "proxmox_virtual_environment_vm" "longhorn_data" {
  name      = "longhorn-data"
  node_name = var.disk_owner.node_name # Use existing disk_owner variable
  started   = false                    # headless disk holder

  disk {
    datastore_id = var.storage_pool
    size         = 150
    interface    = "scsi0"
    iothread     = true
  }

  lifecycle {
    prevent_destroy = true

    # Optional: Ignore changes to the disk block itself if managed externally
    # ignore_changes = [disk]
  }
}
