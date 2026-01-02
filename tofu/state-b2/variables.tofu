variable "encryption_passphrase" {
  description = "Encryption passphrase for Tofu state encryption"
  type        = string
  sensitive   = true
}

variable "b2" {
  description = "Backblaze B2 configuration for S3-compatible state storage"
  type = object({
    region            = string
    endpoint          = string
    access_key_id     = string
    secret_access_key = string
  })
  sensitive = true
}

variable "bucket_name" {
  description = "Globally unique name for B2 bucket"
  type        = string
}

variable "state_key" {
  description = "State file path in B2 bucket"
  type        = string
  default     = "state-b2/terraform.tfstate"
}
