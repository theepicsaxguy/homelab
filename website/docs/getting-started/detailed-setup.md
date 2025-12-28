---
sidebar_position: 2
title: Detailed Setup Guide
description: Step by step instructions for setting up the homelab environment
---

# Detailed Setup Guide

This guide provides step-by-step instructions for setting up your homelab environment using OpenTofu and Talos Linux.

## Prerequisites

- Proxmox access with your SSH key (and `pveum` CLI installed on Proxmox)
- `opentofu` 1.6+: [install](https://opentofu.org/docs/intro/install/)
- `talosctl` 1.10+: [install](https://www.talos.dev/v1.10/talos-guides/install/talosctl/)
- `kubectl` 1.28+: [install](https://kubernetes.io/docs/tasks/tools/)
- `kustomize` 5.0+: [install](https://kubectl.docs.kubernetes.io/installation/kustomize/)
- This repository cloned locally

## Initial Setup

First, navigate to the OpenTofu directory:

```console
cd tofu
```

### Proxmox CSI Prerequisites

**Important**: The `proxmox-csi-plugin` Terraform module will create a Proxmox user and role, but it does **not** include `VM.Snapshot` permission by default.

**Note**: Do NOT use `opentofu` to manually create Proxmox users or roles. The `proxmox-csi-plugin` module uses the Proxmox Terraform provider (`telmate/proxmox`) which manages users, roles, and API tokens directly. Running `opentofu apply` would create resources that Terraform doesn't know about, causing configuration drift.

For Velero CSI backups to work, you must manually add this permission after running `tofu apply`:

```bash
# After tofu apply completes, update the CSI role with snapshot permission
pveum role mod CSI -privs "Sys.Audit VM.Audit VM.Config.Disk Datastore.Allocate Datastore.AllocateSpace Datastore.Audit VM.Snapshot"
```

See [Proxmox CSI Storage](../storage/proxmox-csi.md#csi-snapshot-permissions-required-for-velero) for more details on why this is needed and how to verify it works.

Create a `terraform.tfvars` file with your configuration:

```hcl
proxmox = {
  name         = "host3"              # Your Proxmox host name
  cluster_name = "host3"             # Your Proxmox cluster name
  endpoint     = "https://pve:8006"   # Your Proxmox API endpoint
  insecure     = false                # Set to true if using self-signed certificates
  username     = "root@pam"           # Your Proxmox username
  api_token    = "USER@pam!ID=TOKEN"  # Your Proxmox API token
}
```

Initialize the OpenTofu configuration:

```console
tofu init
```

## Configuration

Create a `terraform.tfvars` file with your specific configuration:

```hcl
proxmox = {
  name         = "proxmox-host"
  cluster_name = "homelab-cluster"
  endpoint     = "https://proxmox.example.com:8006"
  insecure     = false
  username     = "root"
  api_token    = "root@pam!token_id=your_token_secret"
}
```

## Deployment Process

Preview the changes that will be applied:

```console
tofu plan
```

Deploy the configuration to build your cluster:

```console
tofu apply
```

<!-- vale Google.Units = NO -->
After the cluster is deployed, follow the [Manual Bootstrap Guide](/docs/k8s/manual-bootstrap-guide) to initialize your Kubernetes environment.
<!-- vale Google.Units = YES -->
