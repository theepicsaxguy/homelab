---
sidebar_position: 6
title: 'Scenario 6: Ransomware Attack'
---

# Scenario 6: Ransomware Attack

## Symptoms

- Files or volumes are encrypted with unknown extension (.locked, .encrypted, etc.)
- Ransom note files appearing in directories or namespaces
- Unusual network activity or outbound connections to unknown IPs
- TrueNAS shares showing encrypted files or inaccessible data
- NAS or backup systems compromised
- System performance degradation due to encryption processes
- Cluster resources being used by unauthorized processes

## Impact Assessment

- **Recovery Time Objective (RTO)**: 8-24 hours
- **Recovery Point Objective (RPO)**: Up to 24-48 hours (depending on last clean backup)
- **Data Loss Risk**: Moderate (depends on identifying clean backup before infection)
- **Service Availability**: Complete outage during isolation and restoration
- **Security Risk**: High (requires full security audit and remediation)

## Prerequisites

- Access to offsite B2 backups (assume local backups are compromised)
- B2 bucket with object versioning enabled
- Alternative access method (laptop, phone) - do NOT use compromised systems
- Incident response team or security expert contact
- Network isolation capability (ability to disconnect cluster from network)
- Clean OS installation media for rebuilding if needed

## Recovery Procedure

### Step 1: Immediate Containment

**CRITICAL: Do NOT attempt recovery until systems are isolated**

```bash
# Immediately disconnect cluster from network
# Physical method: Unplug network cables from all nodes
# Or via firewall if remote:
# Block all traffic to/from cluster nodes

# Document current state BEFORE taking any action
kubectl get all -A > /tmp/pre-incident-state.txt
kubectl get pvc -A >> /tmp/pre-incident-state.txt

# Shutdown all pods to prevent further encryption
kubectl scale deployment --all --replicas=0 -A
kubectl scale statefulset --all --replicas=0 -A

# Take snapshots of current state for forensics
# On TrueNAS, create read-only snapshots if possible
# Document all encrypted files and ransom notes
```

### Step 2: Assess Infection Timeline

Determine when the infection started to identify clean backups:

```bash
# Check file modification times to find encryption start time
# On TrueNAS via SSH:
find /mnt/pool/data -type f -name "*.locked" -o -name "*.encrypted" | head -20 | xargs stat

# Check Velero backup times
velero backup get --output custom-columns=NAME:.metadata.name,CREATED:.metadata.creationTimestamp

# Check system logs for suspicious activity
# Look for unusual logins, privilege escalations, or process execution
journalctl --since "7 days ago" | grep -E "(sudo|su|ssh|unauthorized)"

# Check Kubernetes audit logs if enabled
kubectl logs -n kube-system -l component=kube-apiserver | grep -i "suspicious"
```

### Step 3: Verify B2 Backup Integrity

Use B2's object versioning to access backups from before the infection:

```bash
# Install B2 CLI on a clean system (NOT the compromised cluster)
pip install b2

# Authenticate to B2
b2 authorize-account <application-key-id> <application-key>

# List all backups with version history
b2 ls --recursive --versions b2://homelab-velero-b2/

# Identify backups from BEFORE infection timeline
# Look for backups older than infection start date
b2 ls --recursive b2://homelab-velero-b2/backups/ | grep -E "daily-202[0-9]{5}"

# Download specific backup version for verification
b2 download-file-by-name homelab-velero-b2 backups/daily-YYYYMMDD-020000.tar.gz /tmp/verify-backup.tar.gz

# Verify backup is not encrypted
tar -tzf /tmp/verify-backup.tar.gz | head -20
# Should show normal file structure, not encrypted data
```

**Check CNPG PostgreSQL backups in B2:**

```bash
# List PostgreSQL backups with versions
b2 ls --recursive --versions b2://homelab-cnpg-b2/

# For each critical database namespace:
b2 ls --recursive b2://homelab-cnpg-b2/database/<cluster-name>/

# Verify base backup integrity
# Download latest base backup from before infection
b2 download-file-by-name homelab-cnpg-b2 \
  database/<cluster-name>/base/<backup-id>/data.tar.gz \
  /tmp/db-verify.tar.gz

# Check it's not encrypted
file /tmp/db-verify.tar.gz
# Should show: "gzip compressed data"
```

