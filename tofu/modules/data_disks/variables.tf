variable "disk_owner" {
  description = "Where to create the data disks VM"
  type = object({
    node_name = string
    vm_id     = number
  })
}

variable "storage_pool" {
  type        = string
  description = "Default Proxmox storage pool to use for VM disks."
}

variable "nodes" {
  description = "Configuration for cluster nodes (used to determine required disks)"
  type = map(object({
    host_node     = string
    machine_type  = string
    datastore_id  = optional(string, "velocity")
    ip            = string
    mac_address   = string
    vm_id         = number
    cpu           = number
    ram_dedicated = number
    update        = optional(bool, false)
    igpu          = optional(bool, false)
    disks = optional(map(object({
      device     = string
      size       = string
      type       = string
      mountpoint = string
    })), {})
  }))
}
