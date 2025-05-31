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

# Storage pool and disk owner variables have been removed as they are unused


# Node configuration is now managed through local variables in main.tf
