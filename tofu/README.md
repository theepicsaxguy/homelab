# Infrastructure Provisioning Layer

Where the magic begins - OpenTofu configurations for bootstrapping our overengineered homelab! 🏗️

## Directory Structure

```
.
├── kubernetes/           # Main cluster provisioning
│   ├── bootstrap/       # Initial configuration
│   ├── talos/          # Talos OS configs
│   └── output/         # Generated configs
└── home-assistant/      # Home automation VM
```

## Quick Start

```bash
cd kubernetes
cp terraform.tfvars.example terraform.tfvars
# Edit your variables
tofu init && tofu apply

kubectl create secret generic bweso-credentials \
   --from-literal=BW_CLIENTSECRET='your-client-secret' \
   --from-literal=BW_CLIENTID='your-client-id' \
   --from-literal=BW_HOST='your-bitwarden-host' \
   -n external-secrets --dry-run=client -o yaml | kubectl apply -f -
```

## Performance Tweaks

- Uses local.kubeconfig_data from Talos (faster than external sources)
- Optimized provider configs (load_config_file = false)
- Retry logic for reliability (apply_retry_count = 3)
- Parallel resource creation where safe

## Resource Specs

### Kubernetes Cluster

```yaml
control_plane:
  cpu: 2
  memory: 4096
  disk: 100G
  count: 3 # HA setup

workers:
  cpu: 4
  memory: 8192
  disk: 200G
  count: 2 # Scalable
```

### Network Configuration

- VLAN support
- BGP for Cilium
- Dedicated storage network

## Talos Configuration

- Minimal OS footprint
- Cilium CNI pre-configured
- API-driven management
- Automated updates

## State Management

- State stored in local files
- Backup state files regularly!
- Use -refresh-only for state checks

## Security Notes

- API tokens generated automatically
- Secrets handled via variables
- No password authentication
- SSH via authorized keys only

## Common Tasks

1. Add worker node:

   ```hcl
   workers_count = 3  # Increase count
   ```

2. Upgrade Kubernetes:
   ```hcl
   kubernetes_version = "v1.28.0"  # Update version
   ```

## Debugging

- Check Talos logs via talosctl
- Proxmox tasks show provisioning status
- OpenTofu state list for resource view

## Recovery Procedure

1. State exists: `tofu refresh`
2. State lost:
   - Rename old resources
   - Import into new state
   - Pray 🙏

## Known Issues

1. Proxmox API timeouts

   - Solution: Increase timeout values
   - Status: Working around it

2. Talos bootstrap race conditions
   - Solution: Retry logic implemented
   - Status: Handled automatically

## Future Plans

- [ ] Multi-cluster support
- [ ] Dynamic worker scaling
- [ ] Improved state backup
- [ ] Automated testing

Remember: If it's not in code, it doesn't exist! 🤖
