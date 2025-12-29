# Longhorn Upgrade Strategy

## Overview

This document outlines the upgrade strategy for Longhorn distributed storage in the homelab Kubernetes cluster. The strategy focuses on automated engine upgrades and version management to minimize downtime and manual intervention.

## Context

The homelab uses Longhorn as its distributed block storage system. Since Longhorn v1.1.1, automatic engine upgrades are supported to reduce manual maintenance overhead during version updates.

## Automatic Engine Upgrades

Since Longhorn v1.1.1, the cluster is configured to automatically upgrade volume engines to the new default engine version after upgrading the Longhorn manager. This feature reduces manual work during upgrades and ensures volumes stay current with the latest engine improvements.

### Configuration

The cluster uses the following automatic upgrade settings:

- **Concurrent Automatic Engine Upgrade Per Node Limit**: 3 engines per node
  - Controls maximum concurrent engine upgrades per node
  - Value of 3 provides good upgrade speed while preventing system overload
  - If set to 0, automatic upgrades would be disabled

### Upgrade Behavior by Volume State

**Attached Volumes**
- Healthy attached volumes receive live upgrades without downtime
- Engine upgrade occurs while the volume remains in use

**Detached Volumes**
- Offline upgrades are performed automatically
- No impact on running applications

**Disaster Recovery Volumes**
- Not automatically upgraded to avoid triggering full restoration
- Manual upgrade recommended during maintenance windows
- When activated, volumes are upgraded offline after detachment

### Failure Handling

If an engine upgrade fails:
- Volume spec retains old engine image reference
- Longhorn continuously retries the upgrade
- If too many failures occur per node (> concurrent limit), upgrades pause on that node
- Failed upgrades don't affect volume availability

This ensures smooth Longhorn version upgrades with minimal operational overhead.

## Upgrade Process

### Longhorn Manager Upgrades

1. **Preparation**
   - Review Longhorn release notes for breaking changes
   - Ensure backup strategy is current and tested
   - Verify cluster has sufficient resources for upgrades

2. **Manager Upgrade**
   - Update Longhorn Helm chart version in `k8s/infrastructure/storage/longhorn/values.yaml`
   - Apply changes through GitOps (Argo CD will deploy automatically)
   - Monitor Longhorn UI for upgrade progress

3. **Engine Upgrades**
   - Automatic engine upgrades begin after manager deployment
   - Monitor upgrade progress in Longhorn UI
   - Check for failed upgrades and investigate if needed

4. **Post-Upgrade Validation**
   - Verify all volumes are healthy
   - Confirm backup jobs are running successfully
   - Test application functionality with upgraded volumes

### Rollback Procedures

If issues occur during upgrade:

1. **Pause Automatic Upgrades**
   - Set `concurrentAutomaticEngineUpgradePerNodeLimit: 0` temporarily
   - This stops automatic engine upgrades

2. **Manager Rollback**
   - Revert Helm chart version in Git
   - Argo CD will roll back the deployment

3. **Volume Recovery**
   - Failed volumes will retain old engine version
   - Manual intervention may be required for problematic volumes
   - Use Longhorn UI to manually upgrade individual volumes if needed

## Monitoring and Alerts

- Monitor Longhorn UI for upgrade status
- Check Kubernetes events for upgrade-related issues
- Set up alerts for failed engine upgrades
- Review upgrade logs in Longhorn manager pods

## Best Practices

- **Test Upgrades**: Always test upgrades in a development environment first
- **Backup First**: Ensure recent backups exist before major upgrades
- **Monitor Resources**: Watch for resource usage spikes during upgrades
- **Staged Rollout**: Consider upgrading nodes in stages for large clusters
- **Documentation**: Keep upgrade records for troubleshooting future issues
