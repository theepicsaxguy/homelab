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
  description = "Per-node configuration map"
  type = map(object({
    host_node     = optional(string) #  "The Proxmox node to schedule this VM on. If omitted, defaults to the `name` specified in the `var.proxmox` provider configuration."
    machine_type  = string
    ip            = string
    mac_address   = string
    vm_id         = number
    ram_dedicated = optional(number)
    igpu          = optional(bool)
    disks         = optional(map(object({
      device      = optional(string)
      size        = optional(string)
      type        = optional(string)
      mountpoint  = optional(string)
      unit_number = optional(number)
    })))
  }))

  validation {
    condition = alltrue([
      for n in values(var.nodes_config) :
      contains(["worker", "controlplane"], n.machine_type)
    ])
    error_message = "machine_type must be worker or controlplane."
  }
}