### Step 4: Rebuild Clean Infrastructure

**Option A: Full Cluster Rebuild (Recommended)**

If the cluster itself may be compromised:

```bash
# On clean system, clone infrastructure repo
git clone https://github.com/theepicsaxguy/homelab.git /tmp/homelab-rebuild
cd /tmp/homelab-rebuild

# Verify git history wasn't tampered with
git log --all --oneline | head -20
git verify-commit HEAD  # If you use signed commits

# Rebuild Talos cluster from scratch
cd talos/
# Follow Talos installation documentation
# This ensures no malware persists in the OS or Kubernetes

# After cluster is online, reinstall base infrastructure
cd ../k8s/
# Apply ArgoCD and core apps
```

**Option B: Selective Pod Rebuild (If cluster OS is clean)**

If only applications were affected:

```bash
# From clean system with kubectl access
# Delete all user workloads but keep infrastructure
kubectl delete namespace --selector=type=application

# Reinstall via ArgoCD from git (verified clean)
kubectl apply -f k8s/argocd/applications/
argocd app sync --all
```

### Step 5: Restore Data from Clean Backups

**Restore Velero backups from B2:**

```bash
# Ensure Velero is pointed at B2 storage location
kubectl -n velero get backupstoragelocations

# If needed, create B2 storage location
cat <<EOF | kubectl apply -f -
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: backblaze-b2
  namespace: velero
spec:
  provider: aws
  objectStorage:
    bucket: homelab-velero-b2
  config:
    region: us-west-000
    s3ForcePathStyle: "true"
    s3Url: https://s3.us-west-002.backblazeb2.com
EOF

# List backups from B2
velero backup get --storage-location backblaze-b2

# Restore from clean backup (identified in Step 3)
# Use backup from BEFORE infection timeline
velero restore create ransomware-recovery-$(date +%Y%m%d) \
  --from-backup daily-YYYYMMDD-020000 \
  --storage-location backblaze-b2 \
  --exclude-resources=nodes,events,componentstatuses

# Monitor restore
velero restore describe ransomware-recovery-$(date +%Y%m%d)
velero restore logs ransomware-recovery-$(date +%Y%m%d)
```

**Restore PostgreSQL from clean B2 backup:**

```yaml
# Create recovery cluster YAML: restore-postgres-clean.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: <cluster-name>
  namespace: <namespace>
spec:
  instances: 2

  bootstrap:
    recovery:
      source: clean-b2-backup
      recoveryTarget:
        # Restore to specific time BEFORE infection
        targetTime: '2024-12-20 23:59:59' # Adjust to pre-infection time

  externalClusters:
    - name: clean-b2-backup
      barmanObjectStore:
        destinationPath: s3://homelab-cnpg-b2/<namespace>/<cluster-name>
        endpointURL: https://s3.us-west-002.backblazeb2.com
        s3Credentials:
          accessKeyId:
            name: b2-cnpg-credentials
            key: AWS_ACCESS_KEY_ID
          secretAccessKey:
            name: b2-cnpg-credentials
            key: AWS_SECRET_ACCESS_KEY
        wal:
          compression: gzip
          encryption: AES256

  storage:
    size: 20Gi
    storageClass: longhorn
```

Apply the recovery:

```bash
# Remove any existing compromised cluster
kubectl -n <namespace> delete cluster <cluster-name> --wait=true

# Apply clean recovery
kubectl apply -f restore-postgres-clean.yaml

# Monitor recovery to pre-infection state
kubectl -n <namespace> get cluster <cluster-name> -w
kubectl -n <namespace> logs -l cnpg.io/cluster=<cluster-name> -c postgres --tail=50 -f
```

### Step 6: Security Scan and Malware Removal

**Scan restored systems:**

```bash
# Deploy security scanning tools
kubectl create namespace security-scan

# Deploy Trivy for container scanning
kubectl -n security-scan run trivy --image=aquasec/trivy:latest -- image --scanners vuln <your-image>

# Scan persistent volumes for malware
# Deploy ClamAV DaemonSet to scan all nodes
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: clamav-scanner
  namespace: security-scan
spec:
  selector:
    matchLabels:
      app: clamav
  template:
    metadata:
      labels:
        app: clamav
    spec:
      hostPID: true
      hostIPC: true
      containers:
      - name: clamav
        image: clamav/clamav:latest
        volumeMounts:
        - name: host-root
          mountPath: /host
          readOnly: true
      volumes:
      - name: host-root
        hostPath:
          path: /
EOF

# Check scan results
kubectl -n security-scan logs -l app=clamav
```

