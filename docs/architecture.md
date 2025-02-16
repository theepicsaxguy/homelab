# Infrastructure Architecture Documentation

## Application Deployment Flow

### GitOps Pipeline

1. Infrastructure changes are committed to the repository
2. ArgoCD detects changes in the following paths:
   - `/k8s/apps/*` - Application workloads
   - `/k8s/infra/*` - Core infrastructure components
   - `/k8s/sets/*` - ApplicationSet configurations

### Deployment Process

1. Changes are validated through ApplicationSets
2. ArgoCD synchronizes the desired state
3. Components are deployed in the following order:
   - Core Infrastructure (CNI, Storage, Auth)
   - Platform Services (Monitoring, Databases)
   - Applications (Media, Home Automation)

## Infrastructure Provisioning

### Prerequisites

- Proxmox VE cluster
- Network connectivity (10.25.150.0/24)
- DNS configuration for api.kube.pc-tips.se

### Provisioning Steps

1. **Cluster Bootstrap**
   ```bash
   cd tofu/kubernetes
   tofu init && tofu apply
   ```
2. **Post-Installation**
   - ArgoCD bootstraps automatically
   - Core infrastructure components deploy
   - Application workloads roll out

## Authentication Setup

### Components

- Keycloak: Primary identity provider
- Authelia: Secondary authentication layer
- LLDAP: Lightweight directory service

### Security Boundaries

1. External perimeter (Cloudflared)
2. Network layer (Cilium)
3. Service mesh (mTLS)
4. Application authentication

## Dependencies Map

### Core Infrastructure

- Cilium CNI ← Network connectivity
- CloudNative PG ← Database workloads
- Cert-Manager ← TLS certificates
- SealedSecrets ← Secret management

### Application Stack

- Authentication ← Keycloak, Authelia
- Storage ← TrueNAS, Proxmox CSI
- Monitoring ← Prometheus Stack
- DNS ← AdGuardHome

## Resource Requirements

### Control Plane

- 3 nodes
- 4 CPU per node
- 2480MB RAM per node

### Worker Nodes

- Variable configuration
- GPU passthrough support
- High-performance storage access

## Scaling Considerations

### Horizontal Scaling

- Worker nodes can be added through Talos
- ApplicationSets support multi-instance deployments
- Database clustering through CloudNative PG

### Vertical Scaling

- Node resources manageable through Proxmox
- Application resources defined in manifests
- Storage expandable through CSI

## Disaster Recovery

### Backup Components

1. Talos system state
2. Kubernetes manifests (GitOps)
3. Application data (CSI volumes)
4. Database backups (CloudNative PG)

### Recovery Procedures

1. Infrastructure recovery through GitOps
2. State restoration from backups
3. Service validation and testing

## Maintenance Procedures

### Regular Maintenance

1. System updates (Talos, managed by configuration)
2. Application updates (managed by Renovate)
3. Certificate rotation (automated by cert-manager)
4. Database maintenance (automated by operators)

### Upgrade Process

1. Test changes in development environment
2. Apply infrastructure updates
3. Validate core services
4. Roll out application updates

## Troubleshooting Guide

### Common Issues

1. Network connectivity

   - Check Cilium status
   - Verify BGP peering
   - Validate DNS resolution

2. Application deployment

   - Check ArgoCD sync status
   - Verify ApplicationSet configuration
   - Review pod events and logs

3. Authentication
   - Validate Keycloak realms
   - Check Authelia configuration
   - Verify LLDAP connectivity

### Monitoring

- Prometheus metrics
- Hubble network flows
- Loki logs
- Grafana dashboards
