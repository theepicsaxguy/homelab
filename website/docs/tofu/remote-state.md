# Remote State Configuration with TrueNAS MinIO

This guide explains how to configure and use TrueNAS MinIO for remote state storage with OpenTofu.

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

Remote state storage provides disaster recovery and collaboration capabilities by storing your OpenTofu state file in TrueNAS MinIO (S3-compatible object storage) instead of locally.

This implementation uses **partial backend configuration**:
1. Static backend settings are defined in `backend.tf`
2. Sensitive credentials are stored in `backend-config.tfvars` (gitignored)
3. Backend is initialized using: `tofu init -backend-config=backend-config.tfvars`

## Benefits

- **Disaster Recovery**: State survives local infrastructure loss
- **State History**: MinIO versioning enabled (can rollback to previous states)
- **Encryption**:
  - In transit: HTTPS/TLS
- **Self-Hosted**: TrueNAS MinIO (no external S3 dependency)
- **State Locking**: S3 native locking prevents concurrent modifications
- **Cost-Effective**: No external cloud storage costs
- **S3 Compatibility**: Works with standard S3 tools and workflows
- **Security**: Credentials stored in gitignored `backend-config.tfvars`

## Prerequisites

### 1. TrueNAS MinIO Deployment

MinIO must be deployed and accessible. Verify with:
```bash
kubectl get secret longhorn-minio-credentials -n litellm -o yaml
```

Expected output includes:
- `AWS_ACCESS_KEY_ID`: MinIO access key
- `AWS_SECRET_ACCESS_KEY`: MinIO secret key
- `AWS_ENDPOINTS`: MinIO endpoint URL

### 2. Generate Encryption Passphrase

Generate a secure passphrase for state encryption (minimum 16 characters, recommended 32+):
```bash
openssl rand -base64 32
```

Store this passphrase securely in your password manager. This will go in `terraform.tfvars`.

### 3. Choose Bucket Name

Bucket names must be unique within your MinIO instance. Example: `homelab-terraform-state`

## Setup Process

### Configure Main Tofu for MinIO Remote State

1. **Navigate to main tofu directory**:
   ```bash
   cd /path/to/homelab/tofu/
   ```

2. **Create `backend-config.tfvars`** from the example:
   ```bash
   cp backend-config.tfvars.example backend-config.tfvars
   ```

3. **Edit `backend-config.tfvars`** with your MinIO credentials:
   ```hcl
   # S3-compatible bucket configuration
   bucket = "homelab-terraform-state"
   key    = "proxmox/terraform.tfstate"
   region = "us-east-1"  # Arbitrary for MinIO, validation is skipped

   # MinIO endpoint (your TrueNAS MinIO URL)
   endpoint = "https://truenas.yourdomain.com:9000"

   # MinIO credentials (obtain from TrueNAS MinIO console)
   access_key = "YOUR_MINIO_ACCESS_KEY"
   secret_key = "YOUR_MINIO_SECRET_KEY"
   ```

   **Note**: `backend-config.tfvars` is gitignored to protect your credentials.

4. **Backup local state** (if exists):
   ```bash
   cp terraform.tfstate terraform.tfstate.backup.before-minio-migration
   ```

5. **Migrate to MinIO remote state**:
   ```bash
   tofu init -backend-config=backend-config.tfvars -migrate-state
   ```

   When prompted, confirm migration by typing: `yes`

6. **Verify migration**:
   ```bash
   tofu state list
   tofu show
   ```

7. **Optional cleanup** (after successful verification):
   ```bash
   # Keep backups, remove active local state
   rm -f terraform.tfstate
   ```

## Migration

### From Local to MinIO Remote State

