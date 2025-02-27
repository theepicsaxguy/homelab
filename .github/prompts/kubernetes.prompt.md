# Kubernetes Configuration Guidelines

## Architecture Preferences

- Cilium as primary CNI with eBPF enabled
- Service mesh and BGP routing enabled
- Strict mTLS enforcement
- CloudNative PG for database operations

## References

[Kubernetes Apps](../../k8s/apps/README.md) [Infrastructure](../../k8s/infrastructure/README.md)

## Provider Configuration

```hcl
provider "kubernetes" {
  host = local.endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  client_certificate = local.client_certificate
  client_key = local.client_key
  load_config_file = false
}

provider "kubectl" {
  apply_retry_count = 3
  load_config_file = false
}
```

## Security Requirements

- All secrets must use sm-operator
- Implement RBAC strictly
- Enable network policies
- Use SecurityContexts appropriately

## Storage Configuration

- TrueNAS + Proxmox CSI for persistence
- Define appropriate StorageClasses
- Implement backup strategies