**Scan TrueNAS:**

```bash
# SSH to TrueNAS
ssh admin@truenas.local

# Update ClamAV
sudo freshclam

# Scan all datasets
sudo clamscan -r -i /mnt/pool/data/ > /tmp/scan-results.txt

# Review results
cat /tmp/scan-results.txt
```

### Step 7: Rotate All Credentials

**CRITICAL: Assume all secrets were compromised**

```bash
# Rotate all Kubernetes secrets
# Generate new credentials for each service

# Example: Rotate database passwords
kubectl -n <namespace> create secret generic <db-secret> \
  --from-literal=password=$(openssl rand -base64 32) \
  --dry-run=client -o yaml | kubectl apply -f -

# Rotate B2 application keys
# Via B2 web interface:
# 1. Go to App Keys
# 2. Delete old keys
# 3. Create new keys
# 4. Update Kubernetes secrets

kubectl -n velero create secret generic b2-credentials \
  --from-literal=AWS_ACCESS_KEY_ID=<new-key-id> \
  --from-literal=AWS_SECRET_ACCESS_KEY=<new-key> \
  --dry-run=client -o yaml | kubectl apply -f -

# Rotate ArgoCD admin password
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {"admin.password": "'$(htpasswd -bnBC 10 "" <new-password> | tr -d ':\n')'"}}'

# Rotate SSH keys and API tokens
# Update in GitHub, BitWarden, etc.
```

### Step 8: Validate System Integrity

```bash
# Check all pods are running from clean images
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'

# Verify no unexpected processes
kubectl get pods -A --field-selector status.phase=Running | while read ns name; do
  kubectl -n $ns top pod $name 2>/dev/null
done

# Check for unexpected network connections
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash
# Inside container:
netstat -antp
ss -tulpn

# Verify DNS is not hijacked
nslookup google.com
nslookup b2.backblazeb2.com

# Check resource quotas aren't being abused (crypto mining)
kubectl top nodes
kubectl top pods -A --sort-by=cpu
```

### Step 9: Restore Network Access Gradually

```bash
# Reconnect cluster to network in stages
# 1. Enable DNS only
# 2. Enable internal cluster communication
# 3. Enable outbound HTTPS (for updates, B2)
# 4. Enable ingress for specific services (monitor closely)

# Monitor network traffic closely
kubectl -n monitoring port-forward svc/prometheus 9090:9090
# View network dashboards, watch for anomalies

# Check for any unusual outbound connections
# Use Cilium Hubble or similar network observability tools
```

## Post-Recovery Tasks

### 1. Full Security Audit

```bash
# Review all access logs
# Check Kubernetes audit logs (if enabled)
kubectl logs -n kube-system kube-apiserver-* | grep -E "(create|update|delete)" > audit.log

# Review who had access
kubectl get clusterrolebindings -o yaml
kubectl get rolebindings -A -o yaml

# Check for backdoors or persistence mechanisms
# Look for unexpected CronJobs, DaemonSets, or webhooks
kubectl get cronjobs -A
kubectl get daemonsets -A
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations
```

### 2. Implement Enhanced Security

```yaml
# Deploy Falco for runtime threat detection
# Create file: falco-deployment.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: falco
---
# Install Falco via Helm or manifests
# Configure alerts for suspicious activity
```

```bash
# Enable Pod Security Standards
kubectl label namespace default pod-security.kubernetes.io/enforce=restricted
kubectl label namespace default pod-security.kubernetes.io/audit=restricted
kubectl label namespace default pod-security.kubernetes.io/warn=restricted

# Enable network policies
# Deny all by default, allow only necessary traffic
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
```

### 3. Document Incident

Create detailed incident report:

