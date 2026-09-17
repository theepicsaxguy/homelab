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

variable "network" {
  description = "Network configuration for the VM"
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

variable "cluster_domain" { type = string }

variable "matter_server_ble_url" {
  description = "WebSocket URL of the matter-server BLE proxy endpoint (ws://<host>:5580/ble)"
  type        = string
}

variable "nodes" {
  description = "BLE proxy VMs"
  type = map(object({
    host_node     = string
    ip            = string
    mac_address   = string
    vm_id         = number
    usb_host      = string
    cpu           = optional(number, 1)
    ram_dedicated = optional(number, 512)
    datastore_id  = optional(string)
  }))
}
