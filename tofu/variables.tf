variable "cluster" {
  type = object({
    name               = string
    endpoint           = string
    gateway            = string
    vip                = string
    talos_version      = string
    proxmox_cluster    = string
    kubernetes_version = optional(string, "1.32.0") # Default K8s version if not specified
  })
  default = {
    name               = "talos"
    endpoint           = "api.kube.pc-tips.se"
    gateway            = "10.25.150.1"
    vip                = "10.25.150.10"
    talos_version      = "v1.9.5"
    proxmox_cluster    = "kube"
    kubernetes_version = "1.33.0"
  }
}

variable "storage_pool" {
  description = "The Proxmox storage pool to use for VM disks."
  type        = string
  default     = "local-lvm"
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

variable "proxmox" {
  description = "Proxmox API connection details"
  type = object({
    endpoint  = string
    insecure  = bool
    username  = string
    api_token = string
  })
  sensitive = true
}

variable "image" {
  description = "Talos image configuration"
  type = object({
    version        = string
    update_version = string
    schematic      = string
  })
  default = {
    version        = "v1.9.5"
    update_version = "v1.9.5"
    schematic      = "talos/image/schematic.yaml"
  }
}

variable "inline_manifests" {
  description = "Additional manifests to apply after bootstrap"
  type = list(object({
    name         = string
    content      = string
    dependencies = optional(list(string), [])
  }))
  default = []
}
