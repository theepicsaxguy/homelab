variable "os_disk_file_id" {
  description = "Map of node name to OS disk file_id."
  type        = map(string)
}

variable "worker_disk_specs" {
  description = "Flattened map of worker disk specs for dynamic disk and null_resource blocks."
  type        = map(any)
}

variable "longhorn_disk_files" {
  description = "Map of node name to Longhorn disk file_id."
  type        = map(string)
}

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
  type        = any
}

variable "cluster" {
  description = "Cluster configuration object (passthrough from root)"
  type        = any
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


