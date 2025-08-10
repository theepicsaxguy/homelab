variable "talos_image" {
  description = "Talos image configuration"
  type = object({
    version               = string
    update_version        = optional(string)
    schematic_path        = string
    update_schematic_path = optional(string)

    # Either provide image_url / update_image_url directly,
    # or provide factory_url/platform/arch and schematic_id / update_schematic_id
    image_url             = optional(string)
    update_image_url      = optional(string)
    file_name             = optional(string)
    update_file_name      = optional(string)

    factory_url           = optional(string, "https://factory.talos.dev")
    platform              = optional(string, "nocloud")
    arch                  = optional(string, "amd64")
    schematic_id          = optional(string)
    update_schematic_id   = optional(string)

    proxmox_datastore     = string
  })
}

variable "cluster" {
  description = "Cluster settings"
  type = object({
    name               = string
    endpoint           = string
    talos_version      = string
    proxmox_cluster    = string
    kubernetes_version = string
  })
}

variable "cluster_domain" {
  description = "Cluster domain (e.g., cluster.local)"
  type        = string
}

variable "proxmox_datastore" {
  description = "Default Proxmox datastore for VM disks and ISOs"
  type        = string
  default     = "velocity"
}

variable "manage_cluster" {
  description = "Run cluster-wide Talos actions (secrets, bootstrap, kubeconfig)."
  type        = bool
  default     = true
}

variable "network" {
  description = "Network settings (original shape)"
  type = object({
    bridge      = string
    vlan_id     = number
    gateway     = string
    vip         = string
    cidr_prefix = number
    dns_servers = list(string)
  })
}

variable "oidc" {
  description = "OIDC configuration"
  type = object({
    issuer_url = string
    client_id  = string
  })
}

variable "nodes" {
  description = "Configuration for cluster nodes"
  type = map(object({
    host_node                = string
    machine_type             = string
    ip                       = string
    mac_address              = optional(string)
    vm_id                    = number
    datastore_id             = optional(string)
    cpu                      = number
    ram_dedicated            = number
    igpu                     = optional(bool)
    gpu_node_exclusive       = optional(bool)
    gpu_devices              = optional(list(string))
    gpu_device_meta          = optional(map(object({
      id           = string
      subsystem_id = string
      iommu_group  = number
    })))
    is_external              = optional(bool)
    update                   = optional(bool)
    network_bridge           = optional(string)
    network_vlan_id          = optional(number)
    root_disk_file_format    = optional(string)
    root_disk_size           = optional(number)
    dns_servers              = optional(list(string))
    disks                    = optional(map(object({
      device      = string
      size        = string
      type        = string
      mountpoint  = string
      unit_number = number
    })))
  }))

  validation {
    condition     = !var.manage_cluster || length([for n in values(var.nodes) : n if n.machine_type == "controlplane"]) >= 1
    error_message = "You must define at least one controlplane node when manage_cluster = true."
  }

  validation {
    condition = alltrue([for n in values(var.nodes) : can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", n.ip)) ])
    error_message = "Each node must have a valid IPv4 address."
  }
}

# Optional, with sensible in-module defaults to keep root DRY.
variable "cilium" {
  description = "Cilium configuration (optional; module has defaults)"
  type = object({
    values  = string
    install = string
  })
  default = null
}

variable "coredns" {
  description = "CoreDNS configuration (optional; module has defaults)"
  type = object({
    install = string
  })
  default = null
}
