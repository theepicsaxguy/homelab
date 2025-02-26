# Network Architecture Guidelines

## Core Network Stack

- Cilium CNI with eBPF and XDP
- BGP peering with UniFi equipment
- Service Mesh with WireGuard encryption
- Gateway API for ingress routing

## Network Policies

- Default deny all ingress/egress
- Explicit allow rules only
- CiliumNetworkPolicy for L7 filtering
- Regular network audits required

## References

- file:../../../k8s/infra/base/network/cilium/kustomization.yaml

- file:../../../k8s/infra/base/network/dns/kustomization.yaml

## Security Requirements

- mTLS for all service communication
- Network isolation between namespaces
- Regular network policy audits
- Flow logs for security analysis
