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
    # gateway and vip are now in var.network
    talos_version      = string
    proxmox_cluster    = string
    kubernetes_version = optional(string, "1.32.0")
  })
}

variable "cluster_domain" {
  description = "Internal cluster domain"
  type        = string
}

variable "network" {
  description = "Network configuration for the cluster."
  type = object({
    gateway     = string
    vip         = string
    cidr_prefix = number
    dns_servers = list(string)
    bridge      = string
    vlan_id     = number
  })
}

variable "oidc" {
  description = "Optional OIDC provider configuration."
  type = object({
    issuer_url = string
    client_id  = string
  })
  default = null
}

variable "proxmox_datastore" {
  description = "Proxmox datastore to use for VM disks"
  type        = string
  default     = "velocity"
}

variable "nodes" {
  description = "Configuration for cluster nodes"
  type = map(object({
    host_node     = string
    machine_type  = string
    datastore_id  = optional(string)
    ip            = string
    mac_address   = string
    vm_id         = number
    cpu           = number
    ram_dedicated = number
    update        = optional(bool, false)
    igpu          = optional(bool, false)
    gpu_node_exclusive = optional(bool, true)
    disks = optional(map(object({
      device      = string
      size        = string
      type        = string
      mountpoint  = string
      unit_number = number
    })), {}),
    gpu_devices = optional(list(string), []),
    gpu_device_meta = optional(
      map(object({
        id            = string
        subsystem_id  = string
        iommu_group   = number
      })),
      {}
    )
  }))

  validation {
    condition     = length([for n in values(var.nodes) : n if n.machine_type == "controlplane"]) > 0
    error_message = "You must define at least one node with machine_type \"controlplane\"."
  }

  validation {
    condition     = length(distinct([for n in values(var.nodes) : n.ip])) == length(var.nodes)
    error_message = "Node IP addresses must be unique."
  }

  validation {
    condition     = length(distinct([for n in values(var.nodes) : n.vm_id])) == length(var.nodes)
    error_message = "Node VM IDs must be unique."
  }

  validation {
    condition = alltrue([
      for n in values(var.nodes) : can(regex("^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$", n.mac_address))
    ])
    error_message = "MAC addresses must use the format 00:11:22:33:44:55."
  }
}

variable "cilium" {
  description = "Cilium configuration"
  type = object({
    values  = string
    install = string
  })
}

variable "coredns" {
  description = "CoreDNS configuration"
  type = object({
    install = string
  })
}



