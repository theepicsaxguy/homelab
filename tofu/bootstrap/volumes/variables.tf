variable "proxmox_api" {
  type = object({
    endpoint     = string
    insecure     = bool
    cluster_name = string
  })
}

variable "volumes" {
  type = map(
    object({
      node = string
      size = string
      storage = optional(string, "rpool2")
      vmid = optional(number, 9999)
      format = optional(string, "raw")
    })
  )
}
