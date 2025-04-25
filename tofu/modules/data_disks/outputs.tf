output "longhorn_disk_files" {
  description = "Map of worker node name to its Longhorn data disk file ID."
  value = {
    for node_name, node in var.nodes :
    node_name => proxmox_virtual_environment_vm.data_disks.disk[
      index(sort(keys(var.nodes)), node_name) + 1
    ].file_id
    if contains(keys(node.disks), "longhorn")
  }
}
