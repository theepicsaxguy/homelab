---
title: Provision Kubernetes with OpenTofu and Talos
---

# Overview

This guide explains how we use OpenTofu to create a Kubernetes cluster running Talos OS on Proxmox VMs. This setup creates an immutable, API-managed environment.

# File Structure

```
/tofu/
├── main.tf           # Main configuration and node definitions
├── variables.tf      # Input variables
├── output.tf        # Generated outputs (kubeconfig, etc.)
├── providers.tf     # Provider configs (Proxmox, Talos)
├── upgrade-k8s.sh   # Kubernetes upgrade helper
└── talos/           # Talos cluster module
    ├── config.tf    # Machine configs and bootstrap
    ├── image.tf     # OS image management
    ├── virtual-machines.tf  # Proxmox VM definitions
    ├── machine-config/     # Config templates
    └── inline-manifests/   # Core component YAMLs
```

# Core Components

## Proxmox Provider

We use `bpg/proxmox` to manage VMs declaratively. This enables:

- Version-controlled infrastructure
- Automated deployments
- Easy cluster rebuilds

## Talos OS

Talos is our node OS because it offers:

- Minimal attack surface
- Atomic upgrades
- API-driven management
- Kubernetes-specific design

## VM Configuration

### Node Specs

Define nodes in `/tofu/main.tf` with:

```hcl
module "talos" {
  nodes = {
    "node1" = {
      host_node    = "proxmox1"
      machine_type = "controlplane"
      ip           = "10.0.0.1" # Example IP
      cpu          = 4
      ram_dedicated = 8192
      disks = {
        # Example: a primary disk for the OS (often handled by the image cloning)
        # and an additional disk for Longhorn.
        # The exact structure depends on your module's variables.tf.
        # This example assumes a structure like the one found in the repository:
        longhorn = { # Key for the disk, e.g., 'longhorn' or 'data'
          device     = "/dev/sdb" # Or another available device
          size       = "180G"
          type       = "scsi"     # Or 'virtio', 'sata'
          mountpoint = "/var/lib/longhorn" # If applicable for Talos config
        }
        # os_disk = { ... } # If explicitly defining the OS disk
      }
    }
  }
}
```

### Custom Images

- Built via Talos Image Factory
- Includes core extensions:
  - QEMU guest agent
  - iSCSI tools
- Automatically downloaded to Proxmox

## Machine Configuration

### Template System

- Uses YAML templates for node configs
- Injects per-node settings:
  - Hostname
  - IP address
  - Cluster details

### Core Services

We embed essential services in the Talos config:

- Cilium (CNI)
- CoreDNS
- ConfigMaps for service configuration

# Deployment Process

1. OpenTofu reads configurations
2. Downloads Talos images
3. Creates Proxmox VMs
4. Applies node configs
5. Bootstraps first control plane
6. Generates kubeconfig
7. Verifies cluster health

# Maintenance Tasks

## Version Upgrades

1. Update versions in `main.tf` or related `tfvars` files. Note that Talos versions might be specified in multiple places:
   - For the Talos image factory (e.g., `module "talos" { image = { version = "vX.Y.Z" } }`)
   - For the machine configurations and cluster secrets (e.g., `module "talos" { cluster = { talos_version = "vX.Y.Z" } }`)
   - Kubernetes version (e.g., `module "talos" { cluster = { kubernetes_version = "vA.B.C" } }`)

   Example snippet from `main.tf` (actual structure may vary based on module inputs):
   ```hcl
   module "talos" {
     # ...
     image = {
       version = "v1.9.5" # Target Talos version for OS images
       # ...
     }
     cluster = {
       talos_version      = "v1.9.5" # Target Talos version for machine configs
       kubernetes_version = "v1.29.3"  # Target Kubernetes version
       # ...
     }
     # ...
   }
   ```

2. Set `update = true` for affected nodes if your OpenTofu module supports this flag for triggering upgrades. Otherwise, `opentofu apply` will handle changes to version properties.

3. Run:

   ```bash
   opentofu apply
   ```

## Node Management

### Add/Remove Nodes

1. Modify `nodes` in `main.tf`
2. Run `opentofu apply`

### Change Resources

1. Update node specs in `main.tf`
2. Run `opentofu apply`

> Note: Resource changes may require VM restarts

# Outputs

After deployment, OpenTofu provides:

- Kubernetes config (kubeconfig)
- Talos API config
- Cluster health status

These enable immediate cluster management.
