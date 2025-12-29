# Infrastructure Network - Component Guidelines

SCOPE: Cluster networking, CNI, DNS, and ingress
INHERITS FROM: ../AGENTS.md
TECHNOLOGIES: Cilium (CNI), CoreDNS, Gateway API, Cloudflared, Cert Manager integration

## INHERITANCE EXPLANATION

This file inherits from k8s/AGENTS.md and root AGENTS.md, which means:
- General Kubernetes patterns from k8s/AGENTS.md already apply (storage, ExternalSecrets, GitOps)
- Universal conventions from root AGENTS.md already apply (commits, PRs, documentation style)
- This file adds network-specific patterns
- References to parent files are for additional details only

## COMPONENT CONTEXT

Purpose:
Manage cluster networking including CNI configuration, DNS resolution, ingress/gateway routing, and external access tunnels.

Boundaries:
- Handles: CNI installation, network policies, DNS configuration, Gateway API routing, external tunnels
- Does NOT handle: Application HTTPRoutes (see applications/), controller certificates (see controllers/)
- Integrates with: controllers/ (for Cert Manager), applications/ (for HTTPRoute references)

Architecture:
- `cilium/` - Cilium CNI (Container Network Interface)
- `coredns/` - Cluster DNS service
- `gateway/` - Gateway API routing configuration
- `cloudflared/` - Cloudflare tunnel for external access

## QUICK-START COMMANDS

```bash
# Build all network components
kustomize build --enable-helm k8s/infrastructure/network

# Build specific component
kustomize build --enable-helm k8s/infrastructure/network/<component>

# Validate network manifests
kustomize build --enable-helm k8s/infrastructure/network | yq eval -P -

# Check Cilium status
cilium status

# Check Gateway API resources
kubectl get gateway -n gateway
kubectl get httproute -A
```

## COMPONENT-SPECIFIC PATTERNS

### Cilium (CNI)

**Purpose**: Container Network Interface providing eBPF-based networking, observability, and security.

**Installation**:
- Helm chart version 1.18.5
- `kubeProxyReplacement: true` - Replaces kube-proxy with eBPF implementation
- Deployed in `kube-system` namespace

**Key Configuration**:
- **Talos Compatibility**:
  - `k8sServiceHost: localhost`, `k8sServicePort: 7445` (Talos API server)
  - Host legacy routing enabled for host DNS forwarding
  - `bpf.hostLegacyRouting: true` - Required for Talos host DNS forwarding
- **IPAM**: Kubernetes IPAM mode
- **Security Context**: Specific capabilities for cilium agent
- **Auto-Rollout**: Enabled for ConfigMap changes

**Network Configuration**:
- **IP Pool**: `10.25.150.220-10.25.150.255` for LoadBalancer IPs
- **BGP Announcements**: Enabled for external service exposure
- **Multicast**: Disabled (not needed)

**Cilium 1.18 Known Issue Fixed**:
- Version 1.17.x dropped pure-TCP Gateway listeners
- Affects MQTT service in `applications/automation/mqtt/`
- Upgrade to 1.18+ resolves this issue
- Remove HTTPRoute workaround after upgrading

### CoreDNS

**Purpose**: Cluster DNS resolution for Kubernetes services and external domains.

**Configuration**:
- Deployment with PodDisruptionBudget for high availability
- ServiceAccount with ClusterRole/ClusterRoleBinding for RBAC
- Custom ConfigMap for DNS forwarding rules
- ClusterRole: View all pods and services for DNS resolution

**Integration**:
- Resolves Kubernetes service names to cluster IPs
- Forwards external queries to upstream DNS servers
- Used by all applications for service discovery

### Gateway API

**Purpose**: Manage HTTP/HTTPS ingress routing using Gateway API standard.

**Gateways**:
- **External Gateway** (`gw-external.yaml`):
  - IP: `10.25.150.222`
  - Hostnames: `*.peekoff.com`, `peekoff.com`, `*.goingdark.social`, `goingdark.social`
  - Port: 443 (HTTPS)
  - TLS certificates: `cert-peekoff`, `cert-goingdark` (from Cert Manager)
  - Routes: Accepts from All namespaces
- **Internal Gateway** (`gw-internal.yaml`):
  - Internal-only traffic
  - No external exposure
- **TLS Passthrough Gateway** (`gw-tls-passthrough.yaml`):
  - For services requiring TLS passthrough

**Certificate Management**:
- Certificates managed by Cert Manager (see controllers/)
- Stored as Secrets in `gateway` namespace
- Referenced by Gateway listeners

**Application HTTPRoutes**:
- Applications create HTTPRoute resources referencing Gateway
- Gateway filters routes based on hostname and namespace
- Example: `applications/automation/frigate/http-route.yaml`

### Cloudflared

**Purpose**: Cloudflare tunnel for secure external access without port forwarding.

**Configuration**:
- DaemonSet running Cloudflared agent
- Tunnel credentials managed via Secret
- ConfigMap for tunnel configuration
- Namespace: `cloudflared`

**Use Case**:
- Provides secure external access to cluster services
- Avoids opening ports on firewall
- Uses Cloudflare's global network

## NETWORKING PATTERNS

### Service Exposure Pattern

Applications expose services through Gateway API:

