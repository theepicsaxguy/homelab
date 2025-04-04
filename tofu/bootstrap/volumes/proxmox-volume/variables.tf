variable "volume" {
  type = object({
    name = string
    node = string
    size = string
    storage = optional(string, "velocity")
    vmid = optional(number, 9999)
    format = optional(string, "raw")
  })
}
