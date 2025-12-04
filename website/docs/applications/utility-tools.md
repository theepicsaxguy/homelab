---
sidebar_position: 2
title: Utility Tools
description: Overview of utility and development tools deployed in the cluster
---

# Utility and Development Tools

This document covers the utility tools and applications deployed in my cluster for development and operational support.

## Core Tools

### IT Tools

- **Purpose**: Collection of utilities for IT operations
- **Access**: https://it-tools.your.domain.tld (via Authentik SSO)
- **Features**:
  - String manipulation
  - Encoding/decoding
  - Network tools
  - Development utilities

### Unrar Service

- **Purpose**: Archive extraction utility
- **Features**:
  - RAR file extraction
  - Automated processing
  - Integration with media stack

## Infrastructure Configuration

### Resource Allocation

| Application | CPU Request | CPU Limit | Memory Request | Memory Limit |
| ----------- | ----------- | --------- | -------------- | ------------ |
| IT Tools    | 75m         | 250m      | 100Mi          | 256Mi        |
| Unrar       | 50m         | 200m      | 64Mi           | 128Mi        |

### Network Access

All tools are exposed through Cilium Gateway API with the following configurations:

```yaml
Gateway Configuration:
  - IT Tools:
      host: it-tools.your.domain.tld
      service: it-tools
      port: 80
      backendRefs:
        - name: ak-outpost-authentik-embedded-outpost
          namespace: auth
          port: 9000 # Authentik SSO

  - Unrar:
      host: internal only
      service: unrar
      port: 80
      backendRefs:
        - name: unrar
          port: 80
          # Internal service only
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
      - from: ak-outpost-authentik-embedded-outpost
        ports: [80]
  unrar:
    ingress:
      - from: media-namespace
        ports: [80]
```

## Monitoring & Maintenance

### Health Checks

The unrar deployment checks for a running extraction process and falls back to a timestamp check on `/tmp/healthy`. This prevents needless restarts when large archives take a while.

```yaml
livenessProbe:
  exec:
    command:
      - /bin/sh
      - -c
      - "pgrep -x unrar >/dev/null || find /tmp/healthy -mmin -le 30"
  initialDelaySeconds: 60
  periodSeconds: 60
  timeoutSeconds: 10
```

All deployments include similar probes to keep services responsive.

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
