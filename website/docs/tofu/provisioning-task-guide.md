---
title: Provision Kubernetes with OpenTofu and Talos
---

# Kubernetes Provisioning with OpenTofu

## Deployment Process

Before you begin deployment, ensure your SSH key is loaded:

```shell
eval $(ssh-agent) && ssh-add ~/.ssh/id_rsa
```

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

1. Update versions in `main.tf` or related `tfvars` files. Note that Talos versions can be specified in multiple places:

   - For the Talos image factory (e.g., `module "talos" { talos_image = { version = "vX.Y.Z" } }`)
   - For the machine configurations and cluster secrets (e.g.,
     `module "talos" { cluster = { talos_version = "vX.Y.Z" } }`)
   - Kubernetes version (e.g., `module "talos" { cluster = { kubernetes_version = "vA.B.C" } }`)

   Example snippet from `main.tf` (actual structure can vary based on module inputs):

   ```hcl
   module "talos" {
     # ...
     versions = {
       talos      = "<see https://github.com/siderolabs/talos/releases>" # Target Talos version
       kubernetes = "<see https://github.com/kubernetes/kubernetes/releases>"  # Target Kubernetes version
     }
     # ...
   }
   ```

2. Set `update = true` for affected nodes in `tofu/nodes.auto.tfvars` if your OpenTofu module supports this flag for
   triggering upgrades. Otherwise, `tofu apply` will handle changes to version properties.

3. Run:

   ```shell
   tofu apply
   ```

## Node Management

### Add/Remove Nodes

1. Modify the map in `tofu/nodes.auto.tfvars`
2. Run `tofu apply`

### Change Resources

1. Update node specs in `tofu/nodes.auto.tfvars`
2. Run `tofu apply`

> Note: Resource changes can require VM restarts

## Initial Setup

### Prerequisites

- Proxmox server running 7.4+
- SSH key access configured
- Network DHCP/DNS ready
- Storage pools configured

### Configuration

Create `config.auto.tfvars` with your environment settings. An example file `terraform.tfvars.Example` is provided.

```hcl
// tofu/config.auto.tfvars example

cluster_name   = "talos"
cluster_domain = "kube.peekoff.com"

# Network settings
# All nodes must be on the same L2 network
network = {
  gateway     = "10.25.150.1"
  vip         = "10.25.150.10" # Control plane Virtual IP
  cidr_prefix = 24
  dns_servers = ["10.25.150.1"]
  bridge      = "vmbr0"
  vlan_id     = 150
}

# Proxmox settings
proxmox_cluster = "host3"

# Software versions
versions = {
  talos      = "v1.10.3"
  kubernetes = "1.33.2"
}

# OIDC settings (optional)
oidc = {
  issuer_url = "https://sso.peekoff.com/application/o/kubectl/"
  client_id  = "kubectl"
}
```

### 3. Deployment Steps

1. Load your SSH key for Proxmox access:

```shell
eval $(ssh-agent) && ssh-add ~/.ssh/id_rsa
```

Initialize your workspace:

```shell
tofu init
```

Review and apply the configuration:

```shell
# Review changes
tofu plan

# Deploy cluster
tofu apply
```

Set up cluster access:

```shell
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

```shell
kubectl cordon node-name
kubectl drain node-name --ignore-daemonsets --delete-emptydir-data
```

Apply updates via OpenTofu:

```shell
tofu apply -target='module.talos.proxmox_virtual_environment_vm.this["node-name"]'
```

Return the node to service:

```shell
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

```shell
# Plan changes
tofu plan -target=module.talos

# Apply updates
tofu apply -target=module.talos
```

### Recovery Operations

#### State Recovery

If OpenTofu state is lost, follow these steps:

Import existing infrastructure:

```shell
tofu import 'module.talos.proxmox_virtual_environment_vm.this["ctrl-00"]' host3/8101
```

Synchronize the state:

```shell
# Refresh state
tofu refresh

# Verify state
tofu plan
```

#### Node Recovery

To replace a failed node:

Remove it from the cluster:

```shell
kubectl cordon failed-node
kubectl drain failed-node --ignore-daemonsets --delete-emptydir-data
```

Rebuild using OpenTofu:

```shell
# Remove state
tofu taint 'module.talos.proxmox_virtual_environment_vm.this["failed-node"]'

# Recreate node
tofu apply -target='module.talos.proxmox_virtual_environment_vm.this["failed-node"]'
```

## Monitoring and Troubleshooting

### Health Checks

To verify cluster health, check the following:

Node status:

```shell
kubectl get nodes -o wide
```

etcd cluster health:

```shell
talosctl -n node-ip etcd status
```

Control plane status:

```shell
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
