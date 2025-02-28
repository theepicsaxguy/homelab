# Gateway API Configuration

## Overview

The cluster uses Gateway API with Cilium as the gateway controller, providing a modern approach to service networking
and ingress management.

## Gateway Architecture

### Components

- Cilium Gateway Controller
- Gateway API CRDs
- Cert-manager for SSL
- External-DNS for DNS management
- Authelia for authentication

### Gateway Classes

The cluster uses a single GatewayClass `cilium` with three gateway types:

- External Gateway (Internet-facing services)
- Internal Gateway (Cluster-local services)
- TLS Passthrough Gateway (Direct TLS termination)

## Standard Configurations

### External Gateway

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
```
