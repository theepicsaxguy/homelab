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

// -------------------------------------------------------------------
// Inputs for disk‐persistence and Proxmox wiring

variable "storage_pool" {
  description = "Proxmox storage pool to use for all VM disks"
  type        = string
}

// -------------------------------------------------------------------
// Inputs for the Talos VM orchestrator

variable "cilium" {
  description = "Cilium inline-manifest settings"
  type = object({
    values  = string
    install = string
  })
}

variable "coredns" {
  description = "CoreDNS inline-manifest settings"
  type = object({
    install = string
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


