variable "bucket_name" {
  description = "Globally unique name for the B2 bucket"
  type        = string
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
