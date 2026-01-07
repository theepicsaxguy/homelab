resource "aws_s3_bucket" "tofu_remote_state" {
  bucket = var.bucket_name

  # force_destroy = true must be applied before removing bucket
  force_destroy = true

  tags = {
    Name        = "OpenTofu Remote State"
    Purpose     = "terraform-state-storage"
    Environment = "homelab"
  }
}

resource "aws_s3_bucket_versioning" "tofu_remote_state" {
  bucket = aws_s3_bucket.tofu_remote_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "tofu_remote_state" {
  bucket = aws_s3_bucket.tofu_remote_state.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
      newer_noncurrent_versions = 100
    }
  }
}

# Server-side encryption is enabled by default on Backblaze B2
# No need for explicit aws_s3_bucket_server_side_encryption_configuration
