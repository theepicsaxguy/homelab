variable "defaults_worker" {
  description = "Default configuration for worker nodes"
  type = object({
    host_node     = optional(string)
    machine_type  = string
    cpu           = number
    ram_dedicated = number
    disks         = optional(map(object({
      device      = string
      size        = string
      type        = string
      mountpoint  = string
      unit_number = number
    })), {})
  })
}

variable "defaults_controlplane" {
  description = "Default configuration for control plane nodes"
  type = object({
    host_node     = optional(string)
    machine_type  = string
    cpu           = number
    ram_dedicated = number
    disks         = optional(map(object({
      device      = string
      size        = string
      type        = string
      mountpoint  = string
      unit_number = number
    })), {})
  })
}
