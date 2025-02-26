# Kubernetes Cluster Bootstrap

The genesis point of our overengineered homelab! 🚀

## Quick Start

1. Configure variables:

```hcl
# terraform.tfvars
cluster_name     = "homelab"
controlplane_ips = ["10.25.150.10", "10.25.150.11", "10.25.150.12"]
worker_ips       = ["10.25.150.20", "10.25.150.21"]
```

2. Launch:

```bash
eval $(ssh-agent)
```

```bash
ssh-add ~/.ssh/id_rsa
```

```bash
ssh-add -L
```

```bash
 cd kubernetes
```

```bash
tofu init
```

```bash
tofu apply
```

## Infrastructure Design

### Node Layout

```yaml
control_plane:
  count: 3
  type: 'talos'
  features:
    - API server
    - etcd
    - controller-manager
    - scheduler

workers:
  count: 2 # Expandable
  type: 'talos'
  features:
    - container runtime
    - cilium networking
    - CSI support
```

## Performance Optimizations

- Local kubeconfig generation
- Optimized provider settings
- Parallel VM provisioning
- Direct Talos bootstrapping

## Network Configuration

| Network | CIDR           | Purpose              |
| ------- | -------------- | -------------------- |
| Node    | 10.25.150.0/24 | Kubernetes nodes     |
| Pod     | 10.25.0.0/16   | Container networking |
| Service | 10.26.0.0/16   | Kubernetes services  |

## Security Features

- API server endpoint protection
- etcd encryption enabled
- Node authentication
- Network isolation

## Critical Files

```yaml
outputs:
  - kubeconfig: Cluster access
  - talosconfig: OS management
  secrets:
  - admin.yaml: Initial credentials
  - worker.yaml: Join tokens
```

## Recovery Procedures

### State Loss

1. Extract node configs
2. Import into state
3. Reconcile differences

### Node Failure

1. Remove from load balancer
2. Rebuild via Talos
3. Rejoin cluster

## Troubleshooting

Common first-boot issues:

1. API Server Unavailable

   ```bash
   # Check Talos status
   talosctl health --talosconfig=talosconfig
   ```

2. etcd Cluster

   ```bash
   # Verify quorum
   talosctl etcd members
   ```

## Pro Tips

- Keep terraform.tfvars in 1Password/Bitwarden
- Backup Talos configs immediately
- Document your network layout
- Test recovery procedures

Remember: You only bootstrap once (hopefully)! 🤞

## Configuration Setup

After running terraform/tofu, set up your configs:

```shell
# Get the configs
tofu output -raw talos_config > ~/.talos/config
tofu output -raw kube_config > ~/.kube/config

# Set proper permissions
chmod 600 ~/.talos/config
chmod 600 ~/.kube/config
```
