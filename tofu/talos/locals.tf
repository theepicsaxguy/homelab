locals {
  # Determine the OS disk file ID based on whether any node needs an updated image
  os_disk_file_id = local.needs_update_image ? proxmox_virtual_environment_download_file.update[0].id : proxmox_virtual_environment_download_file.this.id
}
