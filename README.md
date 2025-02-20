<div align="center">

<h1>🏠 Welcome to My Overengineered Homelab! 🚀</h1>

<p>Because why run Plex on a Raspberry Pi when you can have a full Kubernetes cluster?</p>

<p>
  <a href="https://kubernetes.io"><img src="docs/assets/kubernetes-logo.svg" height="100px"></a>
  <a href="https://www.proxmox.com"><img src="docs/assets/proxmox-logo-stacked-color.svg" height="100px"></a>
  <a href="https://talos.dev"><img src="docs/assets/talos-logo.svg" height="100px"></a>
  <a href="https://opentofu.org"><img src="docs/assets/tofu-on-light.svg" height="100px"></a>
</p>

<p><em>Built with love, coffee, and probably too much time spent reading Kubernetes docs</em></p>

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
- **🧑‍💻 Dev-Friendly**: CI/CD, declarative configs, and infrastructure as code  

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

📝 Documentation

Detailed docs in /docs - because even I forget how this all works sometimes:

🏗 Architecture Deep Dive

🌐 Network Magic Explained

💾 Storage Setup

🔐 Security Model

📊 Monitoring Stack


🎯 Design Goals

1. Performance: eBPF-powered networking, optimized storage paths


2. Security: Zero-trust, authentication everywhere, encrypted everything


3. Automation: If it can't be automated, it doesn't belong here


4. Learning: Because breaking things is how we learn



🧰 Requirements

A Proxmox server with enough resources to make your electricity bill noticeable

Network that can handle BGP (optional, but cool)

Storage that doesn't mind being abused by Kubernetes

Patience for when things inevitably break


🤝 Contributing

Got ideas? Found a bug? PRs welcome! Just remember:

1. Everything must be GitOps-compatible


2. Document performance impacts


3. Security is not optional


4. Keep it clean, keep it automated



📈 Performance

Some cool numbers because who doesn't love metrics:

Pod-to-pod latency: <1ms (Cilium direct routing)

Storage throughput: Up to 1GB/s (depends on backend)

Startup time: From zero to running cluster in ~15 minutes

Time spent tweaking configs: Countless hours


🔐 Security Notes

Zero-trust network model

Everything encrypted in transit and at rest

Authentication required for all services

Regular security scans and updates


🛠 Tech Deep Dive

Check out the architecture docs for the nitty-gritty details, including:

Network topology and security zones

Storage class configurations

Monitoring and alerting setup

Backup and recovery procedures


📊 Current Status

Infrastructure: Running strong 💪

Applications: Continuously evolving 🚀

Documentation: Always improving 📝

My sanity: Depends on the day 😅


🚀 Future To-Do / Improvements

Some planned enhancements to make this even more absurdly overengineered:

🔹 Longhorn: Distributed block storage for better persistence and redundancy

☁️ External Cloud Storage: Hybrid storage integration (e.g., S3, Backblaze B2)

🔄 Node Autoscaler: Dynamic scaling to optimize resources

🏗 More CI/CD: Automating even the tiniest things for efficiency

🌍 Multi-Cluster Federation: Because one cluster isn’t enough

🛡️ More Security Layers: Further hardening network policies and auth


⚖️ License

MIT Licensed - See LICENSE for details


---

_Remember: "It works on my cluster" is the new "It works on my machine"_ 😉

### Credits

This wouldnt be possible without [Vehagn's homelab](https://github.com/vehagn/homelab)