See [Configure Main Tofu for MinIO Remote State](#configure-main-tofu-for-minio-remote-state) above.

### From MinIO Remote to Local State

1. **Backup current state**:
   ```bash
   tofu state pull > terraform.tfstate.backup-$(date +%Y%m%d-%H%M%S)
   ```

2. **Comment out backend block** in `backend.tf`:
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

### Enable MinIO Remote State
1. Ensure `backend-config.tfvars` is configured with your credentials
2. Uncomment backend block in `backend.tf` (if commented)
3. Run: `tofu init -backend-config=backend-config.tfvars -migrate-state`

### Disable MinIO Remote State
1. Comment out backend block in `backend.tf`
2. Run: `tofu init -migrate-state`

**Note**: Always backup state before switching!

## Security Best Practices

### 1. Secure Credentials

- **Never commit** `terraform.tfvars` or `backend-config.tfvars` to git (they're in `.gitignore`)
- **Use strong passphrases** for `encryption_passphrase` in `terraform.tfvars` (minimum 16 chars)
- **Rotate MinIO keys** periodically via TrueNAS console and update `backend-config.tfvars`
- **Limit MinIO key permissions** to specific bucket only

### 2. Encryption

OpenTofu encrypts state using:
- **Algorithm**: pbkdf2 (key derivation, 600k iterations) + AES-GCM (encryption)
- **Configuration**: Set `encryption_passphrase` in `terraform.tfvars`
- **Key requirement**: Same passphrase must be used for all future operations

### 3. State File Security

- State files contain **sensitive information** (passwords, keys, IPs)
- **Encryption passphrase** (in `terraform.tfvars`) is required to decrypt state
- **Store passphrase securely** (password manager, vault)
- **Different passphrase** for prod vs dev environments

### 4. Access Control

- **Limit MinIO key access** to state bucket only
- **Use separate keys** for different environments
- **Audit MinIO access logs** via TrueNAS console

### 5. Backup Strategy

- **MinIO versioning**: Configure bucket versioning for state rollback
- **Local backups**: Before major changes
- **Test restores**: Verify backups work

## Troubleshooting

### Error: "bucket already exists"

**Cause**: Bucket name conflict in MinIO.

**Solution**: MinIO will use existing bucket automatically. No action required.

### Error: "Access Denied"

**Cause**: Invalid or insufficient MinIO credentials.

**Solutions**:
- Verify `access_key` and `secret_key` in `backend-config.tfvars` are correct
- Ensure key has read/write permissions to buckets
- Check key hasn't been deleted or revoked in MinIO console
- Re-run `tofu init -backend-config=backend-config.tfvars` after fixing credentials

### Error: "Invalid encryption passphrase"

**Cause**: Incorrect or missing encryption passphrase.

**Solutions**:
- Verify `encryption_passphrase` in `terraform.tfvars` matches one used to create/encrypt state
- Check for typos in passphrase
- Ensure passphrase is set in `terraform.tfvars`

### Error: "Backend config contains sensitive values"

**Cause**: Attempting to use variables in backend block or sensitive values in backend.tf.

**Solutions**:
- Ensure you're using `backend-config.tfvars` for credentials, not `backend.tf`
- Run `tofu init -backend-config=backend-config.tfvars` to properly configure backend
- Verify `backend.tf` doesn't contain hardcoded credentials

### State migration fails

**Symptoms**: `tofu init -migrate-state` errors

**Solutions**:
1. Verify backend configuration in `backend-config.tfvars`:
   - `bucket` matches desired bucket name
   - `endpoint` URL is correct and accessible
   - `access_key` and `secret_key` are valid
2. Check MinIO connectivity: `curl -k https://truenas.yourdomain.com:9000/minio/health/live`
3. Verify local state exists before migration
4. Ensure you're using: `tofu init -backend-config=backend-config.tfvars -migrate-state`

### Cannot access remote state

**Symptoms**: `tofu plan` fails to read state

**Solutions**:
- Verify MinIO credentials in `backend-config.tfvars` are correct
- Check `encryption_passphrase` in `terraform.tfvars` matches
- Ensure MinIO bucket exists and is accessible
- Verify network connectivity to MinIO
- Re-initialize if needed: `tofu init -backend-config=backend-config.tfvars -reconfigure`

### State lock errors

**Note**: MinIO S3-compatible API supports state locking via native S3 locking.

If lock errors occur:
1. Check for other `tofu apply` processes running
2. Verify no concurrent operators
3. Force unlock (rare): `tofu force-unlock <LOCK_ID>` (use with caution)

## State Versioning

MinIO bucket versioning enables state rollback:

### Enable Bucket Versioning

1. Access MinIO console: `https://truenas.peekoff.com:9001`
2. Navigate to: **Buckets** → Select bucket → **Versioning**
3. Enable versioning

### Rollback to Previous State Version

1. **List versions** in MinIO console
2. **Download desired version**
3. **Restore locally**:
   ```bash
   cp terraform.tfstate.restored terraform.tfstate
   ```
4. **Verify state**:
   ```bash
   tofu state list
   ```

## Cost Considerations

TrueNAS MinIO (self-hosted):
- **Storage**: No direct cost (uses TrueNAS storage)
- **Network**: Local network traffic only
- **Maintenance**: TrueNAS maintenance overhead
- **Backup**: External backup strategy required for MinIO bucket

## References

- [TrueNAS MinIO Documentation](https://www.truenas.com/docs/scale/24.04/scaletutorials/apps/communityapps/minioapp/)
- [OpenTofu S3 Backend](https://opentofu.org/docs/language/settings/backends/s3/)
- [OpenTofu State Encryption](https://opentofu.org/docs/language/state/encryption/)
- [OpenTofu Dynamic Backends](https://opentofu.org/docs/language/settings/backends/configuration/)

## Support

For issues or questions:
1. Review OpenTofu logs: `TF_LOG=DEBUG tofu plan`
2. Check MinIO console for bucket status and access logs
3. Verify credentials and configuration
4. Test MinIO connectivity: `curl https://truenas.peekoff.com:9000/minio/health/live`
