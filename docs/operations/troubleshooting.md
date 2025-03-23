# Common Issues & Solutions

## Quick Reference

### Can't Access Services

1. Check ArgoCD sync status
2. Verify Gateway API routes
3. Test Authelia authentication
4. Check DNS resolution

### Application Not Deploying

1. Check ArgoCD error messages
2. Verify resource quotas
3. Check network policies
4. Review application logs

### Storage Problems

1. Check Longhorn volume status
2. Verify node connectivity
3. Check available capacity
4. Review volume policies

## Critical Service Recovery

### Authentication (Authelia)

**Impact:** No access to services

1. Check Authelia pods
2. Verify LLDAP connection
3. Test login flow
4. Review auth logs

### Network (Cilium)

**Impact:** Service connectivity loss

1. Check Cilium agent status
2. Verify network policies
3. Test pod connectivity
4. Review Cilium logs

### Storage (Longhorn)

**Impact:** Data unavailability

1. Check volume status
2. Verify node health
3. Test replicas
4. Review disk space

## Common Errors

### ArgoCD Sync Failures

- **Cause:** Git repo access, manifest errors, resource conflicts
- **Check:** Application sync status, event logs
- **Fix:** Update credentials, fix manifests, resolve conflicts

### Network Policy Blocks

- **Cause:** Missing ingress/egress rules
- **Check:** Policy configuration, traffic logs
- **Fix:** Update network policies, verify selectors

### Resource Constraints

- **Cause:** Insufficient CPU/memory, quota limits
- **Check:** Pod status, resource usage
- **Fix:** Adjust requests/limits, update quotas

## Getting Help

### Useful Commands

```bash
# Check application status
kubectl get applications -n argocd

# View pod logs
kubectl logs -n <namespace> <pod-name>

# Check pod status
kubectl describe pod -n <namespace> <pod-name>
```

### Logs to Check

1. Application logs
2. ArgoCD logs
3. Cilium logs
4. Auth logs

### Next Steps

1. Document the issue
2. Update runbooks if needed
3. Review root cause
4. Plan preventive measures
