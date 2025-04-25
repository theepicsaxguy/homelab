########################
# root-module variables
########################

variable "proxmox" {
  description = "Proxmox API connection settings"
  type = object({
    endpoint  = string
    insecure  = bool
    username  = string
    api_token = string
  })
  sensitive = true
}

variable "storage_pool" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "velocity"
}

# override baked-in cluster settings if desired
variable "cluster" {
  description = "Cluster configuration object"
  type        = any
  default     = null
}

# override baked-in node map if desired
variable "nodes" {
  description = "Map of all Talos nodes"
  type        = any
  default     = null
}

variable "image" {
  description = "Talos image configuration object"
  type        = any
  default     = null
}

variable "cilium" {
  description = "Cilium install/values YAML strings"
  type        = any
  default     = null
}

variable "coredns" {
  description = "CoreDNS install YAML string"
  type        = any
  default     = null
}

variable "inline_manifests" {
  description = "Extra manifests applied after bootstrap"
  type = list(object({
    name    = string
    content = string
  }))
  default = []
}
