# Service Registry

## Infrastructure Services

### Core Platform

#### Authentication (Authelia)

- **URL**: authelia.kube.pc-tips.se
- **Description**: Single sign-on and 2FA provider
- **Dependencies**:
  - LDAP
  - Redis
  - PostgreSQL
- **Integration Points**:
  - Gateway API for auth
  - Prometheus metrics
  - Loki logging

#### Certificate Management (cert-manager)

- **Version**: v1.17.1
- **Description**: Automated certificate management
- **Dependencies**:
  - Cloudflare DNS
  - Gateway API
- **Integration Points**:
  - Prometheus metrics
  - Kubernetes API
  - DNS providers

### Networking

#### CNI (Cilium)

- **Version**: v1.17+
- **Description**: Network and service mesh provider
- **Features**:
  - Gateway API implementation
  - Service mesh capabilities
  - Network policies
  - Load balancing
- **Integration Points**:
  - Prometheus metrics
  - Hubble UI
  - Gateway API
  - eBPF monitoring

#### DNS (CoreDNS)

- **Version**: 1.11.1
- **Description**: Cluster DNS provider
- **Configuration**:
  - Custom domain: kube.pc-tips.se
  - Pod DNS policy
  - DNS forwarding
- **Integration Points**:
  - Prometheus metrics
  - Health monitoring
  - Gateway API

### Storage

#### Primary Storage (Longhorn)

- **Version**: v1.8.1
- **Description**: Distributed block storage
- **Features**:
  - Volume replication
  - Backup management
  - Snapshot support
- **Integration Points**:
  - Prometheus metrics
  - Volume health monitoring
  - Backup verification

### Monitoring Stack

#### Metrics (Prometheus)

- **Description**: Time-series metrics collection
- **Components**:
  - Prometheus server
  - AlertManager
  - Node exporter
  - kube-state-metrics
- **Integration Points**:
  - Grafana dashboards
