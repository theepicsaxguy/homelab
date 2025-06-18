variable "talos_image" {
  description = "Talos image configuration"
  type = object({
    factory_url           = optional(string, "https://factory.talos.dev")
    schematic_path        = string
    version               = string
    update_schematic_path = optional(string)
    update_version        = optional(string)
    arch                  = optional(string, "amd64")
    platform              = optional(string, "nocloud")
    proxmox_datastore     = optional(string, "local")
  })
}
variable "cluster" {
  description = "Cluster configuration"
  type = object({
    name               = string
    endpoint           = string
    gateway            = string
    vip                = string
    talos_version      = string
    proxmox_cluster    = string
    kubernetes_version = optional(string, "1.32.0")
  })
}


variable "nodes" {
  description = "Configuration for cluster nodes"
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
      device      = string
      size        = string
      type        = string
      mountpoint  = string
      unit_number = number
    })), {})
  }))

  validation {
    condition     = length([for n in values(var.nodes) : n if n.machine_type == "controlplane"]) > 0
    error_message = "You must define at least one node with machine_type \"controlplane\"."
  }
}


# variable "storage_pool" {
#   type        = string
#   description = "Default Proxmox storage pool to use for VM disks."
# }

# variable "disk_owner" {
#   description = "Where to create the data disks VM"
#   type = object({
#     node_name = string
#     vm_id     = number
#   })
# }



