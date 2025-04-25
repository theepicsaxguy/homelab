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

variable "nodes" {
  description = "Configuration for cluster nodes (passthrough from root)"
  type = map(object({
    host_node     = string
    machine_type  = string
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

variable "cluster" {
  description = "Cluster configuration object (passthrough from root)"
  type = object({
    name               = string
    endpoint           = string
    gateway            = string
    vip                = string
    domain             = string
    bridge             = string
    vlan_id            = number
    talos_version      = string
    proxmox_cluster    = string
    kubernetes_version = string
  })
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

variable "longhorn_disk_files" { type = map(string) }
variable "worker_disk_specs" { type = map(object({
  host      = string
  vm_id     = number
  interface = string
  node      = string
  disk_key  = string
  pool      = string
  size      = string
})) }
variable "os_disk_file_id" { type = map(string) }


