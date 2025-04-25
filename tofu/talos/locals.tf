locals {
  default_tags = {
    controlplane = ["k8s","control-plane"]
    worker       = ["k8s","worker"]
  }

  longhorn_disk_files = {
    for name, spec in var.nodes :
    name => "${var.storage_pool}:vm-${spec.vm_id}-disk-longhorn"
    if spec.machine_type == "worker"
      && contains(keys(lookup(spec, "disks", {})), "longhorn")
  }

  # Only worker nodes with a 'longhorn' disk get an extra disk attached
  worker_disks = [
    for node, spec in var.nodes :
    { node = node, interface = "scsi1" }
    if spec.machine_type == "worker" && contains(keys(lookup(spec, "disks", {})), "longhorn")
  ]

  worker_disk_specs = merge([
    for node, spec in var.nodes :
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
}
