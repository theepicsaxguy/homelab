---
title: 'OpenHands AI Coding Agent'
---

OpenHands is an open-source AI coding agent that helps accelerate development work by automating coding tasks. The
deployment runs as a single replica with a Docker-in-Docker sidecar to provide isolated container execution for agent
sessions.

## Architecture

OpenHands creates a new Docker container for each agent session. To avoid mounting the host Docker socket (a security
risk), this deployment uses Docker-in-Docker (DinD) as a sidecar container. The DinD sidecar provides an isolated Docker
daemon that OpenHands uses to spawn agent containers.

```yaml
# k8s/applications/ai/openhands/deployment.yaml
containers:
  - name: openhands
    image: docker.all-hands.dev/all-hands-ai/openhands:0.24
    env:
      - name: DOCKER_HOST
        value: 'unix:///var/run/docker.sock'
  - name: dind
    image: docker:29-dind
    securityContext:
      allowPrivilegeEscalation: true
      capabilities:
        add:
          - SYS_ADMIN
        drop:
          - ALL
      seccompProfile:
        type: Unconfined
```

The DinD container requires the `SYS_ADMIN` capability to run Docker inside Kubernetes. Instead of using full
`privileged: true` mode, it uses specific capabilities to comply with the baseline Pod Security Standard. An init
container waits for the Docker socket to be ready before starting OpenHands.

## Storage

A 10Gi PersistentVolumeClaim stores agent state and workspace files across pod restarts:

```yaml
# k8s/applications/ai/openhands/pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: openhands-state
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 10Gi
```

The volume is mounted at `/openhands-state` with workspace files stored in `/openhands-state/workspace`.

## LiteLLM Integration

OpenHands is configured to use the cluster's LiteLLM proxy service for LLM access. This provides unified access to
multiple LLM providers with caching, rate limiting, and cost tracking.

```yaml
# k8s/applications/ai/openhands/deployment.yaml
env:
  - name: LLM_BASE_URL
    value: 'http://litellm.litellm.svc.cluster.local/v1'
  - name: LLM_API_KEY
    valueFrom:
      secretKeyRef:
        name: app-openhands-litellm-api-key
        key: LITELLM_API_KEY
```

The ExternalSecret `app-openhands-litellm-api-key` sources the LiteLLM master key from Bitwarden:

```yaml
# k8s/applications/ai/openhands/externalsecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-openhands-litellm-api-key
  namespace: openhands
spec:
  secretStoreRef:
    name: bitwarden-backend
    kind: ClusterSecretStore
  target:
    name: app-openhands-litellm-api-key
  data:
    - secretKey: LITELLM_API_KEY
      remoteRef:
        key: app-litellm-master-key
```

Benefits of using LiteLLM:

- **Reduced latency**: Cluster-local communication instead of external API calls
- **Cost tracking**: Centralized logging and spend analytics
- **Caching**: Redis-backed response caching reduces API costs
- **Multi-provider**: Access to all LLM providers configured in LiteLLM

## Networking

The Service uses `ClientIP` session affinity with a 3-hour timeout to maintain user sessions:

```yaml
# k8s/applications/ai/openhands/service.yaml
spec:
  type: ClusterIP
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
```

External access is provided through the HTTPRoute on `openhands.peekoff.com`:

```yaml
# k8s/applications/ai/openhands/httproute.yaml
spec:
  parentRefs:
    - name: external
      namespace: gateway
      sectionName: https
  hostnames:
    - openhands.peekoff.com
```

### Network Policies

A NetworkPolicy restricts traffic to only necessary services:

```yaml
# k8s/applications/ai/openhands/networkpolicy.yaml
spec:
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: gateway
      ports:
        - protocol: TCP
          port: 3000
  egress:
    # DNS, LiteLLM access, and external HTTPS for dependencies
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: litellm
```

The policy allows:

- **Ingress**: Only from the `gateway` namespace on port 3000
- **Egress**: DNS resolution, LiteLLM service access, and HTTPS for downloading models/dependencies

## Security Considerations

### Pod Security Standards

The namespace enforces the `baseline` Pod Security Standard. The DinD sidecar container uses the `SYS_ADMIN` capability
instead of full privileged mode, which allows it to function while complying with baseline security requirements. This
approach:

- Avoids using `privileged: true` which violates baseline policy
- Grants only the specific capability needed for Docker operations
- Uses `Unconfined` seccomp profile required for container runtime operations
- Drops all other unnecessary capabilities

