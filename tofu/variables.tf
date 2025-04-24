variable "cluster" {
  description = "Cluster configuration details"
  type = object({
    name               = string
    endpoint           = string
    gateway            = string
    vip                = string
    talos_version      = string
    proxmox_cluster    = string
    kubernetes_version = optional(string, "1.32.0") # Default K8s version if not specified
  })
  # Add default or sensitive = true as needed
}

variable "storage_pool" {
  description = "The Proxmox storage pool to use for VM disks."
  type        = string
  # Add default or sensitive = true as needed
}

variable "disk_owner" {
  description = "Specifies the Proxmox node and VM ID for the dedicated data disks VM."
  type = object({
    node_name = string
    vm_id     = number
  })
  # Add default or sensitive = true as needed
}

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
    gpu_id        = optional(string) # Add this line for explicit schema definition
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
