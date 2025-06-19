---
sidebar_position: 2
title: Detailed Setup Guide
description: Step by step instructions for setting up the homelab environment
---

# Detailed Setup Guide

This guide provides step-by-step instructions for setting up your homelab environment using OpenTofu and Talos Linux.

## Prerequisites

- Proxmox access with your SSH key
- `opentofu` 1.6+ — [install](https://opentofu.org/docs/install/)
- `talosctl` 1.7+ — [install](https://www.talos.dev/v1.7/getting-started/installation/)
- `kubectl` 1.28+ — [install](https://kubernetes.io/docs/tasks/tools/)
- `kustomize` 5.0+ — [install](https://kubectl.docs.kubernetes.io/installation/kustomize/)
- This repository cloned locally

## Initial Setup

First, navigate to the OpenTofu directory:

```console
cd tofu
```

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

image = {
  version           = "<see https://github.com/siderolabs/talos/releases>"           # Current Talos version
  update_version    = "<see https://github.com/siderolabs/talos/releases>"          # Target Talos version for updates
  schematic         = "standard"
  platform          = "proxmox"
  arch              = "amd64"
  proxmox_datastore = "local"            # Your Proxmox datastore name
  factory_url       = "https://factory.talos.dev"
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

image = {
  version           = "<see https://github.com/siderolabs/talos/releases>"
  schematic         = "standard"
  update_version    = "<see https://github.com/siderolabs/talos/releases>"
  update_schematic  = "standard"
  platform          = "proxmox"
  arch              = "amd64"
  proxmox_datastore = "local"
  factory_url       = "https://factory.talos.dev"
}
```

## Deployment Process

Preview the changes that will be applied:

```console
tofu plan
```

First, generate the Talos image schematics:

```console
tofu apply -target=module.talos.talos_image_factory_schematic.this -target=module.talos.talos_image_factory_schematic.updated
```

Then apply the full configuration to deploy your cluster:

```console
tofu apply
```

After the cluster is deployed, follow the [Manual Bootstrap Guide](/docs/k8s/manual-bootstrap-guide) to initialize your Kubernetes environment.
