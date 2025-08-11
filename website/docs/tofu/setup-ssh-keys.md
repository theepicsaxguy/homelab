---
sidebar_position: 4
title: Setup SSH Keys for Proxmox Nodes
description: This guide shows you how to configure SSH key authentication for several Proxmox nodes that OpenTofu can access.
---

:::info
See the information below to set up SSH key authentication.
:::

## Prerequisites

- Administrative access to all Proxmox nodes
- SSH client on your workstation
- Existing SSH key pair (or ability to create one)

---

## Step 1: Generate or locate your SSH key

### Option A: Use existing SSH key
If you already have an SSH key pair:

```shell
# Check if you have an existing key
ls -la ~/.ssh/

# Display your public key
cat ~/.ssh/id_rsa.pub
```

### Option B: Generate New SSH Key
If you need to create a new SSH key:

```shell
# Generate a new SSH key pair
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# When prompted, save to default location: ~/.ssh/id_rsa
# Optionally set a passphrase for additional security

# Display your new public key
cat ~/.ssh/id_rsa.pub
```

---

## Step 2: Add SSH Key to Each Proxmox Node

For each Proxmox node in your `terraform.tfvars` configuration, you need to add your SSH public key.

### Copy via SSH (if password auth is enabled)

If password authentication is temporarily enabled:

```shell
# Copy your public key to each Proxmox node
ssh-copy-id root@host3.pc-tips.se
ssh-copy-id root@nuc.pc-tips.se

# Replace with your actual node hostnames/IPs
```

---

## Step 3: Test SSH Access

Verify that you can connect to each Proxmox node without a password:

```shell
# Test connection to first node
ssh root@host3.pc-tips.se "hostname"

# Test connection to second node  
ssh root@nuc.pc-tips.se "hostname"
```

---

## Step 4: Configure SSH Agent (for OpenTofu)

Before running OpenTofu commands, ensure your SSH key is loaded:

```shell
# Start SSH agent and add your key
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa

# Verify key is loaded
ssh-add -l
```

:::tip
Add the SSH agent commands to your shell profile (`.bashrc`, `.zshrc`) to automatically load keys on login:

```shell
nano ~/.bashrc
```

```shell
# Add to ~/.bashrc or ~/.zshrc
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval $(ssh-agent)
  ssh-add ~/.ssh/id_rsa 2>/dev/null
fi
```

```shell
source ~/.bashrc
```
:::

---

## Step 5: Verify OpenTofu Configuration

Ensure your `terraform.tfvars` contains the correct username for SSH connections:

```hcl
proxmox = {
  host3 = {
    name         = "host3"
    cluster_name = "host3"
    endpoint     = "https://host3.pc-tips.se:8006"
    insecure     = false
    username     = "root"  # This user must have SSH key access
    api_token    = "root@pam!terraform2=..."
  }
  nuc = {
    name         = "nuc"
    cluster_name = "nuc"
    endpoint     = "https://nuc.pc-tips.se:8006"
    insecure     = false
    username     = "root"  # This user must have SSH key access  
    api_token    = "terraform@pve!terraform-token=..."
  }
}
```

---

## Troubleshooting

### SSH Connection Issues

**Problem:** `Permission denied (publickey)`
```shell
# Check SSH connection with verbose output
ssh -v root@host3.pc-tips.se

# Common solutions:
# 1. Verify public key is in ~/.ssh/authorized_keys on target node
# 2. Check file permissions (authorized_keys should be 600)
# 3. Ensure SSH agent has the key loaded (ssh-add -l)
```

**Problem:** `Host key verification failed`
```shell
# Remove old host key and try again
ssh-keygen -R host3.pc-tips.se
ssh-keygen -R nuc.pc-tips.se

# Then test connections again
```

### OpenTofu SSH Issues

**Problem:** OpenTofu fails with SSH errors
```shell
# Verify SSH agent is running and has keys
echo $SSH_AUTH_SOCK
ssh-add -l

# Reload SSH agent if needed
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa
```

**Problem:** Wrong username in configuration
- Ensure the `username` field in `terraform.tfvars` matches the user account that has SSH key access
- Most Proxmox installations use `root` by default

---

## Security Best Practices

1. **Use dedicated SSH keys** for automation (separate from your personal keys)
2. **Disable password authentication** on Proxmox nodes after SSH keys are configured
3. **Use SSH key passphrases** for additional security
4. **Regularly rotate SSH keys** (update `authorized_keys` on all nodes)
5. **Limit SSH access** to specific IP ranges if possible

### Disable Password Authentication (Optional)

After SSH keys are working, you can disable password authentication:

```shell
# On each Proxmox node, edit SSH config
nano /etc/ssh/sshd_config

# Set these values:
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Restart SSH service
systemctl restart sshd
```

:::warning
Only disable password authentication after confirming SSH key access works correctly.
:::
