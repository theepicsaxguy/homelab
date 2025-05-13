---
slug: welcome-homelab
title: Welcome to My Kubernetes Homelab Journey!
authors: [theepicsaxguy]
tags: [homelab, kubernetes, gitops, opentofu, talos, argocd, introduction]
---

Welcome to the official blog for my Kubernetes-based homelab project! This space will document the evolution, challenges, and learnings from building and maintaining a modern, GitOps-driven infrastructure right at home.

This project is all about leveraging enterprise-grade patterns and open-source tooling to create a robust, automated, and fun platform for self-hosting various services. If you're passionate about Kubernetes, infrastructure-as-code, and pushing the boundaries of what a homelab can be, you're in the right place.

## What's This Homelab All About?

At its core, this homelab is built upon a few key principles and technologies:

* **Kubernetes as the Orchestrator:** Using [Talos OS](https://www.talos.dev/) for a minimal, immutable, and API-driven Kubernetes experience.
* **Infrastructure as Code (IaC):** Leveraging [OpenTofu](https://opentofu.org/) (a fork of Terraform) to provision and manage the underlying virtual machines on Proxmox.
* **GitOps for Everything:** [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) is the heart of our deployment strategy, ensuring that the state of our cluster (from infrastructure components to applications) is defined declaratively in this Git repository.
* **Declarative Configuration:** [Kustomize](https://kustomize.io/) helps manage Kubernetes manifest variations without excessive templating.
* **Automation:** From CI/CD pipelines with GitHub Actions to automated certificate management with Cert-Manager.

The goal is to create a system that is not only powerful but also resilient, auditable, and relatively easy to manage once set up.

## What to Expect From This Blog

This blog will serve as a chronicle of this homelab's development. You can expect posts on topics such as:

* **Deep Dives:** Detailed explanations of specific components, configurations, and architectural choices (e.g., network setup with Cilium, storage with Longhorn, authentication with Authentik).
* **Tutorials & How-Tos:** Step-by-step guides for setting up new services or implementing particular features.
* **Troubleshooting & Learnings:** Sharing challenges encountered and how they were overcome – because no homelab journey is without its bumps!
* **New Additions & Upgrades:** Updates on new applications being self-hosted or major infrastructure upgrades.
* **Project Updates:** Milestones, refactoring efforts, and new documentation highlights.

## Exploring the Repository

All the configurations and documentation for this homelab are publicly available in the [GitHub repository](https://github.com/theepicsaxguy/homelab).

Feel free to browse:

* The `/k8s/` directory for all Kubernetes manifests, managed by ArgoCD.
* The `/tofu/` directory for the OpenTofu code that provisions the Talos cluster.
* The `/website/docs/` for comprehensive documentation on architecture, setup, and management.

## Getting Involved

This project is a personal learning and exploration endeavor, but feedback, suggestions, and discussions are always welcome! Feel free to open an [Issue](https://github.com/theepicsaxguy/homelab/issues) if you spot something amiss or have an idea.

Stay tuned for more updates as this homelab continues to grow and evolve!
