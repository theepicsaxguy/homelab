# # Backblaze B2 Remote State Backend for OpenTofu
# #
# # This configuration stores OpenTofu state remotely in Backblaze B2,
# # providing disaster recovery capability for infrastructure state.
# #
# # Benefits:
# # - State survives local infrastructure loss
# # - State versioning enabled (can rollback)
# # - Encrypted at rest (B2 SSE)
# # - Encrypted in transit (HTTPS)
# #
# # Prerequisites:
# # 1. Complete BACKBLAZE_B2_SETUP.md
# # 2. Create bucket: homelab-terraform-state
# # 3. Set environment variables:
# #    export AWS_ACCESS_KEY_ID="<B2 keyID>"
# #    export AWS_SECRET_ACCESS_KEY="<B2 applicationKey>"
# #
# # Migration from local state:
# # 1. Ensure you have a backup of terraform.tfstate
# # 2. Run: tofu init -migrate-state
# # 3. Confirm the migration when prompted
# # 4. Verify: tofu show (should display current state)
# # 5. Remove local state files (they're in .gitignore already):
# #    rm -f terraform.tfstate terraform.tfstate.backup
# #
# # Rollback (if needed):
# # 1. Restore terraform.tfstate from backup
# # 2. Comment out this entire backend block
# # 3. Run: tofu init -migrate-state

# terraform {
#   backend "s3" {
#     # B2 Bucket configuration
#     bucket = "homelab-terraform-state"
#     key    = "proxmox/terraform.tfstate"
#     region = "us-west-000"

#     # Backblaze B2 S3-compatible endpoint
#     endpoint = "https://s3.us-west-000.backblazeb2.com"

#     # Required for B2 compatibility
#     skip_credentials_validation = true
#     skip_metadata_api_check     = true
#     skip_region_validation      = true
#     skip_requesting_account_id  = true
#     use_path_style              = false  # B2 uses virtual-hosted style

#     # Credentials from environment variables:
#     # AWS_ACCESS_KEY_ID
#     # AWS_SECRET_ACCESS_KEY
#   }
# }

# # State locking is not supported with B2 S3-compatible API
# # For multi-user scenarios, implement external locking or use:
# # - Terraform Cloud
# # - Consul
# # - DynamoDB (with real AWS)
# #
# # For single-operator homelab, this is acceptable.