```bash
cat > /home/benjaminsanden/Dokument/Projects/homelab/docs/incidents/ransomware-$(date +%Y%m%d).md <<EOF
# Ransomware Incident Report

**Date**: $(date)
**Incident Type**: Ransomware Attack
**Detection Time**: <time>
**Resolution Time**: <time>
**Total Downtime**: <hours>

## Timeline
- **T+0h**: Detection - <details>
- **T+1h**: Isolation - <details>
- **T+2h**: Assessment - <details>
- **T+Xh**: Recovery - <details>

## Affected Systems
- Kubernetes cluster: <nodes>
- TrueNAS: <shares>
- Applications: <list>
- Databases: <list>

## Attack Vector
<How the attacker gained access>

## Data Loss
- Last clean backup: <date/time>
- Data lost: <description>
- Approximate loss: <X hours of data>

## Recovery Steps
1. <detailed steps taken>

## Root Cause
<What vulnerability was exploited>

## Lessons Learned
<What went well, what didn't>

## Action Items
- [ ] Patch vulnerability X
- [ ] Implement additional monitoring
- [ ] Schedule security training
- [ ] Review and update backup strategy
- [ ] Implement immutable backups

## Total Cost
- Downtime cost: <estimate>
- Recovery effort: <hours>
- Lost data impact: <description>
EOF
```

### 4. Enable Immutable Backups

Prevent future backup compromise:

```bash
# Configure B2 bucket with object lock (if not already enabled)
# Via B2 web interface:
# Bucket Settings → Object Lock → Enable
# Set retention period (e.g., 30 days)

# Update Velero to use immutable backups
kubectl -n velero patch backupstoragelocation backblaze-b2 \
  --type merge \
  -p '{"spec":{"objectStorage":{"bucket":"homelab-velero-b2-immutable"}}}'

# Configure CNPG for immutable backups
# Edit cluster spec to include:
# barmanObjectStore:
#   wal:
#     retention: "30d"
```

### 5. Schedule Regular Restore Tests

```bash
# Create monthly restore test schedule
# Test restoring to isolated namespace to verify backups

# Add to calendar/cron:
# Monthly: Test Velero restore
# Monthly: Test CNPG point-in-time recovery
# Quarterly: Full disaster recovery drill
```

## Troubleshooting

### B2 Backup Versions Not Available

```bash
# If object versioning wasn't enabled, check B2 lifecycle rules
b2 get-bucket homelab-velero-b2

# If backups are truly lost, check if any local copies survived
# On TrueNAS (if accessible):
ls -lah /mnt/pool/backups/velero/

# Last resort: Check if any cloud sync service has copies
```

### Cannot Determine Clean Backup Point

```bash
# Use file timestamps and infection indicators
# Create timeline of events

# Check application logs for last known good state
kubectl logs <pod> --previous --timestamps

# Consult application data for "last modified" timestamps
# In PostgreSQL:
SELECT MAX(updated_at) FROM users;  # Example

# If uncertain, restore multiple backups to test namespaces
# Compare data to find latest clean version
```

### Restored System Still Shows Suspicious Activity

```bash
# Malware may have persisted in:
# - Container images (rebuild from source)
# - Persistent volumes (scan and clean or recreate)
# - Configuration (review all ConfigMaps and Secrets)

# Nuclear option: Full rebuild
# Rebuild cluster from scratch
# Rebuild all container images from verified sources
# Restore only data, not configurations
```

## Prevention Measures

### Immediate Actions

1. **Isolate critical systems**: Implement network segmentation
2. **Enable immutable backups**: Configure B2 object lock
3. **Implement least privilege**: Review and restrict RBAC
4. **Enable audit logging**: Track all API calls
5. **Deploy security monitoring**: Falco, Prometheus alerts

### Long-term Improvements

1. **Security training**: For all users with cluster access
2. **Penetration testing**: Regular security assessments
3. **Backup verification**: Automated restore testing
4. **Incident response plan**: Document and practice procedures
5. **Supply chain security**: Verify container image signatures

## Related Scenarios

- [Scenario 1: Accidental Deletion](01-accidental-deletion.md) - For restoration procedures
- [Scenario 8: Data Corruption](08-data-corruption.md) - If backups contain subtle corruption
- [Scenario 9: Primary Recovery Guide](09-primary-recovery.md) - For accessing B2 backups

## Reference

- [B2 Object Lock Documentation](https://www.backblaze.com/b2/docs/object_lock.html)
- [Velero Security Best Practices](https://velero.io/docs/main/security/)
- [CNPG Security Documentation](https://cloudnative-pg.io/documentation/current/security/)
- [CISA Ransomware Guide](https://www.cisa.gov/stopransomware)
