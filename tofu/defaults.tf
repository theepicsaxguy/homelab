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
      size        = optional(string)  # Optional - only needed if creating disk in Proxmox
      type        = optional(string)  # Optional - only needed if creating disk in Proxmox
      mountpoint  = string
      unit_number = optional(number)  # Optional - only needed if creating disk in Proxmox
    }))
  })
  default = {
    machine_type  = "worker"
    cpu           = 8
    cpu_units     = 1024
    ram_dedicated = 21504
    igpu          = false
    disks = {
      longhorn = {
        device     = "/dev/sdc" # scsi1 in Proxmox - disk already exists, just mount it
        mountpoint = "/var/lib/longhorn"
        # size, type, unit_number omitted - disk already exists in Proxmox
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
    ram_dedicated = 8192
    disks         = {}
  }
}
