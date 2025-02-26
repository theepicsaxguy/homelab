variable "volume" {
  description = "Volume configuration"
  type = object({
    name               = string
    capacity           = string
    access_modes       = optional(list(string), ["ReadWriteOnce"])
    storage_class_name = optional(string, "local-path")
    mount_options      = optional(list(string), [])
    volume_mode        = optional(string, "Filesystem")
    driver            = optional(string, "local.csi.k8s.io")
    fs_type           = optional(string, "ext4")
    volume_handle     = optional(string)
    cache             = optional(string, "none")
    ssd               = optional(bool, false)
    storage           = optional(string, "local")
  })
}
