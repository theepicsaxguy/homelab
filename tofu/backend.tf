# Backblaze B2 Remote State Backend for OpenTofu
#
# This configuration stores OpenTofu state remotely in Backblaze B2,
# providing disaster recovery capability for infrastructure state.
#
# Benefits:
# - State survives local infrastructure loss
# - State versioning enabled (can rollback)
# - Encrypted at rest (B2 SSE + OpenTofu encryption)
# - Encrypted in transit (HTTPS)
#
# Prerequisites:
# 1. Bootstrap the B2 bucket using tofu/state-b2/
#    See: website/docs/tofu/remote-state.md for detailed instructions
# 2. Configure backend variables in terraform.tfvars:
#    - backend_bucket_name
#    - backend_state_key
#    - backend_region
#    - backend_endpoint
#    - backend_access_key_id (sensitive)
#    - backend_secret_access_key (sensitive)
#    - encryption_passphrase (sensitive)
#
# Migration from local state:
# 1. Ensure you have a backup of terraform.tfstate
# 2. Set backend variables in terraform.tfvars
# 3. Run: tofu init -migrate-state
# 4. Confirm the migration when prompted
# 5. Verify: tofu show (should display current state)
# 6. Optional: Remove local state files (they're in .gitignore):
#    rm -f terraform.tfstate terraform.tfstate.backup
#
# Rollback to local state (if needed):
# 1. Restore terraform.tfstate from backup
# 2. Comment out this entire backend block
# 3. Run: tofu init -migrate-state

terraform {
  backend "s3" {
    # B2 Bucket configuration (configurable via variables)
    bucket     = var.backend_bucket_name
    key        = var.backend_state_key
    region     = var.backend_region
    endpoint   = var.backend_endpoint
    access_key = var.backend_access_key_id
    secret_key = var.backend_secret_access_key

    # Required for B2 S3 compatibility
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = false # B2 uses virtual-hosted style
  }
}

# State locking is not supported with B2 S3-compatible API
# For multi-user scenarios, implement external locking or use:
# - Terraform Cloud
# - Consul
# - DynamoDB (with real AWS)
#
# For single-operator homelab, this is acceptable.
