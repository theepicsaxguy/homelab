variable "proxmox" {
  type = object({
    name         = string
    cluster_name = string
    endpoint     = string
    insecure     = bool
    username     = string
    api_token    = string
  })
  sensitive = true
}

# Storage pool and disk owner variables have been removed as they are unused


variable "nodes" {
  description = "Map of Talos nodes to create"
  type = map(object({
    host_node     = string
    machine_type  = string # controlplane or worker
    ip            = string
    mac_address   = string
    vm_id         = number
    cpu           = number
    ram_dedicated = number
    update        = bool
    igpu          = optional(bool, false)
    disks = optional(map(object({
      device     = string # e.g., /dev/sdb
      size       = string # e.g., 150G
      type       = string # e.g., scsi, virtio
      mountpoint = string # e.g., /var/lib/longhorn
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for node in values(var.nodes) :
      alltrue([
        for disk in values(node.disks) :
        can(regex("^\\d+G$", disk.size))
      ])
    ])
    error_message = "All disk sizes must be specified in gigabytes (e.g., '150G')."
  }
}
