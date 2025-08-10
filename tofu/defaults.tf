variable "defaults_worker" {
  description = "Default configuration for worker nodes"
  type = object({
    host_node     = optional(string)
    machine_type  = string
    cpu           = number
    ram_dedicated = number
    igpu          = optional(bool, false)
    disks = optional(map(object({
      device      = string
      size        = string
      type        = string
      mountpoint  = string
      unit_number = number
    })), {})
  })
  default = {
    machine_type  = "worker"
    cpu           = 8
    ram_dedicated = 13312
    igpu          = false
    disks = {
      longhorn = {
        device      = "/dev/sdb"
        size        = "220G"
        type        = "scsi"
        mountpoint  = "/var/lib/longhorn"
        unit_number = 1
      }
    }
  }
}

variable "defaults_controlplane" {
  description = "Default configuration for control plane nodes"
  type = object({
    host_node     = optional(string)
    machine_type  = string
    cpu           = number
    ram_dedicated = number
    igpu          = optional(bool, false)
    disks = optional(map(object({
      device      = string
      size        = string
      type        = string
      mountpoint  = string
      unit_number = number
    })), {})
  })
  default = {
    machine_type  = "controlplane"
    cpu           = 6
    ram_dedicated = 6144
    igpu          = false
    disks         = {}
  }
}