variable "defaults_worker" {
  description = "Default configuration for worker nodes"
  type = object({
    host_node     = optional(string) #  "The Proxmox node to schedule this VM on. If omitted, defaults to the `name` specified in the `var.proxmox` provider configuration."
    machine_type  = string
    cpu           = number
    cpu_units     = optional(number)
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
    machine_type  = "worker"
    cpu           = 8
    cpu_units     = 1024
    ram_dedicated = 13653
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
    host_node     = optional(string) #  "The Proxmox node to schedule this VM on. If omitted, defaults to the `name` specified in the `var.proxmox` provider configuration."
    machine_type  = string
    cpu           = number
    cpu_units     = optional(number)
    ram_dedicated = number
  })
  default = {
    machine_type  = "controlplane"
    cpu           = 6
    cpu_units     = 1024
    ram_dedicated = 6144
  }
}
