# Remote State Configuration with Backblaze B2

This guide explains how to configure and use Backblaze B2 for remote state storage with OpenTofu.

## Table of Contents

- [Overview](#overview)
- [Benefits](#benefits)
- [Prerequisites](#prerequisites)
- [Setup Process](#setup-process)
- [Migration](#migration)
- [Switching Between Local and Remote State](#switching-between-local-and-remote-state)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

Remote state storage provides disaster recovery and collaboration capabilities by storing your OpenTofu state file in Backblaze B2 (S3-compatible object storage) instead of locally.

This implementation uses a **two-phase bootstrap pattern**:
1. **Phase 1**: Use `tofu/state-b2/` to create the B2 bucket infrastructure
2. **Phase 2**: Configure main tofu to use the created bucket

## Benefits

- **Disaster Recovery**: State survives local infrastructure loss
- **State History**: B2 versioning enabled (can rollback to previous states)
- **Encryption**:
  - At rest: B2 server-side encryption + OpenTofu encryption
  - In transit: HTTPS/TLS
- **Cost-Effective**: Backblaze B2 pricing is competitive
- **S3 Compatibility**: Works with standard S3 tools and workflows

## Prerequisites

### 1. Backblaze B2 Account

Sign up at https://www.backblaze.com/b2/sign-up.html

### 2. Application Key

Create an application key with bucket read/write access:
1. Log into Backblaze B2 console
2. Navigate to: **App Keys** → **Add a New Application Key**
3. Configure:
   - **Name**: `opentofu-state-management`
   - **Access**: Read and Write
   - **Bucket**: All or specific bucket
4. **Save the credentials**:
   - `keyID` (used as `access_key_id`)
   - `applicationKey` (used as `secret_access_key`)
   - **IMPORTANT**: You can only view the applicationKey once!

### 3. Choose a Globally Unique Bucket Name

B2 bucket names must be globally unique. Example: `homelab-terraform-state-<your-identifier>`

## Setup Process

### Phase 1: Bootstrap B2 Bucket

1. **Navigate to the state-b2 directory**:
   ```bash
   cd tofu/state-b2/
   ```

2. **Copy and configure tfvars**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit `terraform.tfvars`** with your credentials:
   ```hcl
   b2 = {
     region            = "us-west-000"  # Or your preferred B2 region
     endpoint          = "https://s3.us-west-000.backblazeb2.com"
     access_key_id     = "your-b2-keyID"
     secret_access_key = "your-b2-applicationKey"
   }
   bucket_name           = "your-unique-bucket-name"
   encryption_passphrase = "your-secure-encryption-passphrase"
   ```

4. **Initialize and create the bucket**:
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

5. **Verify bucket creation**:
   ```bash
   tofu output
   ```

6. **Migrate state-b2 to remote storage** (optional but recommended):
   - Uncomment the backend block in `providers.tofu` (lines 27-41)
   - Run: `tofu init -migrate-state`
   - Confirm migration
   - Remove local state: `rm -f terraform.tfstate*` (optional)

### Phase 2: Configure Main Tofu for Remote State

1. **Navigate to main tofu directory**:
   ```bash
   cd /path/to/homelab/tofu/
   ```

2. **Edit `terraform.tfvars`** and add:
   ```hcl
   # Remote State Configuration
   backend_bucket_name       = "your-unique-bucket-name"
   backend_state_key         = "proxmox/terraform.tfstate"
   backend_region            = "us-west-000"
   backend_endpoint          = "https://s3.us-west-000.backblazeb2.com"
   backend_access_key_id     = "your-b2-keyID"
   backend_secret_access_key = "your-b2-applicationKey"
   encryption_passphrase     = "your-secure-encryption-passphrase"
   ```

3. **Backup local state** (if exists):
   ```bash
   cp terraform.tfstate terraform.tfstate.backup-$(date +%Y%m%d-%H%M%S)
   ```

4. **Migrate to remote state**:
   ```bash
   tofu init -migrate-state
   ```

5. **Verify migration**:
   ```bash
   tofu state list
   ```

6. **Optional cleanup**:
   ```bash
   # Keep backups, remove active local state
   rm -f terraform.tfstate
   ```

## Migration

### From Local to Remote State

See [Phase 2: Configure Main Tofu for Remote State](#phase-2-configure-main-tofu-for-remote-state) above.

### From Remote to Local State

1. **Backup current state**:
   ```bash
   tofu state pull > terraform.tfstate.backup-$(date +%Y%m%d-%H%M%S)
   ```

2. **Comment out the backend block** in `backend.tf`:
   ```hcl
   # terraform {
   #   backend "s3" {
   #     ...
   #   }
   # }
   ```

3. **Migrate to local**:
   ```bash
   tofu init -migrate-state
   ```

4. **Verify**:
   ```bash
   ls -la terraform.tfstate
   tofu state list
   ```

## Switching Between Local and Remote State

### Enable Remote State
1. Ensure backend variables are configured in `terraform.tfvars`
2. Uncomment backend block in `backend.tf`
3. Run: `tofu init -migrate-state`

### Disable Remote State
1. Comment out backend block in `backend.tf`
2. Run: `tofu init -migrate-state`

**Note**: Always backup state before switching!

## Security Best Practices

### 1. Secure Credentials

- **Never commit** `terraform.tfvars` to git (it's in `.gitignore`)
- **Use strong passphrases** for `encryption_passphrase`
- **Rotate B2 keys** periodically
- **Limit B2 key permissions** to specific bucket only

### 2. Encryption

OpenTofu encrypts state using:
- **Algorithm**: pbkdf2 (key derivation) + AES-GCM (encryption)
- **Local encryption**: Before state is sent to B2
- **B2 encryption**: Server-side encryption at rest (enabled by default)

### 3. State File Security

- State files contain **sensitive information** (passwords, keys, IPs)
- **Encryption passphrase** is required to decrypt state
- **Store passphrase securely** (password manager, vault)
- **Different passphrase** for prod vs dev environments

### 4. Access Control

- **Limit B2 key access** to state bucket only
- **Use separate keys** for different environments
- **Audit B2 access logs** regularly

### 5. Backup Strategy

- **B2 versioning**: Keeps 100 previous versions for 90 days
- **Local backups**: Before major changes
- **Test restores**: Verify backups work

## Troubleshooting

### Error: "bucket already exists"

**Cause**: Bucket name is not globally unique across all B2 users.

**Solution**: Choose a different bucket name in `terraform.tfvars`.

### Error: "Access Denied"

**Cause**: Invalid or insufficient B2 credentials.

**Solutions**:
- Verify `access_key_id` and `secret_access_key` are correct
- Ensure key has read/write permissions to buckets
- Check key hasn't been deleted or revoked in B2 console

### Error: "Invalid encryption passphrase"

**Cause**: Incorrect or missing encryption passphrase.

**Solutions**:
- Verify `encryption_passphrase` matches the one used to create/encrypt state
- Check for typos in passphrase
- Ensure passphrase is set in `terraform.tfvars`

### State migration fails

**Symptoms**: `tofu init -migrate-state` errors

**Solutions**:
1. Verify backend configuration variables match:
   - `backend_bucket_name` matches created bucket
   - `backend_endpoint` and `backend_region` are correct
   - Credentials are valid
2. Check B2 bucket exists: log into B2 console
3. Verify local state exists before migration
4. Check OpenTofu/Terraform version compatibility

### Cannot access remote state

**Symptoms**: `tofu plan` fails to read state

**Solutions**:
- Verify B2 credentials are correct
- Check `encryption_passphrase` matches
- Ensure B2 bucket exists and is accessible
- Verify network connectivity to B2

### State lock errors

**Note**: B2 S3-compatible API **does not support state locking**.

For single-operator homelab, this is acceptable. For multi-user scenarios:
- Coordinate manually (communicate before running `tofu apply`)
- Consider Terraform Cloud (supports state locking)
- Use DynamoDB with AWS S3 (supports state locking)

## State Versioning

B2 bucket is configured with versioning:
- **Retention**: 90 days for noncurrent versions
- **Limit**: Keep 100 newer versions
- **Rollback**: Possible via B2 console or API

### Rollback to Previous State Version

1. **List versions** in B2 console or CLI
2. **Download desired version**:
   ```bash
   # Using B2 CLI
   b2 download-file-by-id <fileId> terraform.tfstate.restored
   ```
3. **Restore locally**:
   ```bash
   cp terraform.tfstate.restored terraform.tfstate
   ```
4. **Verify state**:
   ```bash
   tofu state list
   ```

## Cost Considerations

Backblaze B2 pricing (as of 2025):
- **Storage**: $0.006/GB/month
- **Downloads**: $0.01/GB
- **API calls**: Included (Class C)

Typical homelab state file: ~500KB - 1MB
- **Monthly cost**: <$0.01/month for storage
- **Downloads**: Minimal (only on `tofu` operations)

## References

- [Backblaze B2 Documentation](https://www.backblaze.com/docs/cloud-storage)
- [B2 S3 Compatible API](https://www.backblaze.com/docs/cloud-storage-s3-compatible-api)
- [OpenTofu S3 Backend](https://opentofu.org/docs/language/settings/backends/s3/)
- [OpenTofu State Encryption](https://opentofu.org/docs/language/state/encryption/)
- [Bootstrap Module: tofu/state-b2/](https://github.com/theepicsaxguy/homelab/tree/main/tofu/state-b2)

## Support

For issues or questions:
1. Check this documentation and [tofu/state-b2/README.md](https://github.com/theepicsaxguy/homelab/tree/main/tofu/state-b2/README.md)
2. Review OpenTofu logs: `TF_LOG=DEBUG tofu plan`
3. Check B2 console for bucket status and access logs
4. Verify credentials and configuration
