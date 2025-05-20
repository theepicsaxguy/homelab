---
sidebar_position: 2
title: Utility Tools
description: Overview of utility and development tools deployed in the cluster
---

# Utility and Development Tools

This document covers the utility tools and applications deployed in our cluster for development and operational support.

## Core Tools

### IT Tools

- **Purpose**: Collection of utilities for IT operations
- **Access**: https://it-tools.pc-tips.se (via Authentik SSO)
- **Features**:
  - String manipulation
  - Encoding/decoding
  - Network tools
  - Development utilities

### Whoami Service

- **Purpose**: Testing and debugging service
- **Features**:
  - HTTP request inspection
  - Headers display
  - Connection info
  - Load balancing verification

### Unrar Service

- **Purpose**: Archive extraction utility
- **Features**:
  - RAR file extraction
  - Automated processing
  - Integration with media stack

## Infrastructure Configuration

### Resource Allocation

| Application | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------------|-------------|-----------|----------------|--------------|
| IT Tools    | 100m        | 500m      | 128Mi         | 256Mi       |
| Whoami      | 50m         | 100m      | 64Mi          | 128Mi       |
| Unrar       | 100m        | 500m      | 128Mi         | 256Mi       |

### Network Access

All tools are exposed through Cilium Gateway API with the following configurations:

```yaml
Gateway Configuration:
  - IT Tools:
      host: it-tools.pc-tips.se
      service: it-tools
      port: 80
      auth: true  # Authentik SSO required
  
  - Whoami:
      host: whoami.pc-tips.se
      service: whoami
      port: 80
      auth: true
  
  - Unrar:
      host: internal only
      service: unrar
      port: 80
      auth: false  # Internal service only
```

## Security Configuration

### Authentication

- IT Tools and public services integrated with Authentik SSO
- Internal services restricted by network policies
- Zero-trust security model

### Network Policies

```yaml
policies:
  it-tools:
    ingress:
      - from: authentik-proxy
        ports: [80]
  unrar:
    ingress:
      - from: media-namespace
        ports: [80]
```

## Monitoring & Maintenance

### Health Checks

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 30

readinessProbe:
  httpGet:
    path: /ready
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 10
```

### Resource Monitoring

- CPU and memory utilization
- Network traffic patterns
- Response times
- Error rates

## Troubleshooting Guide

### Common Issues

1. **Authentication Failures**
   - Verify Authentik proxy configuration
   - Check service account tokens
   - Validate network policies

2. **Performance Issues**
   - Review resource utilization
   - Check node capacity
   - Validate network connectivity

3. **Service Unavailability**
   - Verify pod status
   - Check Gateway configuration
   - Review service endpoints

## Future Enhancements

- [ ] Add metrics visualization tools
- [ ] Implement advanced debugging tools
- [ ] Enhanced logging capabilities
- [ ] Integration with cluster monitoring

## Best Practices

1. **Resource Management**
   - Set appropriate resource limits
   - Monitor usage patterns
   - Implement HPA when needed

2. **Security**
   - Regular security updates
   - Minimal permission model
   - Network isolation

3. **Maintenance**
   - Regular health checks
   - Automated updates
   - Backup procedures if applicable
