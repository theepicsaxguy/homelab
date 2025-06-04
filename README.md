# 🏠 The Homelab That Refuses to Die

#### _Because fixing endless VMs is for the birds—and my first kid is arriving soon!_

---

## 📌 Project Summary & Key Features

**The Homelab That Refuses to Die** is a fully automated, GitOps-driven infrastructure built to be self-healing and
nearly maintenance-free. It’s designed to rescue you from the endless cycle of VM fixes so you can focus on your growing
family.

**Key Features:**

- **Namespace-Based Isolation:** All workloads run in a single cluster but are kept separate via dedicated namespaces
- **Pure GitOps Workflow:** All changes go through Git for full traceability and easy rollback.
- **Self-Healing Infrastructure:** Leveraging ArgoCD to automatically reconcile your state.
- **Zero Trust Security:** Enforced at every layer so you never worry about unauthorized changes.
- **Rapid Recovery:** Disaster recovery in just a few commands.


<p align="center">
  <em>Built with love, caffeine, and a whole lot of "not again!" moments.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/theepicsaxguy/homelab?style=social" alt="GitHub stars">
  <img src="https://img.shields.io/github/forks/theepicsaxguy/homelab?style=social" alt="GitHub forks">
  <img src="https://img.shields.io/github/watchers/theepicsaxguy/homelab?style=social" alt="GitHub watchers">
  <img src="https://img.shields.io/github/license/theepicsaxguy/homelab" alt="License">
  <img src="https://img.shields.io/github/issues/theepicsaxguy/homelab" alt="GitHub issues">
  <img src="https://img.shields.io/github/issues-pr/theepicsaxguy/homelab" alt="GitHub pull requests">
</p>

<details>
  <summary>📊 GitHub Stats</summary>

