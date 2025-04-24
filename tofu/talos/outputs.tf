output "longhorn_disk_files" {
  description = "List of file_ids from the data_disks VM for each worker node"
  value = {
    for node_name, disk_list in proxmox_virtual_environment_vm.data_disks.disk :
    node_name => disk_list.file_id if disk_list.interface != "scsi0"
  }
}
