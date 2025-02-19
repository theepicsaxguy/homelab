<div align="center">

# 🏠 Welcome to My Overengineered Homelab! 🚀

Because why run Plex on a Raspberry Pi when you can have a full Kubernetes cluster?

[![Kubernetes](docs/assets/kubernetes-logo.svg)](https://kubernetes.io)
[![Proxmox](docs/assets/proxmox-logo-stacked-color.svg)](https://www.proxmox.com)
[![Talos](docs/assets/talos-logo.svg)](https://talos.dev)
[![OpenTofu](docs/assets/tofu-on-light.svg)](https://opentofu.org)

_Built with love, coffee, and probably too much time spent reading Kubernetes docs_

</div>

---

## 🎯 What's This All About?

This is my homelab - a slightly excessive but incredibly fun infrastructure setup that brings enterprise-grade tech to
my home network. It's built on modern DevOps practices because, well, why not learn the cool stuff?

### 🛠 Core Stack

- **Proxmox VE**: The rock-solid foundation (VM hypervisor)
- **OpenTofu**: Infrastructure as code (the cooler fork of Terraform)
- **Talos**: A Kubernetes-focused OS that's lean and mean
- **Kubernetes**: The container orchestrator we all love to debug
- **ArgoCD**: GitOps magic - because `kubectl apply` is so 2020
- **Cilium**: eBPF-powered networking that makes kube-proxy cry

## 🌟 Key Features

- **🔒 Security First**: Zero-trust setup with Authelia, sealed secrets, and network policies
- **🚄 Performance Focused**: Cilium direct routing, eBPF optimizations, tuned storage classes
- **🤖 Fully Automated**: From VM provisioning to app deployment, it's GitOps all the way down
- **🎮 Self-Healing**: Because nobody wants to fix servers at 3 AM
- **📊 Observable**: Prometheus, Grafana, and Hubble keeping watch

## 📦 What's Running?

### Core Infrastructure

- Authentication stack (Authelia, LLDAP)
- Monitoring (Prometheus, Grafana, Loki)
- Storage (Proxmox CSI, TrueNAS integration)
- Network (Cilium, DNS, Gateway API)

### Applications

- Media stack (Plex alternative with Jellyfin)
- Development environments
- Home automation
- And whatever else catches my fancy!

## 🚀 Quick Start

If you're brave enough to replicate this:

```bash
# 1. Clone and set up infrastructure
git clone https://github.com/yourusername/homelab.git
cd tofu/kubernetes
tofu init && tofu apply

# 2. Let ArgoCD take the wheel
cd ../../k8s
tofu init && tofu apply
```

## 📝 Documentation

Detailed docs in `/docs` - because even I forget how this all works sometimes:

- [🏗 Architecture Deep Dive](docs/architecture.md)
- [🌐 Network Magic Explained](docs/network-architecture.md)
- [💾 Storage Setup](docs/storage-architecture.md)
- [🔐 Security Model](docs/security-architecture.md)
- [📊 Monitoring Stack](docs/monitoring-architecture.md)

## 🎯 Design Goals

1. **Performance**: eBPF-powered networking, optimized storage paths
2. **Security**: Zero-trust, authentication everywhere, encrypted everything
3. **Automation**: If it can't be automated, it doesn't belong here
4. **Learning**: Because breaking things is how we learn

## 🧰 Requirements

- A Proxmox server with enough resources to make your electricity bill noticeable
- Network that can handle BGP (optional, but cool)
- Storage that doesn't mind being abused by Kubernetes
- Patience for when things inevitably break

## 🤝 Contributing

Got ideas? Found a bug? PRs welcome! Just remember:

1. Everything must be GitOps-compatible
2. Document performance impacts
3. Security is not optional
4. Keep it clean, keep it automated

## 📈 Performance

Some cool numbers because who doesn't love metrics:

- Pod-to-pod latency: <1ms (Cilium direct routing)
- Storage throughput: Up to 1GB/s (depends on backend)
- Startup time: From zero to running cluster in ~15 minutes
- Time spent tweaking configs: Countless hours

## 🔐 Security Notes

- Zero-trust network model
- Everything encrypted in transit and at rest
- Authentication required for all services
- Regular security scans and updates

## 🛠 Tech Deep Dive

Check out the [architecture docs](docs/architecture.md) for the nitty-gritty details, including:

- Network topology and security zones
- Storage class configurations
- Monitoring and alerting setup
- Backup and recovery procedures

## 📊 Current Status

- **Infrastructure**: Running strong 💪
- **Applications**: Continuously evolving 🚀
- **Documentation**: Always improving 📝
- **My sanity**: Depends on the day 😅

## ⚖️ License

MIT Licensed - See [LICENSE](LICENSE) for details

---

_Remember: "It works on my cluster" is the new "It works on my machine"_ 😉

### Credits

This wouldnt be possible without [Vehagn's homelab](https://github.com/vehagn/homelab)
