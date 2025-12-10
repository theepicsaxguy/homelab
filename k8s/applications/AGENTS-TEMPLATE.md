# Application Category - Agent Guidelines Template

> **Note:** This is a template for creating category-level AGENTS.md files under `k8s/applications/<category>/`. Copy and customize this template when a category develops unique patterns, deployment workflows, or testing requirements not covered by the parent `k8s/AGENTS.md`.

## Purpose & Scope

- **Scope:** `k8s/applications/<category>/` (all applications in this category)
- **Parent:** Inherits from `k8s/AGENTS.md` for general Kubernetes patterns
- **Goal:** Document category-specific patterns, shared resources, and common workflows

## When to Create a Category-Level AGENTS.md

Create an AGENTS.md file for a category when:
- The category has 5+ applications with shared patterns
- Applications in the category share common resources (databases, message queues, storage)
- The category has unique deployment, testing, or operational patterns
- Category-specific conventions differ from general Kubernetes patterns

## Category-Specific Quick-Start

```bash
# Build all applications in this category
kustomize build --enable-helm k8s/applications/<category>

# Build a specific application
kustomize build --enable-helm k8s/applications/<category>/<app>

# Validate category kustomization
kustomize build k8s/applications/<category> | kubeval --strict
```

## Category Structure & Conventions

### Common Patterns

Describe patterns shared across applications in this category:
- Shared database configurations
- Common ingress/routing patterns
- Standard resource requests/limits
- Backup tier recommendations (GFS, daily, or none)
- Network policies or security contexts

### Example Application Layout

```
k8s/applications/<category>/<app>/
├── kustomization.yaml
├── deployment.yaml
├── service.yaml
├── httproute.yaml (if exposed)
├── pvc.yaml (if stateful)
├── externalsecret.yaml (if needs secrets)
└── README.md (optional)
```

### Shared Resources

Document any shared resources used by applications in this category:
- Shared databases or database clusters
- Shared message queues or caches
- Shared S3 buckets or object storage
- Shared authentication/authorization configurations

## Adding a New Application

1. Create directory: `k8s/applications/<category>/<app>/`
2. Add manifests following the category's conventions
3. Include `kustomization.yaml` that references all manifests
4. Add backup labels to PVCs if stateful (see parent `k8s/AGENTS.md` for tiers)
5. Update `k8s/applications/<category>/kustomization.yaml` to include new app
6. Test locally: `kustomize build --enable-helm k8s/applications/<category>/<app>`
7. Create PR (do not apply directly to cluster)

## Testing & Validation

### Local Validation

```bash
# Validate individual application
kustomize build --enable-helm k8s/applications/<category>/<app>

# Check for common issues
kustomize build k8s/applications/<category>/<app> | \
  grep -E 'kind: (Secret|ConfigMap)' # Ensure no hardcoded secrets
```

### Category-Specific Tests

Document any category-specific validation:
- Integration tests between applications
- Smoke tests for critical functionality
- Database migration validation
- Performance or resource usage checks

## Operational Patterns

### Deployment Order

If applications in this category have dependencies, document the deployment order:
1. Shared infrastructure (databases, queues)
2. Core services
3. Dependent applications
4. Frontend/UI applications

### Backup Strategy

Recommend backup tiers for applications in this category:
- **GFS (Grandfather-Father-Son):** Critical data requiring point-in-time recovery
- **Daily:** Standard applications with daily retention
- **None:** Ephemeral data, caches, or fully reproducible state

### Scaling Considerations

Document scaling patterns for this category:
- Horizontal pod autoscaling configurations
- Resource limits and requests
- StatefulSet vs Deployment trade-offs
- Storage scaling considerations

## Common Issues & Solutions

### Issue 1: [Common Problem]

**Symptoms:**
- Describe what users/operators observe

**Diagnosis:**
```bash
# Commands to diagnose
kubectl get pods -n <namespace> -l app=<label>
kubectl logs <pod-name> -n <namespace>
```

**Solution:**
- Step-by-step resolution

### Issue 2: [Another Common Problem]

(Repeat pattern as needed)

## Boundaries & Safety

- **Do not modify** shared infrastructure without coordinating across all dependent apps
- **Always verify** database credentials and connection strings before applying changes
- **Never hardcode** secrets in manifests; use ExternalSecrets
- **Check backup status** of PVCs before applying changes that affect storage

## References

- Parent guidance: [k8s/AGENTS.md](../AGENTS.md)
- Root guidance: [/AGENTS.md](../../AGENTS.md)
- Category documentation: `website/docs/<category>/` (if exists)
- Upstream documentation: [list relevant external docs]

---

**Maintenance Note:** Keep this file updated when category patterns change. Update in the same PR as architectural changes.
