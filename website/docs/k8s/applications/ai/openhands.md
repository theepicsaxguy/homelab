---
title: 'OpenHands AI Coding Agent'
---

OpenHands is an open-source AI coding agent that helps accelerate development work by automating coding tasks. The deployment runs as a single replica with a Docker-in-Docker sidecar to provide isolated container execution for agent sessions.

## Architecture

OpenHands creates a new Docker container for each agent session. To avoid mounting the host Docker socket (a security risk), this deployment uses Docker-in-Docker (DinD) as a sidecar container. The DinD sidecar provides an isolated Docker daemon that OpenHands uses to spawn agent containers.

```yaml
# k8s/applications/ai/openhands/deployment.yaml
containers:
  - name: openhands
    image: docker.all-hands.dev/all-hands-ai/openhands:0.24
    env:
      - name: DOCKER_HOST
        value: "unix:///var/run/docker.sock"
  - name: dind
    image: docker:27-dind
    securityContext:
      privileged: true
```

The DinD container requires `privileged: true` to run Docker inside Kubernetes. An init container waits for the Docker socket to be ready before starting OpenHands.

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

## Secrets

The ExternalSecret `app-openhands-llm-api-key` sources the LLM API key from Bitwarden and injects it into the container:

```yaml
# k8s/applications/ai/openhands/externalsecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-openhands-llm-api-key
  namespace: openhands
spec:
  secretStoreRef:
    name: bitwarden-secrets-manager
    kind: ClusterSecretStore
  target:
    name: app-openhands-llm-api-key
  dataFrom:
    - extract:
        key: app-openhands-llm-api-key
```

Configure your LLM provider (Anthropic, OpenAI, Gemini, etc.) through the OpenHands UI. The API key can be set via the `LLM_API_KEY` environment variable or directly in the UI.

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

External access is provided through the HTTPRoute on `openhands.pc-tips.se`:

```yaml
# k8s/applications/ai/openhands/httproute.yaml
spec:
  parentRefs:
    - name: external
      namespace: gateway
      sectionName: https
  hostnames:
    - openhands.pc-tips.se
```

## Security Considerations

### Pod Security Standards

The namespace enforces the `baseline` Pod Security Standard to accommodate the DinD sidecar, which requires `privileged: true` to function. The baseline standard prevents the most dangerous behaviors while allowing the privileged container needed for Docker-in-Docker operation.

The OpenHands main container follows security best practices:
- Runs as non-root user (UID 1000)
- Drops all capabilities
- Uses seccomp profile

Note: `readOnlyRootFilesystem` is set to `false` for the OpenHands container because the application requires write access to multiple directories for runtime operation.

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

Consider implementing NetworkPolicies to restrict egress traffic from the OpenHands namespace to only necessary destinations.

### Deployment Isolation

For production use, consider running OpenHands on dedicated nodes with node taints and tolerations to further reduce the threat surface from the privileged DinD container.

## Configuration

Key environment variables:

- `SANDBOX_RUNTIME_CONTAINER_IMAGE`: Docker image for agent runtime containers (default: `docker.all-hands.dev/all-hands-ai/runtime:0.24-nikolaik`)
- `LOG_ALL_EVENTS`: Enable verbose logging (default: `true`)
- `SANDBOX_HOST`: Host for agent containers (default: `127.0.0.1`)
- `WORKSPACE_BASE`: Base path for workspace files (default: `/openhands-state/workspace`)
- `LLM_API_KEY`: API key for LLM provider (sourced from ExternalSecret)

## Integration with LLMariner

If running LLMariner in the same cluster, configure OpenHands to use local LLM endpoints to reduce latency:

1. Set the LLM base URL to your LLMariner service endpoint
2. Use cluster-local DNS names (e.g., `http://llmariner.llmariner.svc.cluster.local`)
3. Configure the API key through the OpenHands UI or `LLM_API_KEY` environment variable

## Limitations and Future Improvements

### Current Limitations

1. **Single Replica**: The deployment uses `strategy: Recreate` and single replica due to session state requirements
2. **Privileged Container**: DinD requires privileged mode, which increases security risk
3. **Storage Backend**: Switching from Docker to containerd would require updates to the runtime configuration

### Planned Improvements

1. **Containerd Support**: Test and validate deployment with containerd runtime instead of Docker
2. **Enhanced Network Policies**: Add egress restrictions to limit outbound connections
3. **Node Isolation**: Document patterns for node-level isolation using taints and tolerations
4. **Monitoring**: Add Prometheus ServiceMonitor for metrics collection
5. **Multi-User Sessions**: Investigate patterns for multi-user deployments with session isolation

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
