variable "talos_image" {
  description = "Talos image configuration"
  type = object({
    factory_url       = optional(string, "https://factory.talos.dev")
    schematic_path    = string
    version           = optional(string) # Defaults to var.versions.talos if not set
    update_version    = optional(string) # Defaults to var.versions.talos if not set
    arch              = optional(string, "amd64")
    platform          = optional(string, "nocloud")
    proxmox_datastore = optional(string, "local")
  })
}

variable "versions" {
  description = "Software versions for the cluster components"
  type = object({
    talos      = string
    kubernetes = string
  })
}

variable "cluster" {
  description = "Cluster configuration"
  type = object({
    name     = string
    endpoint = string
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
  default     = "Nvme1"
}

variable "nodes" {
  description = "Configuration for cluster nodes"
  type = map(object({
    host_node          = string
    machine_type       = string
    datastore_id       = optional(string)
    ip                 = string
    mac_address        = optional(string)
    vm_id              = optional(number)
    is_external        = optional(bool, false)
    cpu                = number
    ram_dedicated      = number
    igpu               = optional(bool, false)
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
        id           = string
        subsystem_id = string
        iommu_group  = number
      })),
      {}
    )
    upgrade = optional(bool, false)
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
    condition     = length(distinct([for n in values(var.nodes) : n.vm_id if !lookup(n, "is_external", false) && n.vm_id != null])) == length([for n in values(var.nodes) : n if !lookup(n, "is_external", false)])
    error_message = "VM IDs must be unique among internal nodes."
  }

  validation {
    condition = alltrue([
      for n in values(var.nodes) :
      lookup(n, "is_external", false) ? n.mac_address == null : n.mac_address != null
    ])
    error_message = "External nodes must not have mac_address; internal nodes must have mac_address."
  }

  validation {
    condition = alltrue([
      for n in values(var.nodes) :
      lookup(n, "is_external", false) || can(regex("^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$", n.mac_address))
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



