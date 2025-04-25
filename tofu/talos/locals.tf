locals {
  # Derive tags by machine_type
  default_tags = {
    controlplane = ["k8s","control-plane"]
    worker       = ["k8s","worker"]
  }

  # Unified OS-disk file_id (References resources within this module)
  os_disk_file_id = (
    length(proxmox_virtual_environment_download_file.update) > 0
    ? proxmox_virtual_environment_download_file.update[0].id
    : proxmox_virtual_environment_download_file.this.id
  )

  # Map node ⇒ longhorn disk file identifier (Uses module variables)
  longhorn_disk_files = {
    for name, spec in var.nodes :
    name => "${var.storage_pool}:vm-${spec.vm_id}-disk-longhorn"
    if spec.machine_type == "worker" && contains(keys(spec.disks), "longhorn")
  }

  # Flatten every (node,diskkey) for detach/attach loops (Uses module variables)
  worker_disk_specs = merge([
    for node, spec in var.nodes :
      spec.disks == null ? {} : {
        for dk, dv in spec.disks :
          "${node}-${dk}" => {
            host      = spec.host_node
            vm_id     = spec.vm_id
            disk_key  = dk
            node      = node
            interface = "scsi${index(keys(spec.disks), dk) + 1}"
            pool      = var.storage_pool
            size      = dv.size
          }
      }
  ]...)
}
