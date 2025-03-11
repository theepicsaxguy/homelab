variable "volumes" {
  description = "Volume configuration"
  type = map(object({
    size = string
  }))
}
