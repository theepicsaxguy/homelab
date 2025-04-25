locals {
  # map each worker to its existing Longhorn vdisk file
  longhorn_disk_files = {
    for name, spec in coalesce(var.nodes, local.nodes_defaults) :
    name => "${var.storage_pool}:vm-${spec.vm_id}-disk-longhorn"
    if spec.machine_type == "worker" && contains(keys(lookup(spec, "disks", {})), "longhorn")
  }

  # flatten all disks so we can loop them in the VM resource
  worker_disk_specs = merge([
    for node, spec in coalesce(var.nodes, local.nodes_defaults) :
    lookup(spec, "disks", null) == null ? {} : {
      for dk, dv in lookup(spec, "disks", {}) :
      "${node}-${dk}" => {
        host      = spec.host_node
        vm_id     = spec.vm_id
        disk_key  = dk
        node      = node
        interface = "scsi${index(keys(lookup(spec, "disks", {})), dk) + 1}"
        pool      = var.storage_pool
        size      = dv.size
      }
    }
  ]...)

  # if you ever need the OS‐disk file IDs elsewhere
  os_disk_file_id = {
    for k, v in coalesce(var.nodes, local.nodes_defaults) :
    k => "${var.storage_pool}:vm-${v.vm_id}-os"
  }
}
