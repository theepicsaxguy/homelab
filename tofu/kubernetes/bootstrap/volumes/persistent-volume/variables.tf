variable "volume" {
  description = "Volume configuration"
  type = object({
    name     = string
    capacity = string
  })
}
