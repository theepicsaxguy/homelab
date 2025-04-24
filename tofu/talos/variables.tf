variable "image" {
  description = "Talos image configuration"
  type = object({
    factory_url       = optional(string, "https://factory.talos.dev")
    schematic         = string
    version           = string
    update_schematic  = optional(string)
    update_version    = optional(string)
    arch              = optional(string, "amd64")
    platform          = optional(string, "nocloud")
    proxmox_datastore = optional(string, "local")
  })
}

variable "cluster" {
  description = "Cluster configuration"
  type = object({
    name               = string
    endpoint           = string
    gateway            = string
    vip                = string
    talos_version      = string
    proxmox_cluster    = string
    kubernetes_version = optional(string, "1.32.0")
  })
}

variable "nodes" {
  description = "Configuration for cluster nodes"
  type = map(object({
    host_node     = string
    machine_type  = string
    datastore_id  = optional(string, "velocity")
    ip            = string
    mac_address   = string
    vm_id         = number
    cpu           = number
    ram_dedicated = number
    update        = optional(bool, false)
    igpu          = optional(bool, false)
    disks = optional(map(object({
      device     = string
      size       = string
      type       = string
      mountpoint = string
    })), {})
  }))
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

variable "storage_pool" {
  type        = string
  description = "Default Proxmox storage pool to use for VM disks."
}

variable "disk_owner" {
  description = "Where to create the data disks VM"
  type = object({
    node_name = string
    vm_id     = number
  })
}

variable "inline_manifests" {
  description = "Inline manifests to apply after bootstrap with dependencies"
  type = list(object({
    name         = string
    content      = string
    dependencies = optional(list(string), [])
  }))
  default = []
}

variable "longhorn_disk_files" {
  description = "Map of worker node name to its Longhorn data disk file ID."
  type        = map(string)
  default     = {}
}

variable "pool_id" {
  description = "The Proxmox resource pool ID where VMs will be placed."
  type        = string
}

variable "gateway_ip" {
  description = "The IP address of the network gateway."
  type        = string
}

variable "dns_servers" {
  description = "List of DNS server IP addresses."
  type        = list(string)
}

variable "network_bridge" {
  description = "The name of the Proxmox network bridge to connect VMs to."
  type        = string
}

variable "network_mtu" {
  description = "The MTU (Maximum Transmission Unit) for the network interface."
  type        = number
  default     = 1500 # Or another sensible default
}


