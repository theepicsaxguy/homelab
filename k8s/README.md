# Kubernetes Configuration

This directory contains the GitOps configuration for our entire cluster, managed through ArgoCD.

## Architecture Overview

Our infrastructure follows a strict GitOps approach with:

- Base configurations with common settings
- Environment-specific overlays with customizations
- Progressive deployment through sync waves
- Resource graduation across environments

## Environment Strategy

- **Development**: Fast iteration, relaxed limits
- **Staging**: Production-like with HA
- **Production**: Full HA, strict limits

## Network Architecture

Our networking stack is built on:

- **Cilium** (v1.17+) for CNI and service mesh capabilities
- **Gateway API** for modern ingress management
- Structured gateway classes:
  - External (Internet-facing services)
  - Internal (Cluster-local services)
  - TLS Passthrough (Direct TLS termination)

## Gateway Structure

```yaml
Gateways:
  - gw-external: # Internet-facing services
      - HTTP/HTTPS routes
      - Load balancing
  - gw-internal: # Cluster-local services
      - Internal DNS
      - Service mesh integration
  - gw-tls-passthrough: # Direct TLS termination
      - Secure services
      - Certificate management
```

To safely reboot a node.

For example:

´´´

kubectl cordon work-00 kubectl drain work-00 --ignore-daemonsets --delete-emptydir-data

´´´ ´´´

talosctl reboot --nodes 10.25.150.21

´´´ kubectl uncordon work-00
