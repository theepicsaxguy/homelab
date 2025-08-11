---
title: Provision Kubernetes with OpenTofu and Talos
---

# Kubernetes provisioning with OpenTofu



## Deployment process

Before you begin deployment, load your SSH key:

```shell
eval $(ssh-agent) && ssh-add ~/.ssh/id_rsa
```



# Deployment process

1. OpenTofu reads configurations
2. Downloads Talos images
3. Creates Proxmox VMs
4. Applies node configs
5. Bootstraps first control plane
6. Generates kubeconfig
7. Verifies cluster health

# Maintenance tasks

## Version upgrades

1. Update versions in `main.tf` or related `tfvars` files. You can specify Talos versions in several
   places:

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

2. Set `update = true` for affected nodes in `tofu/nodes.auto.tfvars` if your OpenTofu module supports this flag for triggering upgrades. Otherwise,
   `tofu apply` handles changes to version properties.

3. Run:

   ```shell
   tofu apply
   ```

## Node management

### Add or remove nodes

1. Change the map in `tofu/nodes.auto.tfvars`
2. Run `tofu apply`

### Change resources

1. Update node specs in `tofu/nodes.auto.tfvars`
2. Run `tofu apply`

> Note: Resource changes can require VM restarts

## Initial setup

### Prerequisites

- Proxmox server running 7.4+

<!-- vale off -->
- API tokens configured for each Proxmox node ([Setup Guide](setup-apikey.md))
- SSH key access configured for each Proxmox node ([Setup Guide](setup-ssh-keys.md))
<!-- vale on -->
- Network dynamic host configuration and domain name resolution ready
- Storage pools configured

### Configuration

Create `config.auto.tfvars` with your environment settings. The repository provides example configuration files.

```hcl
// tofu/config.auto.tfvars example

cluster_name   = "talos"
cluster_domain = "kube.pc-tips.se"

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
  issuer_url = "https://sso.pc-tips.se/application/o/kubectl/"
  client_id  = "kubectl"
}
```

Configure your Proxmox clusters in `terraform.tfvars`:

```hcl
// tofu/terraform.tfvars example for multiple clusters
proxmox = {
  host3 = {
    name         = "host3"
    cluster_name = "host3"
    endpoint     = "https://host3.pc-tips.se:8006"
    insecure     = false
    username     = "root"
    api_token    = "root@pam!terraform2=..."
  }
  nuc = {
    name         = "nuc"
    cluster_name = "nuc"
    endpoint     = "https://nuc.pc-tips.se:8006"
    insecure     = false
    username     = "root"
    api_token    = "terraform@pve!terraform-token=..."
  }
}
```

Configure your nodes in `nodes.auto.tfvars`:

```hcl
// tofu/nodes.auto.tfvars example
nodes_config = {
  "ctrl-00" = {
    machine_type = "controlplane"
    ip          = "10.25.150.11"
    mac_address = "bc:24:11:e6:ba:07"
    vm_id       = 8101
    # Will deploy to first cluster (host3) by default
  }
  "work-04" = {
    host_node    = "nuc"  # Explicitly specify cluster
    machine_type = "worker"
    ip           = "10.25.150.25"
    mac_address  = "bc:24:11:7f:20:05"
    vm_id        = 8205
  }
}
```

### 3. Deployment steps

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

## Maintenance operations

### Node operations

#### Applying node updates

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

#### Version upgrades

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

### Recovery operations

#### State recovery

If you lose OpenTofu state, follow these steps:

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

#### Node recovery

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



## Monitoring and troubleshooting

### Health checks

To verify cluster health, select the following:

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

#### Node join problems

Common causes of node join failures:

- Network connectivity issues
- Machine configuration errors
- Bootstrap process failures

#### API server availability

When the API server becomes unreachable:

- Verify control plane virtual IP status
- Check etcd cluster health
- Review API server container logs

#### Resource management

Watch these aspects:

- VM resource use
- Storage availability and performance
- Network connectivity and throughput
