locals {
  # Derive tags by machine_type
  default_tags = {
    controlplane = ["k8s","control-plane"]
    worker       = ["k8s","worker"]
  }

  # Map node ⇒ longhorn disk file identifier
  longhorn_disk_files = {
    for name, spec in var.nodes :
    name => "${var.storage_pool}:vm-${spec.vm_id}-disk-longhorn"
    if spec.machine_type == "worker" && contains(keys(spec.disks), "longhorn")
  }

  # Flatten every (node,diskkey) for detach/attach loops
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
