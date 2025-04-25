locals {
  default_tags = {
    controlplane = ["k8s", "control-plane"]
    worker       = ["k8s", "worker"]
  }

  # Only worker nodes with a 'longhorn' disk get an extra disk attached
  worker_disks = [
    for node, spec in var.nodes :
    { node = node, interface = "scsi1" }
    if spec.machine_type == "worker" && contains(keys(lookup(spec, "disks", {})), "longhorn")
  ]
}
