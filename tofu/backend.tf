# TrueNAS MinIO Remote State Backend for OpenTofu
#
# This configuration stores OpenTofu state remotely in TrueNAS MinIO,
# providing disaster recovery capability for infrastructure state.
#
# Benefits:
# - State survives local infrastructure loss
# - State versioning enabled (can rollback via MinIO)
# - Encrypted at rest (OpenTofu AES-GCM encryption)
# - Encrypted in transit (HTTPS)
# - State locking via S3 native locking
#
# Prerequisites:
# 1. MinIO must be deployed and accessible
# 2. Create backend-config.tfvars from backend-config.tfvars.example
# 3. Configure your MinIO credentials in backend-config.tfvars
#
# Migration from local state:
# 1. Ensure you have a backup of terraform.tfstate
# 2. Create and configure backend-config.tfvars
# 3. Run: tofu init -backend-config=backend-config.tfvars -migrate-state
# 4. Confirm migration when prompted
# 5. Verify: tofu show (should display current state)
# 6. Optional: Remove local state files (they're in .gitignore):
#    rm -f terraform.tfstate terraform.tfstate.backup
#
# Rollback to local state (if needed):
# 1. Restore terraform.tfstate from backup
# 2. Comment out this entire backend block
# 3. Run: tofu init -migrate-state
#
# Usage:
# - Init:  tofu init -backend-config=backend-config.tfvars
# - Apply: tofu apply (backend config is saved after init)
# - Plan:  tofu plan (backend config is saved after init)

terraform {
  backend "s3" {
    # Static configuration - sensitive values supplied via backend-config.tfvars
    # Note: Backend blocks don't support variable interpolation

    # Required for MinIO S3 compatibility
    skip_credentials_validation = true
    skip_metadata_api_check      = true
    skip_region_validation       = true
    skip_requesting_account_id  = true
    use_path_style              = true  # MinIO uses path-style URLs
  }
}

# State locking is supported via S3 native locking (use_lockfile)
# For additional locking, enable use_lockfile = true in backend-config.tfvars