1. **Create Service** in application namespace (ClusterIP or NodePort)
2. **Create HTTPRoute** in application namespace
3. **Reference Gateway** from `gateway` namespace
4. **Cert Manager** provisions TLS certificate for hostname
5. **Gateway** routes HTTPS traffic to service

Example HTTPRoute structure:
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: myapp
  namespace: myapp
spec:
  parentRefs:
    - name: external
      namespace: gateway
  hostnames:
    - myapp.peekoff.com
  rules:
    - backendRefs:
        - name: myapp-service
          port: 80
```

### DNS Resolution Pattern

**Internal DNS** (CoreDNS):
- Service names: `<service-name>.<namespace>.svc.cluster.local`
- Short form: `<service-name>.<namespace>` (within cluster)
- Resolved to ClusterIP

**External DNS** (Cloudflare):
- DNS records managed by Crossplane (see controllers/)
- Records point to Gateway IP or Cloudflare tunnel

### LoadBalancer IP Allocation

**Cilium LoadBalancerIPPool**:
- Pool: `10.25.150.220-10.25.150.255`
- Allocate IPs by annotating Services with `io.cilium/lb-ipam-ips: 10.25.150.XXX`
- Gateway uses `10.25.150.222` for external access
- Other services use IPs from this pool as needed

### Network Policy Pattern

Cilium enforces network policies by default:
- Default deny all ingress/egress (if policy is strict)
- Explicitly allow required traffic
- Use CiliumNetworkPolicy resources for fine-grained control
- See application manifests for examples

## OPERATIONAL PATTERNS

### Cilium Upgrades

**Upgrade Process**:
1. Check Cilium release notes for breaking changes
2. Update Helm chart version in `cilium/kustomization.yaml`
3. Review `cilium/values.yaml` for deprecated options
4. Apply via GitOps
5. Monitor `cilium status` during upgrade
6. Verify all pods can communicate

**Rollback**:
- Use Helm rollback if upgrade fails
- Check Cilium agent logs for errors

### Network Troubleshooting

**DNS Issues**:
```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

**Connectivity Issues**:
```bash
# Check Cilium status
cilium status

# Check Cilium agent logs
kubectl logs -n kube-system -l k8s-app=cilium -c cilium-agent

# Check network policies
kubectl get cnp -A

# Test pod-to-pod connectivity
kubectl exec -it <pod> -- ping <other-pod-ip>
```

**Gateway Issues**:
```bash
# Check Gateway status
kubectl get gateway -n gateway

# Describe Gateway
kubectl describe gateway -n gateway <name>

# Check HTTPRoute status
kubectl get httproute -A

# Describe HTTPRoute
kubectl describe httproute -n <namespace> <name>
```

**Cilium 1.17 TCP Listener Bug**:
- Symptom: MQTT TCP listener dropped
- Workaround: Use HTTPRoute until upgrade to 1.18+
- Fix: Upgrade Cilium to 1.18 or later

## SECURITY BOUNDARIES

Never expose services to public internet without authentication. Use Authentik SSO where applicable.

Never use HTTP for external traffic. Always use HTTPS with TLS certificates.

Never expose database services directly. Keep databases internal-only.

Never disable Cilium network policies without authorization. Policies enforce security boundaries.

Never use wildcard DNS certificates for production. Issue specific certificates per service.

Never open ports on firewall without justification. Use Gateway API and Cloudflared for secure access.

## TESTING

### Network Connectivity Tests

```bash
# Test DNS resolution
kubectl run -it --rm dns-test --image=busybox --restart=Never -- nslookup kubernetes.default

# Test pod-to-pod connectivity
kubectl run -it --rm ping-test --image=busybox --restart=Never -- ping <service-name>.<namespace>

# Test external connectivity
kubectl run -it --rm curl-test --image=curlimages/curl --restart=Never -- curl https://google.com

# Test Gateway routing
curl -H "Host: myapp.peekoff.com" https://<gateway-ip>
```

### Cilium Connectivity Tests

```bash
# Cilium connectivity test (requires connectivity-check pod)
kubectl -n kube-system exec ds/cilium -- cilium connectivity test
```

### Certificate Validation

```bash
# Check Certificate status
kubectl get certificate -A

# Check CertificateRequest status
kubectl get certificaterequest -A

# Describe Certificate for details
kubectl describe certificate -n <namespace> <name>
```

## ANTI-PATTERNS

Never skip TLS certificates for external services. Always use HTTPS with valid certificates.

Never bypass Gateway API for external access. Use HTTPRoutes for consistent routing.

Never disable Cilium kubeProxyReplacement. eBPF provides better performance and observability.

Never manually configure CoreDNS. Let Helm chart manage CoreDNS configuration.

Never use NodePort for external access. Use Gateway API instead.

Never allow unrestricted network policies. Explicitly define required traffic flows.

## REFERENCES

For Kubernetes domain patterns, see k8s/AGENTS.md

For Cert Manager integration, see k8s/infrastructure/controllers/AGENTS.md

For application HTTPRoutes, see k8s/applications/*/http-route.yaml

For Cilium documentation, see https://docs.cilium.io

For Gateway API specification, see https://gateway-api.sigs.k8s.io

For commit message format, see root AGENTS.md
