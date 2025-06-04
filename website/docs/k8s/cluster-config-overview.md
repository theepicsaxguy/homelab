---
sidebar_position: 1
title: Cluster Configuration Overview
description: Overview of the Kubernetes cluster architecture and configuration management
---

# Kubernetes Cluster Configuration

This guide provides an overview of our Kubernetes cluster architecture and configuration management approach using GitOps with ArgoCD.

## Architecture Overview

Our infrastructure follows a strict GitOps approach with the following principles:

- Base configurations containing common settings and defaults
- Environment-specific overlays for customized deployments
- Progressive deployment through ArgoCD sync waves
- Resource graduation across environments when applicable

## Network Architecture

Our modern networking stack is built on:

- **Cilium** (see https://github.com/cilium/cilium/releases)
  - CNI for network connectivity
  - Service mesh capabilities
  - Network policies
  - Cluster mesh (future capability)

- **Gateway API**
  - Modern ingress management
  - Replaces traditional Ingress resources
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
