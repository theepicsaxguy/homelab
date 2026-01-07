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

First, set up Proxmox API access for OpenTofu. Follow the [Setup API Key for Proxmox](/docs/tofu/setup-apikey) guide to create the API token.

Then navigate to the OpenTofu directory:

```console
cd tofu
```

Create a `terraform.tfvars` file with your configuration:

```hcl
# Proxmox connection
proxmox = {
  name         = "proxmox-host"        # Your Proxmox host name
  cluster_name = "homelab-cluster"     # Your Proxmox cluster name
  endpoint     = "https://pve:8006"    # Your Proxmox API endpoint
  insecure     = false                 # Set to true if using self-signed certificates
  username     = "root@pam"            # Your Proxmox username
  api_token    = "USER@pam!ID=TOKEN"   # Your Proxmox API token
}

# Cluster configuration
cluster_name          = "homelab"
cluster_domain        = "cluster.local"
external_api_endpoint = "api.example.com"  # Optional: external API endpoint for kubectl access

# Network configuration
network = {
  gateway     = "10.0.0.1"
  vip         = "10.0.0.10"
  api_lb_vip  = "10.0.0.9"
  cidr_prefix = 24
  dns_servers = ["10.0.0.1"]
  bridge      = "vmbr0"
  vlan_id     = 0
}

# Software versions
versions = {
  talos      = "v1.11.5"
  kubernetes = "1.34.3"
}

# Bootstrap secrets for automatic cluster configuration
bitwarden_token = "your_bitwarden_access_token_here"  # Bitwarden Secrets Manager API token for External Secrets Operator
```

Refer to `config.auto.tfvars` for a complete example with all available options.

Initialize the OpenTofu configuration:

```console
tofu init
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
The cluster bootstraps automatically after deployment. Cert Manager, External Secrets Operator, ArgoCD, and all ApplicationSets are installed via OpenTofu without manual intervention.

If automatic bootstrap fails, follow the [Manual Bootstrap Guide](/docs/k8s/manual-bootstrap-guide) for disaster recovery.
<!-- vale Google.Units = YES -->
