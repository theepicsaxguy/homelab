---
title: Provision Kubernetes with OpenTofu and Talos
---

# Kubernetes Provisioning with OpenTofu

This guide explains our infrastructure provisioning using OpenTofu to create a production-grade Kubernetes cluster running Talos OS on Proxmox## Deployment Process

Before you begin deployment, ensure your SSH key is loaded:

```bash
eval $(ssh-agent) && ssh-add ~/.ssh/id_rsa
## Infrastructure Overview

### Node Architecture

```yaml
Control Plane:
  count: 3
  type: 'talos'
  features:
    - API server (HA)
    - etcd cluster
    - controller-manager
    - scheduler

Worker Nodes:
  count: 2+
  type: 'talos'
  features:
    - container runtime
    - cilium networking
    - CSI support
    - GPU support (optional)
```

### Network Architecture

| Network     | CIDR           | Purpose                    |
|-------------|---------------|----------------------------|
| Node        | 10.25.150.0/24| Kubernetes node networking |
| Pod         | 10.25.0.0/16  | Container networking       |
| Service     | 10.26.0.0/16  | Kubernetes services        |

## Project Structure

```
/tofu/
├── main.tf           # Main configuration and node definitions
├── variables.tf      # Input variables
├── output.tf         # Generated outputs (kubeconfig, etc.)
├── providers.tf      # Provider configs (Proxmox, Talos)
├── upgrade-k8s.sh    # Kubernetes upgrade helper
├── terraform.tfvars  # Variable definitions
└── talos/            # Talos cluster module
    ├── config.tf     # Machine configs and bootstrap
    ├── image.tf      # OS image management
    ├── virtual-machines.tf  # Proxmox VM definitions
    └── manifests/    # Kubernetes bootstrap manifests
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

2. Set `update = true` for affected nodes if your OpenTofu module supports this flag for triggering upgrades. Otherwise, `tofu apply` will handle changes to version properties.

3. Run:

   ```bash
   tofu apply
   ```

## Node Management

### Add/Remove Nodes

1. Modify `nodes` in `main.tf`
2. Run `tofu apply`

### Change Resources

1. Update node specs in `main.tf`
2. Run `tofu apply`

> Note: Resource changes may require VM restarts

## Initial Setup

### Prerequisites

- Proxmox server running 7.4+
- SSH key access configured
- Network DHCP/DNS ready
- Storage pools configured

### Configuration

Create `terraform.tfvars` with your environment settings:

```hcl
proxmox = {
  name         = "host3"              # Your Proxmox host name
  cluster_name = "host3"             # Your Proxmox cluster name
  endpoint     = "https://pve:8006"   # Your Proxmox API endpoint
  insecure     = false                # Set to true if using self-signed certs
  username     = "root@pam"           # Your Proxmox username
  api_token    = "USER@pam!ID=TOKEN"  # Your Proxmox API token
}

cluster = {
  name               = "talos"        # Cluster name
  endpoint           = "api.kube.pc-tips.se"  # API endpoint
  kubernetes_version = "1.33.0"       # Kubernetes version
  talos_version     = "v1.10.1"      # Talos version
  gateway           = "10.25.150.1"   # Network gateway
  vip               = "10.25.150.10"  # Control plane VIP
}

nodes = {
  "ctrl-00" = {
    host_node     = "host3"
    machine_type  = "controlplane"
    ip            = "10.25.150.11"
    mac_address   = "bc:24:11:XX:XX:XX"
    vm_id         = 8101
    cpu           = 6
    ram_dedicated = 6144
    update        = false
    igpu          = false
  }
  # Additional nodes...
}
```

### 3. Deployment Steps

1. Load your SSH key for Proxmox access:

```bash
eval $(ssh-agent) && ssh-add ~/.ssh/id_rsa
```

Initialize your workspace:

```bash
tofu init
```

Review and apply the configuration:

```bash
# Review changes
tofu plan

# Deploy cluster
tofu apply
```

Set up cluster access:

```bash
# Copy kubeconfig to your config directory
cat output/kube-config.yaml > ~/.kube/config

# Verify cluster access
kubectl get nodes
```

## Maintenance Operations

### Node Operations

#### Applying Node Updates

To update a node, follow these steps:

Prepare the node for maintenance:

```bash
kubectl cordon node-name
kubectl drain node-name --ignore-daemonsets --delete-emptydir-data
```

Apply updates via OpenTofu:

```bash
tofu apply -target=module.talos.proxmox_virtual_environment_vm.this["node-name"]
```

Return the node to service:

```bash
kubectl uncordon node-name
```

#### Version Upgrades

To upgrade Kubernetes and Talos versions, update the configuration:

```hcl
cluster = {
  kubernetes_version = "1.33.0"  # Target K8s version
  talos_version     = "v1.10.1" # Target Talos version
}
```

Then apply the changes in stages:

```bash
# Plan changes
tofu plan -target=module.talos

# Apply updates
tofu apply -target=module.talos
```

### Recovery Operations

#### State Recovery

If OpenTofu state is lost, follow these steps:

Import existing infrastructure:

```bash
tofu import 'module.talos.proxmox_virtual_environment_vm.this["ctrl-00"]' host3/8101
```

Synchronize the state:

```bash
# Refresh state
tofu refresh

# Verify state
tofu plan
```

#### Node Recovery

To replace a failed node:

Remove it from the cluster:

```bash
kubectl cordon failed-node
kubectl drain failed-node --ignore-daemonsets --delete-emptydir-data
```

Rebuild using OpenTofu:

```bash
# Remove state
tofu taint 'module.talos.proxmox_virtual_environment_vm.this["failed-node"]'

# Recreate node
tofu apply -target=module.talos.proxmox_virtual_environment_vm.this["failed-node"]
```

## Security Implementation

### Core Security Features

Our cluster implements several security measures:

* API server endpoint protection via Gateway API
* etcd encryption at rest enabled
* Node authentication via Talos PKI
* Network isolation with Cilium policies

### Sensitive Files

The deployment generates several sensitive files that must be secured:

```yaml
output/:
  - kube-config.yaml           # Cluster access configuration
  - talos-config.yaml         # Talos management configuration
  - talos-machine-config-*.yaml # Node configurations
```

**Important:** These files contain cluster access credentials and should be stored securely.

## Monitoring and Troubleshooting

### Health Checks

To verify cluster health, check the following:

Node status:

```bash
kubectl get nodes -o wide
```

etcd cluster health:

```bash
talosctl -n node-ip etcd status
```

Control plane status:

```bash
kubectl get pods -n kube-system
```

### Common Issues

#### Node Join Problems

Common causes of node join failures:

* Network connectivity issues
* Machine configuration errors
* Bootstrap process failures

#### API Server Availability

When the API server is unreachable:

* Verify control plane VIP status
* Check etcd cluster health
* Review API server container logs

#### Resource Management

Monitor these aspects:

* VM resource utilization
* Storage availability and performance
* Network connectivity and throughput
