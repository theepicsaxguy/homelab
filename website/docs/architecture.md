---
title: System architecture overview
description: High-level diagram of how Talos, Kubernetes, and GitOps combine to run the homelab.
---

A concise map of the homelab stack—hypervisor to apps—so you always know **what runs where**.

## About the system architecture

This design marries an immutable Talos OS, Kubernetes, and GitOps to create a repeatable, auditable platform for self‑hosted services.

:::info
**Why you care:** Understanding the layers helps you troubleshoot faster and extend the platform safely.
:::

### Key layers in more detail

| Layer | What it does | Primary tool |
|-------|--------------|--------------|
| Hypervisor | Hosts all VMs | Proxmox VE |
| Node OS | Minimal, API‑managed Linux | Talos |
| Networking | eBPF CNI + policies | Cilium |
| Traffic routing | L4/L7 gateways | Gateway API |
| State sync | Declarative config | ArgoCD + Kustomize |
| Workloads | Apps + infra | Helm charts / YAML |

## Prerequisites

- Basic Kubernetes familiarity.
- Access to the repo for cross‑referenced manifests.

## Overview of data flow

1. **Git commit →** ArgoCD reconciles to cluster.
2. **Cilium eBPF →** handles service routing.
3. **Gateway API →** exposes traffic internally/externally.

## Dive deeper

- Provisioning flow: [Talos with OpenTofu](./tofu/opentofu-provisioning.md)
- Configuration flow: [Manage Kubernetes with GitOps](./k8s/manage-kubernetes.md)
- Application strategy: [Deploy and manage applications](./k8s/applications/application-management.md)

## Verify the architecture in your cluster

```bash
kubectl get nodes -o wide       # Talos nodes present?
argocd app list                 # All apps Synced/Healthy?
````
