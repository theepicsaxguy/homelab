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

variable "upgrade_control" {
  description = "Controls sequential node upgrades. Set enabled=true and specify index to upgrade a specific node."
  type = object({
    enabled = bool
    index   = number
  })
  default = {
    enabled = false
    index   = -1
  }

  validation {
    condition     = var.upgrade_control.index >= -1
    error_message = "Index must be -1 (disabled) or a valid node position (0+)."
  }
}

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

variable "nodes_config" {
  description = "Configuration map for cluster nodes"
  type = map(object({
    machine_type  = string
    ip            = string
    mac_address   = string
    vm_id         = number
    ram_dedicated = optional(number)
    cpu           = optional(number)
    igpu          = optional(bool)
    host_node     = optional(string)
    disks = optional(map(object({
      device      = string
      size        = string
      type        = string
      mountpoint  = string
      unit_number = optional(number)
    })))
  }))
  default = {}
  validation {
    condition     = length(var.nodes_config) > 0
    error_message = "nodes_config must not be empty. Ensure nodes.auto.tfvars is loaded."
  }
}
