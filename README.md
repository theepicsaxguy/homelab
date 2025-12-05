# Over-Engineered GitOps Homelab

[![CI](https://github.com/theepicsaxguy/homelab/actions/workflows/image-build.yaml/badge.svg)](https://github.com/theepicsaxguy/homelab/actions/workflows/image-build.yaml) ![License](https://img.shields.io/github/license/theepicsaxguy/homelab)

After rebuilding my homelab one too many times, I committed to managing it entirely with GitOps. This repository is the result: a blueprint for a resilient, production-inspired Kubernetes cluster.

I'm sharing it to document my own journey and to help others build a stable, maintainable homelab without repeating my mistakes.
 **[Explore the Documentation](https://homelab.orkestack.com/)** │ **[See the Architecture](https://homelab.orkestack.com/docs/architecture)** │ **[Get Started](https://homelab.orkestack.com/docs/getting-started)**

## The Stack

 This lab is built on a foundation of powerful, open-source tools that work together to create a fully automated system.

| Category           | Tool                                                                                               | Description                                                   |
| ------------------ | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| **Hypervisor**     | [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment)                               | Manages the bare‑metal server and virtual machines.           |
| **OS**             | [Talos Linux](https://www.talos.dev/)                                                              | Minimal, secure, API‑managed operating system for Kubernetes. |
| **Infrastructure** | [OpenTofu](https://opentofu.org/)                                                                  | Declaratively provisions all infrastructure (IaC).            |
| **GitOps Engine**  | [Argo CD](https://argo-cd.readthedocs.io/en/stable/)                                               | Deploys and manages every app from this Git repo.             |
| **Networking**     | [Cilium](https://cilium.io/)                                                                       | eBPF‑based networking, security, and observability.           |
| **Storage**        | [Longhorn](https://longhorn.io/)                                                                   | Distributed block‑storage for stateful workloads.             |
| **Secrets**        | [External Secrets](https://external-secrets.io/latest/)                                            | Syncs secrets from Bitwarden into Kubernetes.                 |
| **Authentication** | [Authentik](https://goauthentik.io/)                                                               | Single Sign‑On (SSO) across all services.                     |
| **Certificates**   | [cert‑manager](https://cert-manager.io/)                                                           | Automates TLS certificate issuance and renewal.               |
| **API Gateway**    | [Gateway API](https://gateway-api.sigs.k8s.io/)                                                    | Next‑generation Kubernetes ingress and traffic management.    |
| **Database**       | [Zalando Postgres Operator](https://opensource.zalando.com/postgres-operator/docs/quickstart.html) | Manages highly‑available PostgreSQL clusters.                 |
| **CI / Checks**    | [Kubechecks](https://github.com/zapier/kubechecks)                                                 | Validates Argo CD changes before rollout.                     |
| **Tunnel**         | [Cloudflared](https://github.com/cloudflare/cloudflared)                                           | Creates secure Cloudflare tunnels for private services.       |

---

## Hardware

| Name   | Device                      | CPU                   | RAM           | Storage           | Purpose         |
|--------|-----------------------------|-----------------------|---------------|-------------------|-----------------|
| Host3  | Dell Precision Tower 7810   | 2× Xeon E5-2650 v3    | 78 GB DDR4    | 1x 1TB SSD - 1x 1TB Nvme SSD  | Hypervisor      |
| NAS    | Supermicro X8DTU            | Xeon E5620            | 16 GB DDR3    | 2x 3TB HDD Mirror   | Shared storage  |

---

## Quick Start

1. Make sure you have Proxmox access with your SSH key and install `opentofu`, `talosctl`, `kubectl`, and `argocd`. A little Kubernetes and Git know-how helps.
2. Clone this repository and follow the steps in the [Quick Start guide](https://homelab.orkestack.com/docs/getting-started).

---

## Why This Homelab?

- **Everything as Code:** I describe the entire lab in this repo. That gives me a full audit trail and lets me rebuild from scratch.
- **Automated from Day One:** Provisioning, deployments, and secrets run on autopilot.
- **Secure by Default:** Non-root containers, network policies, and single sign-on are baked in from the start.
- **Real-World Learning:** I'm applying enterprise ideas at home so I can tinker and pick up new skills.

## Who Is This For?

- **The Learner:** Understand how a production-grade Kubernetes stack really works.
- **The Tinkerer:** Deploy self-hosted apps on a stable base without endless upkeep.
- **The Pro:** Experiment with enterprise patterns or run a lab that "just works."

---

## Folder Structure

```shell
.
├── 📂 website                # Documentation site
├── 📂 k8s                 # Kubernetes manifests
│   ├── 📂 applications            # Applications
│   ├── 📂 infrastructure           # Infrastructure components
├── 📂 images                 # custom containers
└── 📂 tofu                # Tofu configuration
    └── 📂 talos       # Talos configuration
```

More details are in [Architecture](https://homelab.orkestack.com/docs/architecture).

---

## Roadmap

- [ ] Hybrid cloud backups
- [ ] Node autoscaling
- [ ] Additional monitoring dashboards

---

## Limitations

These docs describe how my cluster works today. Hardware or configuration changes
could make some steps outdated. Treat them as a reference to adapt rather than a
drop‑in manual.

---

## Contributing

You can contribute! I'm currently the sole maintainer and would welcome collaboration on anything from typo fixes to new applications.

1. **Read the Docs:** Start with the [Contributing Guide](.github/CONTRIBUTING.md) to learn the workflow and standards.
2. **Find an Issue:** Look for items labeled [good first issue](https://github.com/theepicsaxguy/homelab/labels/good%20first%20issue) to get started quickly.
3. **Suggest an Idea:** Have a feature request? [**Open an issue**](https://github.com/theepicsaxguy/homelab/issues/new?template=feature_request.md) and let's talk about it.

For questions, open an issue or start a discussion. More details are at [homelab.orkestack.com](https://homelab.orkestack.com).

---

## License

MIT – see [LICENSE](LICENSE) for details.

---

## Credits

Inspired by [Vehagn's Homelab](https://github.com/vehagn/homelab).