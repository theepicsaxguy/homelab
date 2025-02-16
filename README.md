<div align="center">

# 🪨 Homelab 🏡

A modern GitOps-driven homelab infrastructure powered by Kubernetes and automation

[![Kubernetes](docs/assets/kubernetes-logo.svg)](https://kubernetes.io)
[![Proxmox](docs/assets/proxmox-logo-stacked-color.svg)](https://www.proxmox.com)
[![Talos](docs/assets/talos-logo.svg)](https://talos.dev)
[![OpenTofu](docs/assets/tofu-on-light.svg)](https://opentofu.org)

Built with [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment), [OpenTofu](https://opentofu.org/),
[Talos](https://talos.dev), [Kubernetes](https://kubernetes.io/), and [Argo CD](https://argoproj.github.io/cd/).
Continuously updated by [Renovate](https://www.mend.io/renovate/).

</div>

---

## Quick Start 🚀

```bash
# Clone the repo
git clone https://github.com/theepicsaxguy/homelab

# Deploy infrastructure
cd tofu/kubernetes
tofu init && tofu apply

# Access your cluster
export KUBECONFIG=output/kube-config.yaml
```

## Technical Stack 🏗️

### Core Infrastructure

- **Hypervisor**: Proxmox VE (3-node cluster)
- **Kubernetes**: Talos v1.9.4
- **CNI**: Cilium with eBPF, Service Mesh, BGP
- **GitOps**: Argo CD with ApplicationSets
- **Storage**: TrueNAS + Proxmox CSI
- **Auth**: Keycloak + Authelia + LLDAP

### Technical Specifications

- **Control Plane**: 3 nodes (4 CPU, 2480MB RAM each)
- **Worker Nodes**: High-performance workers with GPU passthrough
- **Network**: 10.25.150.0/24 cluster network
- **API**: api.kube.pc-tips.se:6443

## Documentation 📚

### Architecture

- [Core Infrastructure](docs/architecture.md) - Application flows and infrastructure overview
- [Network Architecture](docs/network-architecture.md) - Network topology and traffic flows
- [Security Architecture](docs/security-architecture.md) - Security boundaries and controls
- [Storage Architecture](docs/storage-architecture.md) - Storage components and procedures
- [Monitoring Architecture](docs/monitoring-architecture.md) - Observability and alerting

### Key Features

- GitOps-driven deployments
- Zero-trust security model
- High-availability design
- Performance-optimized storage
- Automated certificate management
- Comprehensive monitoring

## Repository Structure 📂

### Core Infrastructure

```
k8s/
├── infra/          # Core infrastructure components
├── apps/           # Application workloads
└── sets/           # ApplicationSet configurations
```

### Infrastructure Code

```
tofu/
├── kubernetes/     # Kubernetes cluster provisioning
└── home-assistant/ # Home automation infrastructure
```

## Development 🛠️

### Prerequisites

- Proxmox VE cluster
- Network infrastructure
- DNS configuration
- Storage backend

### Deployment Flow

1. Infrastructure provisioning (tofu)
2. Cluster bootstrapping (Talos)
3. Core services deployment (ArgoCD)
4. Application rollout (ApplicationSets)

## Contributing 🤝

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License 📝

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
