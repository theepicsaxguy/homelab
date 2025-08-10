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
  description = "Controls sequential node upgrades."
  type = object({
    enabled = bool
    index   = number
  })
  default = {
    enabled = false
    index   = -1
  }
}

variable "talos_image" {
  description = "Talos image configuration"
  type = object({
    schematic_path        = string
    version               = string
    update_schematic_path = optional(string)
    update_version        = optional(string)
    arch                  = optional(string, "amd64")
    platform              = optional(string, "nocloud")
    proxmox_datastore     = optional(string, "velocity")
    factory_url           = optional(string, "https://factory.talos.dev")
  })
}

variable "nodes_config" {
  description = "Per-node configuration map (primary cluster)"
  type = map(object({
    host_node          = optional(string)
    machine_type       = string
    ip                 = string
    mac_address        = optional(string)
    vm_id              = optional(number)
    is_external        = optional(bool, false)
    cpu                = optional(number)
    ram_dedicated      = optional(number)
    update             = optional(bool, false)
    igpu               = optional(bool, false)
    gpu_node_exclusive = optional(bool, true)
    gpu_devices        = optional(list(string), [])
    gpu_device_meta = optional(map(object({
      id           = string
      subsystem_id = string
      iommu_group  = number
    })), {})
    datastore_id          = optional(string)
    network_bridge        = optional(string)
    network_vlan_id       = optional(number)
    root_disk_file_format = optional(string)
    root_disk_size        = optional(number)
    dns_servers           = optional(list(string))
    disks = optional(map(object({
      device      = string
      size        = string
      type        = string
      mountpoint  = string
      unit_number = number
    })), {})
  }))

  validation {
    condition     = length(distinct([for n in values(var.nodes_config) : n.ip])) == length(var.nodes_config)
    error_message = "Node IP addresses must be unique."
  }
}

variable "proxmox_extra" {
  description = "Proxmox API connection for extra cluster"
  type = object({
    name         = string
    cluster_name = string
    endpoint     = string
    insecure     = bool
    username     = string
    api_token    = string
  })
  sensitive = true
  default   = null
}

variable "nodes_config_extra" {
  description = "Per-node configuration for extra proxmox cluster (optional)"
  type = map(object({
    host_node          = optional(string)
    machine_type       = string
    ip                 = string
    mac_address        = optional(string)
    vm_id              = optional(number)
    is_external        = optional(bool, false)
    cpu                = optional(number)
    ram_dedicated      = optional(number)
    update             = optional(bool, false)
    igpu               = optional(bool, false)
    gpu_node_exclusive = optional(bool, true)
    gpu_devices        = optional(list(string), [])
    gpu_device_meta = optional(map(object({
      id           = string
      subsystem_id = string
      iommu_group  = number
    })), {})
    datastore_id          = optional(string)
    network_bridge        = optional(string)
    network_vlan_id       = optional(number)
    root_disk_file_format = optional(string)
    root_disk_size        = optional(number)
    dns_servers           = optional(list(string))
    disks = optional(map(object({
      device      = string
      size        = string
      type        = string
      mountpoint  = string
      unit_number = number
    })), {})
  }))
  default = {}
}

variable "cluster_name" { type = string }
variable "cluster_domain" { type = string }

variable "cluster_name_extra" {
  type    = string
  default = "talos-b"
}

variable "cluster_domain_extra" {
  type    = string
  default = null
}

variable "proxmox_datastore" {
  description = "Default Proxmox datastore for all nodes"
  type        = string
  default     = "velocity"
}

variable "proxmox_cluster" { type = string }

variable "versions" {
  description = "Software versions for the cluster components."
  type = object({
    talos      = string
    kubernetes = string
  })
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
  description = "Optional OIDC provider configuration for Kubernetes API server."
  type = object({
    issuer_url = string
    client_id  = string
  })
  default = null
}