![Your GitHub Stats](https://github-readme-stats.vercel.app/api?username=theepicsaxguy&show_icons=true&theme=radical)
![GitHub Streak](https://streak-stats.demolab.com/?user=theepicsaxguy&theme=monokai)

</details>

---

## 📌 Why This Homelab?

I was fed up with manually fixing and maintaining multiple VMs and their operating systems. With a baby on the way, I
needed a foolproof, low-maintenance system. This homelab is my answer:

- **Automation Overhead?** Gone.
- **Manual Fixes at 3 AM?** Not happening.
- **Downtime?** Reduced to a minimum.

It's designed to be robust and self-recovering—so I can focus on my family rather than fighting infrastructure
meltdowns.

---

## 🖥 Infrastructure & Applications Overview

### Core Infrastructure

Our infrastructure is built on a GitOps foundation that makes everything reproducible and auditable.

**Key Components:**

- **Talos Linux:** A Kubernetes-native OS that minimizes attack surface and maintenance.
- **ArgoCD:** Our GitOps engine that ensures the cluster state always matches Git.
- **Cilium & Gateway API:** Advanced networking, security, and load balancing.
- **Authentik:** For centralized authentication and secure access control.
- **Longhorn:** Distributed storage solution. Proxmox is used as the hypervisor.
- **External Secrets & Cert-Manager:** Securely manage secrets and automate TLS certificate provisioning.

_\*\*For more details, check out our [Architecture Deep Dive](/docs/architecture)._

### Environment Strategy

All services run in a single Kubernetes cluster.  Infrastructure components and
applications are organized into dedicated namespaces (such as
`infrastructure-system` and `applications-system`) and synchronized via ArgoCD
sync waves.  Configuration overlays allow resources to progress through
different stages when needed without maintaining separate clusters.

### Technology Stack

- **Talos Linux**
- **ArgoCD**
- **Cilium**
- **Kustomize**
- **Bitwarden** (Secrets Management)


---

## 🚀 Quick Start Guide

If you’re ready to deploy your foolproof homelab, follow these steps:

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/theepicsaxguy/homelab.git
   cd homelab
   ```

2. **Install Dependencies:** Make sure you have [Tofu](https://opentofu.org) installed along with any other
   prerequisites.

3. **Deploy the Infrastructure:**

   ```bash
   cd tofu
   tofu init && tofu apply
   ```

4. **Deploy Kubernetes Workloads via ArgoCD:**

   ```bash
   cd ../k8s
   tofu init && tofu apply
   ```

5. **Verify & Enjoy:** Check your deployment status and celebrate as your homelab comes to life—ready to self-heal and
   keep you out of midnight fix sessions.

_For more detailed deployment instructions, see our
[Disaster Recovery: The 4-Command Rule](#disaster-recovery-the-4-command-rule) section._

---

## 🛠 Operational Excellence

### Disaster Recovery: The 4-Command Rule

When disaster strikes (like an unexpected VM meltdown—or a diaper blowout), your homelab is designed to resurrect in
minutes:

```bash
# 1. Clone the repository
git clone https://github.com/theepicsaxguy/homelab.git
cd tofu

# 2. Deploy the infrastructure
tofu init && tofu apply

# 3. Deploy workloads via ArgoCD
cd ../k8s
tofu init && tofu apply
```

> **Note:** Back online faster than you can say, “I need more sleep!” 😅

A quick flowchart:

```mermaid
flowchart TD
    A[Clone Repository] --> B[Deploy Infrastructure]
    B --> C[Deploy Workloads via ArgoCD]
    C --> D[Homelab Up and Running!]
    D --> E[Celebrate with Baby Giggles & Coffee]
```

---

## 📝 Documentation & Further Reading

For geekier details, in-depth configurations, and all the YAML, visit the
[Documentation](https://homelab.orkestack.com/docs/)

---

## 🌟 Project Journey & Future Vision

### Evolution

- **From VM Frustration:** Tired of endless manual fixes.
- **Kubernetes Epiphany:** Embraced a GitOps-driven approach for self-healing.
- **Talos Transition:** A move toward immutable, secure infrastructure.
- **GitOps All the Way:** If it’s not in Git, it doesn’t exist.

### Roadmap

**High Priority:**

- **Hybrid Cloud Backups:** Offload backups for extra redundancy.
- **Node Autoscaling:** Let the cluster scale dynamically.
- **Automated Disaster Recovery:** More tests, less manual intervention.

**Security & Stability:**

- **Enhanced Security Layers:** Tighter RBAC and network policies.
- **Stricter Monitoring:** Upgrading our observability stack for proactive alerts.

**Performance & Optimization:**

- **Storage Tuning:** Optimized I/O and SSD caching.
- **CI/CD Enhancements:** More automation to reduce manual work.
- **Advanced Observability:** More dashboards and metrics to keep you in the know.

---

## 🤝 Getting Involved

### Getting Started

Ready to join the revolution? Here’s your starter pack:

1. **Fork & Clone:**

   ```bash
   git clone https://github.com/theepicsaxguy/homelab.git
   cd homelab
   ```

2. **Install Dependencies:** Ensure you have [Tofu](https://opentofu.org) and other prerequisites installed.

3. **Deploy:** Follow the Quick Start Guide above to see the homelab in action.

4. **Contribute:** Fork, branch, and open a pull request with your ideas or fixes.

### Contributing Guidelines

- **Follow GitOps:** All changes must be tracked in Git.
- **Keep It Lean:** Help us keep the main docs uncluttered—details go in the dedicated docs.
- **Be Respectful:** Follow our [Code of Conduct](CONTRIBUTING.md).

---

## 💬 Community & Support

Join our community to chat, ask questions, or share your homelab adventures:

- **GitHub Issues & Discussions:** [Join Here](https://github.com/theepicsaxguy/homelab/issues)
- **Documentation:** Detailed docs are available in the [docs folder](docs/).

If you find broken links or have suggestions, please open an issue.

---

## 🤔 Final Thoughts

This isn’t just a homelab—it’s my escape from endless VM fixes and the chaos of life, engineered to be self-healing so I
can enjoy family time. It’s built for:

- **Automation:** So you (and I) can sleep in on weekends.
- **Rapid Recovery:** Because a few commands should bring everything back online.
- **Zero Headaches:** Let the system work its magic while you focus on what matters.

When things break, they get fixed. When chaos ensues, a quick command restores order. And that, my friends, is how you
free up time for family, love, and a bit of coding adrenaline.

---

## 📄 License

MIT License – See [LICENSE](LICENSE) for details.

---

## 🙏 Credits

Special thanks to the inspiration and work behind [Vehagn's Homelab](https://github.com/vehagn/homelab).
