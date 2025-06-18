variable "defaults_worker" {
  description = "Default configuration for worker nodes"
  type = object({
    host_node     = string
    machine_type  = string
    cpu           = number
    ram_dedicated = number
    igpu          = bool
    disks = map(object({
      device      = string
      size        = string
      type        = string
      mountpoint  = string
      unit_number = number
    }))
  })
  default = {
    host_node     = "host3"
    machine_type  = "worker"
    cpu           = 8
    ram_dedicated = 10240
    igpu          = false
    disks = {
      longhorn = {
        device      = "/dev/sdb"
        size        = "180G"
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
    host_node     = string
    machine_type  = string
    cpu           = number
    ram_dedicated = number
  })
  default = {
    host_node     = "host3"
    machine_type  = "controlplane"
    cpu           = 6
    ram_dedicated = 6144
  }
}
