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
  description = "Controls sequential node upgrades. Set enabled=true and specify index to upgrade a specific node."
  type = object({
    enabled = bool
    index   = number
  })
  default = {
    enabled = false
    index   = -1
  }

  validation {
    condition     = var.upgrade_control.index >= -1
    error_message = "Index must be -1 (disabled) or a valid node position (0+)."
  }
}

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

variable "nodes_config" {
  description = "Per-node configuration map"
  type = map(object({
    host_node     = optional(string) #  "The Proxmox node to schedule this VM on. If omitted, defaults to the `name` specified in the `var.proxmox` provider configuration."
    machine_type  = string
    ip            = string
    mac_address   = optional(string)
    vm_id         = optional(number)
    is_external   = optional(bool, false)
    ram_dedicated = optional(number)
    igpu          = optional(bool)
    disks = optional(map(object({
      device      = optional(string)
      size        = optional(string)
      type        = optional(string)
      mountpoint  = optional(string)
      unit_number = optional(number)
    }))),
    gpu_devices = optional(list(string), []),
    #   map keyed by the same BDF strings you list in `gpu_devices`
    gpu_device_meta = optional(
      map(object({
        id           = string
        subsystem_id = string
        iommu_group  = number
      })),
      {}
    ),
    gpu_node_exclusive          = optional(bool, true)
    datastore_id                = optional(string),
    description                 = optional(string),
    tags                        = optional(list(string)),
    on_boot                     = optional(bool),
    machine                     = optional(string),
    scsi_hardware               = optional(string),
    bios                        = optional(string),
    agent_enabled               = optional(bool),
    cpu_type                    = optional(string),
    network_bridge              = optional(string),
    network_vlan_id             = optional(number),
    root_disk_interface         = optional(string),
    root_disk_iothread          = optional(bool),
    root_disk_cache             = optional(string),
    root_disk_discard           = optional(string),
    root_disk_ssd               = optional(bool),
    root_disk_file_format       = optional(string),
    root_disk_size              = optional(number),
    additional_disk_iothread    = optional(bool),
    additional_disk_cache       = optional(string),
    additional_disk_discard     = optional(string),
    additional_disk_ssd         = optional(bool),
    additional_disk_file_format = optional(string),
    boot_order                  = optional(list(string)),
    os_type                     = optional(string),
    dns_servers                 = optional(list(string))
  }))

  validation {
    condition = alltrue([
      for n in values(var.nodes_config) :
      contains(["worker", "controlplane"], n.machine_type)
    ])
    error_message = "machine_type must be worker or controlplane."
  }

  validation {
    condition = alltrue([
      for name, node in var.nodes_config :
      !coalesce(node.igpu, false) || (
        coalesce(node.igpu, false) &&
        length(lookup(node, "gpu_devices", [])) > 0
      )
    ])
    error_message = "If 'igpu' is true, 'gpu_devices' must contain at least one PCI address."
  }
  validation {
    condition = alltrue(flatten([
      for _, n in var.nodes_config :
      [
        for bdf in lookup(n, "gpu_devices", []) :
        contains(keys(lookup(n, "gpu_device_meta", {})), bdf)
      ]
    ]))
    error_message = "Every BDF in gpu_devices must exist in gpu_device_meta."
  }

  validation {
    condition = alltrue([
      for n in values(var.nodes_config) :
      lookup(n, "is_external", false) ? n.vm_id == null : n.vm_id != null
    ])
    error_message = "External nodes must not have vm_id; internal nodes must have vm_id."
  }

  validation {
    condition     = length(distinct([for n in values(var.nodes_config) : n.vm_id if !lookup(n, "is_external", false) && n.vm_id != null])) == length([for n in values(var.nodes_config) : n if !lookup(n, "is_external", false)])
    error_message = "VM IDs must be unique among internal nodes."
  }

  validation {
    condition = alltrue([
      for n in values(var.nodes_config) :
      lookup(n, "is_external", false) ? n.mac_address == null : n.mac_address != null
    ])
    error_message = "External nodes must not have mac_address; internal nodes must have mac_address."
  }
}

variable "proxmox_datastore" {
  description = "Default Proxmox datastore for all nodes"
  type        = string
  default     = "velocity"
}

variable "cluster_name" {
  description = "The name of the Talos cluster."
  type        = string
}

variable "cluster_domain" {
  description = "The domain for the cluster (e.g., kube.example.com)."
  type        = string
}

variable "network" {
  description = "Network configuration for the cluster."
  type = object({
    gateway     = string
    vip         = string
    api_lb_vip  = string
    cidr_prefix = number
    dns_servers = list(string)
    bridge      = string
    vlan_id     = number
  })
}

variable "proxmox_cluster" {
  description = "The name of the Proxmox cluster."
  type        = string
}

variable "versions" {
  description = "Software versions for the cluster components."
  type = object({
    talos      = string
    kubernetes = string
  })
}

variable "oidc" {
  description = "Optional OIDC provider configuration for Kubernetes API server."
  type = object({
    issuer_url = string
    client_id  = string
  })
  default = null # Make it optional
}

variable "lb_nodes" {
  description = "Load balancer VMs"
  type = map(object({
    host_node     = string
    ip            = string
    mac_address   = string
    vm_id         = number
    cpu           = optional(number)
    ram_dedicated = optional(number)
    datastore_id  = optional(string)
  }))
}

variable "auth_pass" {
  description = "Password for Keepalived auth"
  type        = string
  sensitive   = true
}

variable "lb_store" {
  description = "datastore for loadbalancers"
  type        = string
}
