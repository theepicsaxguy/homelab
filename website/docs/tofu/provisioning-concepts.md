---
title: OpenTofu Provisioning Concepts
---

# Kubernetes Provisioning with OpenTofu: Concepts

This guide explains the conceptual underpinnings of infrastructure provisioning using OpenTofu to create a production ready Kubernetes cluster running Talos OS on Proxmox.

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

| Network | CIDR           | Purpose                    |
| ------- | -------------- | -------------------------- |
| Node    | 10.25.150.0/24 | Kubernetes node networking |
| Pod     | 10.25.0.0/16   | Container networking       |
| Service | 10.26.0.0/16   | Kubernetes services        |

## Project Structure

```
/tofu/
├── main.tf           # Core configuration
├── nodes.auto.tfvars # Node definitions
├── variables.tf      # Input variables
├── output.tf         # Generated outputs (kubeconfig, etc.)
├── providers.tf      # Provider configs (Proxmox, Talos)
├── config.auto.tfvars # Environment-specific configuration
├── terraform.tfvars.Example # Example variable definitions
└── talos/            # Talos cluster module
    ├── config-secrets.tf     # Machine secrets
    ├── config-client.tf      # Client configuration
    ├── config-machine.tf     # Machine configs
    ├── config-cluster.tf     # Bootstrap and health checks
    ├── image.tf      # OS image management
    ├── virtual-machines.tf  # Proxmox VM definitions
    ├── machine-config/      # Config templates
    └── inline-manifests/    # Core component YAMLs
```

All provider version constraints live in this root `providers.tf` file. The subdirectory modules inherit those settings so updates happen in one place.

# Core Components

## Proxmox Provider

I use `bpg/proxmox` to manage VMs in a declarative manner. This enables:

- Version-controlled infrastructure
- Automated deployments
- Quick cluster rebuilds

## Talos OS

Talos is my node OS because it offers:

- Minimal attack surface
- Atomic upgrades
- API-driven management
- Kubernetes-specific design

## VM Configuration

VM configuration uses `lookup(each.value, ..., <default>)` for various settings (e.g., `bios`, `cpu`, `memory`, `disk_size`). This allows for per-node overrides in `nodes.auto.tfvars` while providing sensible defaults.



### Node Specs

Node definitions pull from two base variables: `defaults_worker` and `defaults_controlplane`. Each node configuration in `nodes.auto.tfvars` only needs to declare what differs from these defaults. This structure simplifies configuration and reduces repetition.

If a node's `machine_type` doesn't match a key in the defaults table, the plan fails with an explicit error.

`host_node` is optional. If you omit it, the virtual machine will be scheduled on the Proxmox node specified in your main provider configuration (`var.proxmox.name`). This is ideal for single-host setups.

```hcl
# tofu/nodes.auto.tfvars example
nodes_config = {
  # This controlplane node inherits its CPU and RAM from defaults_controlplane
  "ctrl-00" = {
    machine_type  = "controlplane"
    ip            = "10.25.150.11"
    mac_address   = "bc:24:11:XX:XX:X1"
    vm_id         = 8101
  }
  # This worker inherits all its specs from defaults_worker
  "work-00" = {
    machine_type = "worker"
    ip           = "10.25.150.21"
    mac_address  = "bc:24:11:XX:XX:X2"
    vm_id        = 8201
  }
  # This worker inherits defaults but overrides the dedicated RAM
   "work-01" = {
    machine_type  = "worker"
    ip            = "10.25.150.22"
    mac_address   = "bc:24:11:XX:XX:X3"
    vm_id         = 8202
    ram_dedicated = 12240 # Override default worker RAM
  }
  # This worker is GPU-capable
  "work-03" = {
    machine_type = "worker"
    ip           = "10.25.150.24"
    mac_address  = "bc:24:11:XX:XX:X5"
    vm_id        = 8204
    igpu         = true
    gpu_devices  = ["0000:01:00.0", "0000:01:00.1"] # Example BDFs for GPU and HDMI Audio
  }
  # This worker runs on a different Proxmox host
  "work-04" = {
    host_node    = "nuc"
    machine_type = "worker"
    ip           = "10.25.150.25"
    mac_address  = "bc:24:11:XX:XX:X6"
    vm_id        = 8205
  }
}
```

> Note: At least one node must have `machine_type` set to `controlplane`. OpenTofu validates this during `tofu plan`.

OpenTofu also enforces a few sanity checks:

- IP addresses must be unique across nodes.
- VM IDs must be unique.
- `mac_address` values must follow the `00:11:22:33:44:55` format.

### Disk Layout

Additional disks can be defined per node in a `disks` map. This allows you to override the default disk configuration for specific nodes. For example, you can assign a larger Longhorn volume to a particular worker. Each disk now requires a `unit_number` which determines the Proxmox interface, for example `scsi1`:

```hcl
# Example of a worker node with an overridden disk size
"work-02" = {
  machine_type = "worker"
  ip           = "10.25.150.23"
  mac_address  = "bc:24:11:XX:XX:X4"
  vm_id        = 8203
  disks = {
    longhorn = {
      size = "500G" # This overrides the default size
    }
  }
}
```

### Custom Images

Talos OS images are built via the Talos Image Factory and include core extensions like the QEMU guest agent and iSCSI tools. These images are automatically downloaded to Proxmox and deduplicated per Proxmox node and image variant.



## Machine Configuration

### Template System

- Uses YAML templates for node configs
- Injects per-node settings:
  - Hostname
  - IP address
  - Cluster details

### Core Services

I embed essential services in the Talos config:

- Cilium (CNI)
- CoreDNS
- ConfigMaps for service configuration

## Security Implementation

### Core Security Features

My cluster implements several security measures:

- API server endpoint protection via Gateway API
- etcd encryption at rest enabled
- Node authentication via Talos PKI
- Network isolation with Cilium policies

### Sensitive Files

The deployment generates several sensitive files that must be secured:

```yaml
output/:
  - kube-config.yaml # Cluster access configuration
  - talos-config.yaml # Talos management configuration
  - talos-machine-config-*.yaml # Node configurations
```

**Important:** These files contain cluster access credentials and should be stored securely.
