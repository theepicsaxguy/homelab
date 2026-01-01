# Backblaze B2 Setup Prerequisites

This document outlines the steps required to set up Backblaze B2 offsite backups for your homelab disaster recovery
strategy.

## Overview

Your homelab currently backs up to TrueNAS MinIO (local only). This setup adds offsite backups to Backblaze B2 to
protect against:

- Total site loss (fire, flood, etc.)
- Rack destruction
- Ransomware attacks that could encrypt local backups
- Hardware failures affecting both cluster and NAS

## Step 1: Create Backblaze B2 Account

1. Go to [https://www.backblaze.com/b2/sign-up.html](https://www.backblaze.com/b2/sign-up.html)
2. Sign up for a Backblaze B2 account
3. Note: First 10GB is free, then $6/TB/month for storage

## Step 2: Create B2 Buckets

Create three buckets in your B2 account:

### Bucket 1: Velero Backups

- **Name**: `homelab-velero-b2`
- **Files**: Private
- **Encryption**: Server-Side Encryption (SSE-B2) enabled
- **Object Lock**: Disabled (Velero manages retention)
- **Lifecycle Rules**: None (Velero manages expiration)

### Bucket 2: PostgreSQL Backups

- **Name**: `homelab-cnpg-b2`
- **Files**: Private
- **Encryption**: Server-Side Encryption (SSE-B2) enabled
- **Object Lock**: Disabled
- **Lifecycle Rules**: None (CNPG manages retention)

### Bucket 3: OpenTofu State

- **Name**: `homelab-terraform-state-b2`
- **Files**: Private
- **Encryption**: Server-Side Encryption (SSE-B2) enabled
- **Object Lock**: Disabled
- **Lifecycle Rules**: Keep all versions (Object versioning: Enabled)

## Step 3: Create Application Keys

Create three separate Application Keys for security isolation:

### Application Key 1: Velero

1. In B2 dashboard, go to "App Keys"
2. Click "Add a New Application Key"
3. Configuration:

   - **Name of Key**: `homelab-velero-offsite`
   - **Allow access to Bucket(s)**: `homelab-velero-b2`
   - **Type of Access**: Read and Write
   - **Allow List All Bucket Names**: No
   - **File name prefix**: (leave empty)
   - **Duration (seconds)**: (leave empty for no expiration)

4. **SAVE THESE CREDENTIALS IMMEDIATELY** (shown only once):
   - `keyID`: This is your `AWS_ACCESS_KEY_ID`
   - `applicationKey`: This is your `AWS_SECRET_ACCESS_KEY`

### Application Key 2: CNPG PostgreSQL

1. Click "Add a New Application Key"
2. Configuration:

   - **Name of Key**: `homelab-cnpg-offsite`
   - **Allow access to Bucket(s)**: `homelab-cnpg-b2`
   - **Type of Access**: Read and Write
   - **Allow List All Bucket Names**: No

3. **SAVE THESE CREDENTIALS IMMEDIATELY**:
   - `keyID`: `AWS_ACCESS_KEY_ID`
   - `applicationKey`: `AWS_SECRET_ACCESS_KEY`

### Application Key 3: OpenTofu State

1. Click "Add a New Application Key"
2. Configuration:

   - **Name of Key**: `homelab-terraform-state`
   - **Allow access to Bucket(s)**: `homelab-terraform-state`
   - **Type of Access**: Read and Write
   - **Allow List All Bucket Names**: No

3. **SAVE THESE CREDENTIALS IMMEDIATELY**:
   - `keyID`: `AWS_ACCESS_KEY_ID`
   - `applicationKey`: `AWS_SECRET_ACCESS_KEY`

## Step 4: Add Credentials to Bitwarden Secrets Manager

Add the following secrets to your Bitwarden Secrets Manager (not the vault):

### Bitwarden Secrets 1: Velero B2 Credentials

Create three separate secrets in Secrets Manager:

1. **Name**: `backblaze-b2-velero-access-key-id`

   - **Value**: [keyID from Velero app key]

2. **Name**: `backblaze-b2-velero-secret-access-key`

   - **Value**: [applicationKey from Velero app key]

3. **Name**: `backblaze-b2-velero-repository-password`
   - **Value**: [Generate a strong random password, e.g., `openssl rand -base64 32`]
   - **Note**: This password encrypts Kopia backup data at rest (client-side encryption)

### Bitwarden Secrets 2: CNPG B2 Credentials

Create two separate secrets in Secrets Manager:

1. **Name**: `backblaze-b2-cnpg-access-key-id`

   - **Value**: [keyID from CNPG app key]

2. **Name**: `backblaze-b2-cnpg-secret-access-key`
   - **Value**: [applicationKey from CNPG app key]

### Bitwarden Secrets 3: OpenTofu State B2 Credentials

Create two separate secrets in Secrets Manager:

1. **Name**: `backblaze-b2-tofu-state-access-key-id`

   - **Value**: [keyID from OpenTofu app key]

2. **Name**: `backblaze-b2-tofu-state-secret-access-key`
   - **Value**: [applicationKey from OpenTofu app key]

Note: Bitwarden Secrets Manager stores each secret as a single key-value pair. Do NOT use the vault or custom fields.

## Step 6: Test Connectivity

Test that you can connect to B2 from your workstation:

```bash
# Install AWS CLI if not already installed
# macOS: brew install awscli
# Linux: apt install awscli

# Configure AWS CLI for B2 (use Velero credentials as test)
export AWS_ACCESS_KEY_ID="<your-velero-keyID>"
export AWS_SECRET_ACCESS_KEY="<your-velero-applicationKey>"

# Test listing bucket (should be empty initially)
aws s3 ls s3://homelab-velero-b2 \
  --endpoint-url https://s3.us-west-002.backblazeb2.com

# Test uploading a file
echo "test" > test.txt
aws s3 cp test.txt s3://homelab-velero-b2/test.txt \
  --endpoint-url https://s3.us-west-002.backblazeb2.com

# Test downloading the file
aws s3 cp s3://homelab-velero-b2/test.txt test-download.txt \
  --endpoint-url https://s3.us-west-002.backblazeb2.com

# Cleanup test file
aws s3 rm s3://homelab-velero-b2/test.txt \
  --endpoint-url https://s3.us-west-002.backblazeb2.com
rm test.txt test-download.txt
```

If all tests pass, you're ready to proceed with the infrastructure configuration!

## Expected Costs

Based on your current backup sizes:

**Storage (per month)**:

- Velero backups: ~50GB (estimated) = $0.30/month
- PostgreSQL backups: ~10GB (estimated) = $0.06/month
- OpenTofu state: ~1MB (estimated) = $0.00/month
- **Total Storage**: ~$0.36/month

**Download (Class B transactions)**:

- Disaster recovery download (rare): First 1GB/day free
- Large restore (100GB): ~$0.01 per 10k requests

**Estimated Monthly Cost**: $0.40 - $1.00/month (negligible)

## Security Notes

1. **Never commit B2 credentials to Git** - they are managed via Bitwarden
2. **Application Keys are scoped** - each key can only access its designated bucket
3. **Encryption at rest** - B2 server-side encryption is enabled
4. **Encryption in transit** - All connections use HTTPS
5. **Kopia encryption** - Velero uses Kopia with additional client-side encryption

## Next Steps

Once you've completed all steps above, notify the infrastructure automation that you're ready to proceed with:

1. Velero B2 configuration
2. CNPG B2 configuration
3. OpenTofu state backend migration

## Troubleshooting

### "Access Denied" errors

- Verify Application Key has correct bucket permissions
- Ensure you're using the correct endpoint URL
- Check that the bucket name matches exactly

### "Bucket does not exist"

- Verify bucket was created in the correct B2 region (us-west-000)
- Check spelling of bucket name

### External Secrets not syncing

- Verify Bitwarden item IDs are correct
- Check External Secrets Operator logs: `kubectl -n external-secrets logs -l app.kubernetes.io/name=external-secrets`
- Ensure Bitwarden token is still valid

## Reference

- B2 Endpoint: `https://s3.us-west-002.backblazeb2.com`
- B2 Region: `us-west-000`
- B2 Documentation: https://www.backblaze.com/docs/cloud-storage
- Velero AWS Plugin: https://github.com/vmware-tanzu/velero-plugin-for-aws
