---
title: Provision Kubernetes with OpenTofu and Talos
---

# Kubernetes Provisioning with OpenTofu

This guide explains my infrastructure provisioning using OpenTofu to create a production-grade Kubernetes cluster
running Talos OS on Proxmox.

## Deployment Process

Before you begin deployment, ensure your SSH key is loaded:

```bash
eval $(ssh-agent) && ssh-add ~/.ssh/id_rsa
```

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
├── terraform.tfvars  # Variable definitions
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

All provider version constraints live in this root `providers.tf` file. The
subdirectory modules inherit those settings so updates happen in one place.

# Core Components

## Proxmox Provider

I use `bpg/proxmox` to manage VMs declaratively. This enables:

- Version-controlled infrastructure
- Automated deployments
- Easy cluster rebuilds

## Talos OS

Talos is my node OS because it offers:

- Minimal attack surface
- Atomic upgrades
- API-driven management
- Kubernetes-specific design

## VM Configuration

VM configuration uses `lookup(each.value, ..., <default>)` for various settings (e.g., `bios`, `cpu`, `memory`, `disk_size`). This allows for per-node overrides in `nodes.auto.tfvars` while providing sensible defaults.

#### GPU Mapping

For GPU-capable nodes (`igpu = true`), the `dynamic "hostpci"` block iterates over the `gpu_devices` list, creating PCI passthrough devices. Each device is mapped using a unique alias in the format `gpu-<node>-<idx>` instead of raw PCI IDs. This mapping is handled by the `proxmox_virtual_environment_hardware_mapping_pci` resource, which creates the necessary PCI alias mappings in Proxmox using vendor/device IDs, subsystem IDs, and IOMMU groups.

#### `variables.tf` Updates

The nodes and nodes_config input types in variables.tf include the gpu_devices attribute, which accepts a list of PCI BDFs. A validation rule ensures that if igpu is true, the gpu_devices list is not empty.

### Node Specs

Node definitions pull from two base variables—`defaults_worker` and `defaults_controlplane`. Each node configuration in `nodes.auto.tfvars` only needs to declare what differs from these defaults. This structure simplifies configuration and reduces repetition.

If a node's `machine_type` doesn't match a key in the defaults table, the plan fails with an explicit error.

A key improvement is that `host_node` is now optional. If you omit it, the virtual machine will be scheduled on the Proxmox node specified in your main provider configuration (`var.proxmox.name`). This is ideal for single-host setups.

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

#### Talos Image Pipeline

The Talos image pipeline supports conditional inclusion of NVIDIA GPU extensions. A set of OpenTofu locals manages this functionality:

*   `has_gpu_nodes`: A boolean indicating if any node in the configuration is GPU-capable.
*   `schematic_configs`: A map that defines different image schematics (e.g., `std_inst` for standard installation, `gpu_inst` for GPU-enabled installation, and their update counterparts `std_upd`, `gpu_upd`).
*   `get_schematic_key`: A helper to determine the correct schematic key for each node based on its GPU capability and update status.
*   `image_download_groups` and `image_downloads`: These locals manage the grouping and flattening of image downloads, ensuring that the correct image variant is downloaded for each node.

The `talos_image_factory_schematic` resource uses a `for_each` loop over `local.schematic_configs`, allowing for dynamic image generation based on node requirements. The `proxmox_virtual_environment_download_file` resource uses `each.value.schematic_id` to ensure the correct image is downloaded.

GPU-enabled images include the `siderolabs/nonfree-kmod-nvidia-lts` and `siderolabs/nvidia-container-toolkit-lts` extensions, which provide support for NVIDIA's proprietary drivers.


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

1. Update versions in `main.tf` or related `tfvars` files. Note that Talos versions might be specified in multiple
   places:

   - For the Talos image factory (e.g., `module "talos" { talos_image = { version = "vX.Y.Z" } }`)
   - For the machine configurations and cluster secrets (e.g.,
     `module "talos" { cluster = { talos_version = "vX.Y.Z" } }`)
   - Kubernetes version (e.g., `module "talos" { cluster = { kubernetes_version = "vA.B.C" } }`)

   Example snippet from `main.tf` (actual structure may vary based on module inputs):

   ```hcl
   module "talos" {
     # ...
     talos_image = {
       version = "<see https://github.com/siderolabs/talos/releases>" # Target Talos version for OS images
       # ...
     }
     cluster = {
       talos_version      = "<see https://github.com/siderolabs/talos/releases>" # Target Talos version for machine configs
       kubernetes_version = "<see https://github.com/kubernetes/kubernetes/releases>"  # Target Kubernetes version
       # ...
     }
     # ...
   }
   ```

2. Set `update = true` for affected nodes in `tofu/nodes.auto.tfvars` if your OpenTofu module supports this flag for triggering upgrades. Otherwise,
   `tofu apply` will handle changes to version properties.

3. Run:

   ```bash
   tofu apply
   ```

## Node Management

### Add/Remove Nodes

1. Modify the map in `tofu/nodes.auto.tfvars`
2. Run `tofu apply`

### Change Resources

1. Update node specs in `tofu/nodes.auto.tfvars`
2. Run `tofu apply`

> Note: Resource changes may require VM restarts

## Initial Setup

### Prerequisites

- Proxmox server running 7.4+
- SSH key access configured
- Network DHCP/DNS ready
- Storage pools configured

### Configuration

Create `terraform.tfvars` with your environment settings. The internal
cluster domain defaults to `kube.pc-tips.se` and can be changed in
`tofu/locals.tf`:

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
  endpoint           = "api.kube.your.domain.tld"  # API endpoint
  kubernetes_version = "<see https://github.com/kubernetes/kubernetes/releases>"       # Kubernetes version
  talos_version     = "<see https://github.com/siderolabs/talos/releases>"      # Talos version
  gateway           = "10.25.150.1"   # Network gateway
  vip               = "10.25.150.10"  # Control plane VIP
}

nodes = {
  "ctrl-00" = {
    # host_node is optional and defaults to proxmox.name
    machine_type  = "controlplane"
    ip            = "10.25.150.11"
    mac_address   = "bc:24:11:XX:XX:XX"
    vm_id         = 8101
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
tofu apply -target='module.talos.proxmox_virtual_environment_vm.this["node-name"]'
```

Return the node to service:

```bash
kubectl uncordon node-name
```

#### Version Upgrades

To upgrade Kubernetes and Talos versions, update the configuration:

```hcl
cluster = {
  kubernetes_version = "<see https://github.com/kubernetes/kubernetes/releases>"  # Target K8s version
  talos_version     = "<see https://github.com/siderolabs/talos/releases>" # Target Talos version
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
tofu apply -target='module.talos.proxmox_virtual_environment_vm.this["failed-node"]'
```

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

- Network connectivity issues
- Machine configuration errors
- Bootstrap process failures

#### API Server Availability

When the API server is unreachable:

- Verify control plane VIP status
- Check etcd cluster health
- Review API server container logs

#### Resource Management

Monitor these aspects:

- VM resource utilization
- Storage availability and performance
- Network connectivity and throughput
