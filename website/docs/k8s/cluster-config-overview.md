---
sidebar_position: 1
title: Cluster Configuration Overview
description: Overview of the Kubernetes cluster architecture and configuration management
---

# Kubernetes Cluster Configuration

This guide provides an overview of my Kubernetes cluster architecture and configuration management approach using GitOps with ArgoCD.

## Architecture Overview

My infrastructure follows a strict GitOps approach with the following principles:

- Base configurations containing common settings and defaults
- Environment-specific overlays for customized deployments
- Progressive deployment through ArgoCD sync waves
- Resource graduation across environments when applicable

## Network Architecture

My modern networking stack is built on:

- **Cilium** (see https://github.com/cilium/cilium/releases)
  - CNI for network connectivity
  - Service mesh capabilities
  - Network policies
  - Cluster mesh (future capability)

- **Gateway API**
  - Modern ingress management
  - Enhanced traffic routing capabilities

### Gateway Classes and Structure

```yaml
Gateway Classes:
  external:            # Internet-facing services
    - HTTP/HTTPS routes
    - Load balancing
    - External DNS integration
  internal:           # Cluster-local services
    - Internal DNS resolution
    - Service mesh integration
    - Cross-namespace communication
  tls-passthrough:    # Direct TLS termination
    - Secure services
    - Certificate management via cert-manager
```

## Node Management

### Safe Node Drainage and Reboot

To safely reboot a node, follow these steps:

1. Cordon the node to prevent new workloads:
```console
kubectl cordon node-name
```

2. Drain workloads (ignore DaemonSets, handle ephemeral storage):
```console
kubectl drain node-name --ignore-daemonsets --delete-emptydir-data
```

3. Reboot using talosctl (replace IP with your node's IP):
```console
talosctl reboot --nodes 10.25.150.21
```

4. Uncordon the node after it's back online:
```console
kubectl uncordon node-name
```

### Node Maintenance Best Practices

- Always drain nodes before maintenance
- Verify pod rescheduling before proceeding
- Monitor node health after maintenance
- Ensure cluster has capacity for workload redistribution
- Consider impact on stateful applications

### Pod Disruption Budgets

PodDisruptionBudgets (PDBs) keep critical pods running during a voluntary
node drain. Most of my applications run a single replica, so each namespace
defines a simple PDB with `maxUnavailable: 0`. When you drain a node hosting
one of these pods, the operation waits until another replica is available or the
PDB is removed. This prevents accidental outages during routine maintenance.
Multi-replica services like CoreDNS and the monitoring stack also
have PDBs defined to ensure at least one instance stays online during upgrades.
Argo CD runs in high availability mode, and the Helm chart automatically
creates PDBs for each component. The Cloudflare tunnel doesn't use a PDB; its
DaemonSet rolls out pods one at a time with `maxUnavailable: 1`.
