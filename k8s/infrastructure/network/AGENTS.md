# Network Infrastructure - External Access Hub

SCOPE: Service exposure, DNS, and external access workflows
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: Gateway API, Cilium, CoreDNS, Cloudflared

## SERVICE EXPOSURE WORKFLOWS

### HTTPS Service Setup (Most Common)

#### Step 1: Create Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: <app-name>
  namespace: <app-namespace>
spec:
  selector:
    app.kubernetes.io/name: <app-name>
  ports:
  - port: 80
    targetPort: <app-port>
    protocol: TCP
```

#### Step 2: Create HTTPRoute
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: <app-name>
  namespace: <app-namespace>
spec:
  parentRefs:
  - name: external  # IP: 10.25.150.222
    namespace: gateway
    sectionName: https
  - name: internal  # Internal traffic only
    namespace: gateway
  hostnames:
  - "<app-name>.peekoff.com"
  - "<app-name>.goingdark.social"  # optional
  rules:
  - matches:
    - path:
        type: Prefix
        value: /
    backendRefs:
    - name: <app-name>
      port: 80
```

#### Step 3: DNS Configuration
1. Add A record in Cloudflare:
   - Name: `<app-name>.peekoff.com`
   - IP: `10.25.150.222`
   - TTL: Auto
   - Proxy: DNS only (not cloudflare proxy)

2. Certificate auto-provisioned by Cert Manager
3. Gateway routes HTTPS traffic to your service

#### Step 4: Validation
```bash
# Check HTTPRoute status
kubectl get httproute -n <app-namespace> <app-name>

# Test from external
curl -H "Host: <app-name>.peekoff.com" https://10.25.150.222

# Check certificate
kubectl get certificate -n <app-namespace>
```

### Internal Service Access

#### Step 1: Create Service (ClusterIP)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: <app-name>
  namespace: <app-namespace>
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: <app-name>
  ports:
  - port: <service-port>
    targetPort: <app-port>
```

#### Step 2: Access Pattern
Internal DNS: `<app-name>.<app-namespace>.svc.cluster.local`

### Cloudflare Tunnel Integration

#### Step 1: Install Cloudflared
Cloudflared runs as DaemonSet in `cloudflared` namespace.

#### Step 2: Configure Tunnel
Add to cloudflared ConfigMap:
```yaml
ingress:
  - hostname: <app-name>.peekoff.com
    service: http://<app-name>.<app-namespace>.svc.cluster.local:80
```

#### Step 3: DNS Configuration
1. Create CNAME record in Cloudflare:
   - Name: `<app-name>.peekoff.com`
   - Target: `<tunnel-id>.cfargotunnel.com`
   - Proxy: Cloudflare proxy (orange cloud)

## NETWORK COMPONENTS

### Cilium (CNI)
- Version: 1.18.5+ (1.17.x has TCP listener bug)
- Replaces kube-proxy with eBPF
- IP Pool for LoadBalancers: `10.25.150.220-10.25.150.255`

### Gateway API
- **External Gateway**: `gateway/external` (IP: 10.25.150.222)
- **Internal Gateway**: `gateway/internal`
- **TLS Passthrough**: `gateway/tls-passthrough`

### CoreDNS
- Cluster DNS resolution
- Resolves: `<service>.<namespace>.svc.cluster.local`

## TROUBLESHOOTING COMMANDS

### Service Issues
```bash
# Check service endpoints
kubectl get endpoints -n <namespace> <service-name>

# Test service connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://<service-name>.<namespace>.svc.cluster.local

# Check service logs
kubectl logs -n <namespace> -l app.kubernetes.io/name=<app-name>
```

### Gateway Issues
```bash
# Check gateway status
kubectl get gateway -n gateway
kubectl describe gateway -n gateway external

# Check HTTPRoute status
kubectl get httproute -A
kubectl describe httproute -n <namespace> <route-name>

# Test routing
curl -H "Host: <hostname>" https://10.25.150.222
```

### DNS Issues
```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test DNS resolution
kubectl run -it --rm dns-test --image=busybox --restart=Never -- \
  nslookup kubernetes.default.svc.cluster.local

# Test external DNS
kubectl run -it --rm dns-test --image=busybox --restart=Never -- \
  nslookup google.com
```

### Certificate Issues
```bash
# Check certificate status
kubectl get certificate -A
kubectl describe certificate -n <namespace> <cert-name>

# Check certificate requests
kubectl get certificaterequest -A
```

## NETWORK ANTI-PATTERNS

### Security
- Never expose databases directly - keep internal-only
- Never skip TLS certificates - always use HTTPS
- Never use NodePort for external access - use Gateway API
- Never open firewall ports - use Gateway API and Cloudflared

### Configuration
- Never bypass Gateway API - use HTTPRoutes
- Never disable Cilium kubeProxyReplacement
- Never manually configure CoreDNS
- Never use wildcard DNS certificates

## KNOWN ISSUES

### Cilium 1.17.x TCP Listener Bug
Version 1.17.x broke TCP Gateway listeners. Use 1.18+ for MQTT services.

## REFERENCES

For application patterns: `k8s/AGENTS.md`
For certificate management: `k8s/infrastructure/controllers/AGENTS.md`
For Cilium documentation: https://docs.cilium.io