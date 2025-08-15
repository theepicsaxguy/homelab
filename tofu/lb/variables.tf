variable "proxmox_datastore" { type = string }

variable "proxmox" {
  type = object({
    endpoint  = string
    insecure  = bool
    username  = string
    api_token = string
    name      = string
  })
  sensitive = true
}

variable "cluster_domain" { type = string }

variable "network" {
  description = "Extend network object with api_lb_vip"
  type = object({
    gateway     = string
    vip         = string
    cidr_prefix = number
    dns_servers = list(string)
    bridge      = string
    vlan_id     = number
    api_lb_vip  = string
  })
}

variable "control_plane_ips" {
  description = "Control plane node IPs"
  type        = list(string)
}

variable "lb_nodes" {
  description = "Load balancer VMs"
  type = map(object({
    host_node     = string
    ip            = string
    mac_address   = string
    vm_id         = number
    cpu           = optional(number, 2)
    ram_dedicated = optional(number, 2048)
    datastore_id  = optional(string)
  }))
}

variable "auth_pass" {
  description = "Password for Keepalived auth"
  type        = string
  sensitive   = true
}


variable "lb_store" {
  description = "Datastore for load balancers"
  type        = string
  default     = "rpool2"
}