The OpenHands main container follows security best practices:

- Runs as non-root user (UID 1000)
- Drops all capabilities
- Uses RuntimeDefault seccomp profile
- Disables privilege escalation

Note: `readOnlyRootFilesystem` is set to `false` for the OpenHands container because the application requires write
access to multiple directories for runtime operation.

### Isolated Execution

Using DinD instead of mounting the host Docker socket provides isolation:

- Agent containers run in the DinD daemon, not on the host
- No direct access to the host container runtime
- Damage is limited to the DinD container if compromised

### Resource Limits

Both containers have resource limits to prevent exhaustion:

```yaml
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 4Gi
```

The DinD container gets additional ephemeral storage (20Gi limit) for Docker images and containers.

### Network Isolation

Consider implementing NetworkPolicies to restrict egress traffic from the OpenHands namespace to only necessary
destinations.

### Deployment Isolation

For production use, consider running OpenHands on dedicated nodes with node taints and tolerations to further reduce the
threat surface from the privileged DinD container.

### Network Isolation

NetworkPolicies enforce the principle of least privilege:

- Ingress traffic only from the gateway namespace
- Egress limited to DNS, LiteLLM service, and external HTTPS
- No lateral movement to other application namespaces

## Configuration

Key environment variables:

- `SANDBOX_RUNTIME_CONTAINER_IMAGE`: Docker image for agent runtime containers (default:
  `docker.all-hands.dev/all-hands-ai/runtime:0.24-nikolaik`)
- `LOG_ALL_EVENTS`: Enable verbose logging (default: `true`)
- `SANDBOX_HOST`: Host for agent containers (default: `127.0.0.1`)
- `WORKSPACE_BASE`: Base path for workspace files (default: `/openhands-state/workspace`)
- `LLM_BASE_URL`: LiteLLM proxy endpoint (default: `http://litellm.litellm.svc.cluster.local/v1`)
- `LLM_API_KEY`: LiteLLM API key (sourced from ExternalSecret)

## LLM Provider Configuration

OpenHands is pre-configured to use the cluster's LiteLLM proxy, which provides:

1. **Unified access**: All LLM providers configured in LiteLLM are available
2. **Local routing**: Cluster-local communication reduces latency
3. **Cost tracking**: Centralized spend monitoring across all services
4. **Caching**: Redis-backed caching reduces redundant API calls

To add or modify LLM providers, update the LiteLLM configuration rather than OpenHands directly. This allows for
centralized management of all AI services in the cluster.

## Limitations and Future Improvements

### Current Limitations

1. **Single Replica**: The deployment uses `strategy: Recreate` and single replica due to session state requirements
2. **Elevated Capabilities**: DinD requires the `SYS_ADMIN` capability, which still carries some security risk but is
   better than full privileged mode
3. **Storage Backend**: Switching from Docker to containerd would require updates to the runtime configuration

### Planned Improvements

1. **Containerd Support**: The current deployment uses Docker-in-Docker. Kubernetes has migrated to containerd as the
   default runtime. Future work should investigate:
   - Testing OpenHands with containerd runtime
   - Evaluating performance and compatibility
   - Updating runtime configuration if needed
2. **Node Isolation**: Document patterns for node-level isolation using taints and tolerations
3. **Monitoring**: Add Prometheus ServiceMonitor for metrics collection
4. **Multi-User Sessions**: Current deployment supports single-user sessions. For multi-user scenarios:
   - Investigate StatefulSet with per-user pods
   - Evaluate session isolation mechanisms
   - Consider authentication and authorization patterns
   - Research workspace segregation strategies

## Troubleshooting

### Pod Fails to Start

Check if the DinD container is ready:

```bash
kubectl logs -n openhands deployment/openhands -c dind
```

Verify the init container completed:

```bash
kubectl describe pod -n openhands -l app.kubernetes.io/name=openhands
```

### Agent Containers Fail to Spawn

Check Docker daemon logs in the DinD container:

```bash
kubectl logs -n openhands deployment/openhands -c dind --tail=100
```

Verify storage is available:

```bash
kubectl get pvc -n openhands
```

### Session State Not Persisting

Ensure the PVC is bound and mounted:

```bash
kubectl get pvc -n openhands openhands-state
kubectl describe pod -n openhands -l app.kubernetes.io/name=openhands
```

Check volume mounts:

```bash
kubectl exec -n openhands deployment/openhands -c openhands -- ls -la /openhands-state
```
