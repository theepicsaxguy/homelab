# Proxmox CSI Storage

This guide explains how storage works in the homelab using the Proxmox CSI (Container Storage Interface) plugin for dynamic volume provisioning.

## Overview

The homelab uses the [Proxmox CSI Plugin](https://github.com/sergelogvinov/proxmox-csi-plugin) (`csi.proxmox.sinextra.dev`) as the **primary storage provisioner** for new Kubernetes workloads. This provides dynamic volume provisioning directly from Proxmox datastores without requiring additional storage layers.

**Current Storage Classes:**
- `proxmox-csi` — Primary storage class (Retain policy, Immediate binding, expandable)
- `longhorn` — Legacy storage class for existing workloads (being phased out)
- `longhorn-static` — Legacy static provisioning

The Proxmox CSI plugin allows applications to automatically request and receive persistent storage without manual intervention, with volumes created directly on the Proxmox Nvme1 ZFS datastore.

## How Dynamic Provisioning Works

The Proxmox CSI plugin provides **fully automatic storage provisioning**. You don't need to pre-create volumes, manually attach disks, or configure storage backends. Just create a PVC and the CSI plugin handles everything.

### The Process (Completely Automatic)

1. **You create a PVC:**
   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: my-app-data
   spec:
     storageClassName: proxmox-csi  # References the StorageClass
     resources:
       requests:
         storage: 10Gi
   ```

2. **CSI Controller sees the PVC and automatically:**
   - Calls Proxmox API to create a new virtual disk: `vm-XXXX-pvc-<uuid>`
   - Attaches the disk to the appropriate Proxmox node
   - Formats the disk with ext4 (or specified filesystem)
   - Creates a PersistentVolume (PV) in Kubernetes
   - Binds the PVC to the PV

3. **Done!** Your pod can now mount the volume. The entire process is automatic - no manual intervention needed.

### Key Benefits

- **Zero manual steps**: No need to SSH into Proxmox or run `pvesm` commands
- **Automatic placement**: Volumes are created on the same node where the pod is scheduled (WaitForFirstConsumer)
- **Direct ZFS access**: Volumes are ZFS datasets on Nvme1, providing high performance
- **Volume expansion**: Resize PVCs dynamically without recreating them
- **Clean lifecycle**: When you delete a PVC, the volume is retained (Retain policy) for data safety

## Why Not Pre-Provision Volumes?

Unlike older storage systems, **you should never pre-create volumes manually**. The CSI plugin is designed for dynamic provisioning - it creates volumes on-demand as applications request them.

The `bootstrap/volumes` Terraform module exists only for migrating pre-existing Proxmox volumes into Kubernetes, not for creating new storage.

## Bootstrap Configuration

The storage bootstrap is managed through OpenTofu in the `tofu/bootstrap.tf` file.

### Proxmox CSI Plugin Setup

The `proxmox-csi-plugin` module in `tofu/bootstrap.tf` automatically configures:

1. **Proxmox User & Role**: Creates a `kubernetes-csi@pve` user with minimal CSI permissions
2. **API Token**: Generates a secure API token with `privileges_separation = true`
3. **Kubernetes Resources**:
   - Creates `csi-proxmox` namespace with PodSecurity privileged labels
   - Stores Proxmox credentials in a Kubernetes secret

**Command to deploy:**

```bash
cd tofu
tofu apply
```

**Terraform Module Reference:**

```hcl
# From tofu/bootstrap.tf
module "proxmox-csi-plugin" {
  source = "./bootstrap/proxmox-csi-plugin"

  proxmox = {
    cluster_name = var.proxmox_cluster
    endpoint     = var.proxmox.endpoint
    insecure     = var.proxmox.insecure
  }
}
```

### Security Configuration

The CSI plugin uses a **least-privilege security model**:

| Setting | Value | Purpose |
|---------|-------|---------|
| Role Privileges | `Sys.Audit`, `VM.Audit`, `VM.Config.Disk`, `Datastore.*` | Minimal required for CSI operations |
| Token | `privileges_separation = false` | Token inherits full user privileges, enabling storage/volume access |
| Namespace | `pod-security.kubernetes.io/enforce: privileged` | Required for CSI node plugins |

**Why `privileges_separation = false`?**

- Token needs full access to Proxmox resources (storage allocation, VM disk operations)
- With `privileges_separation = true`, the token is restricted to CSI role only, causing "not authorized" errors
- Full user privileges are required for the CSI plugin to manage volumes across nodes

## Using Storage in Applications

### Dynamic Provisioning Example

Most applications should use dynamic provisioning:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-csi
  resources:
    requests:
      storage: 20Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  template:
    spec:
      containers:
      - name: postgres
        image: postgres:15
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: postgres-data
```

### That's It!

Notice what you **didn't** have to do:
- No manual volume creation in Proxmox
- No SSH into Proxmox nodes
- No `pvesm alloc` commands
- No manual PV creation
- No volume attachment configuration

The CSI plugin handles all of this automatically when you create the PVC. This is the power of dynamic provisioning!

## StorageClass Configuration

The Proxmox CSI plugin typically provides a default StorageClass. You can create additional StorageClasses for different storage backends or performance tiers:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: proxmox-ssd
provisioner: csi.proxmox.sinextra.dev
parameters:
  storage: local-zfs
  cache: writethrough
  ssd: "true"
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
```

## Volume Binding Mode Decision

### Why We Use `Immediate` Instead of `WaitForFirstConsumer`

The homelab's `proxmox-csi` StorageClass uses **`volumeBindingMode: Immediate`** binding mode. This section documents why this decision was made and the trade-offs involved.

#### Context: Single-Zone Cluster

This homelab runs a **single-zone Kubernetes cluster** where all worker nodes are in the same physical location (same Proxmox cluster, same datacenter, same network). There are no multiple availability zones, regions, or geographically distributed nodes.

#### The Problem with WaitForFirstConsumer

**What is WaitForFirstConsumer?**
- PVC creation does NOT immediately provision a PV
- Volume provisioning is delayed until a pod that uses the PVC is scheduled
- The volume is then created on the same node/zone where the pod is scheduled
- **Purpose**: Ensures volume locality in multi-zone clusters (volume created in same zone as pod)

**Why it caused problems in our setup:**

1. **Velero Restore Deadlock (Primary Issue)**
   - During disaster recovery, Velero restores PVCs and Pods simultaneously
   - PVCs stay `Pending` (waiting for pod to be scheduled)
   - Pods stay `Pending` (waiting for PVC to be bound)
   - **Result**: Chicken-and-egg deadlock - nothing progresses without manual intervention
   - Manual fix required: annotating each PVC with `volume.kubernetes.io/selected-node=<node>` to break deadlock

2. **Unbalanced Pod Distribution**
   - After Velero restore with manual node annotations, all pods scheduled on same node
   - Created single point of failure (57% of pods on one node after migration)
   - Kubernetes scheduler couldn't rebalance because PVCs were already bound to specific node

3. **No Topology Benefit in Single-Zone**
   - In single-zone clusters, all nodes can access all storage equally
   - Topology awareness provides **zero benefit**
   - WaitForFirstConsumer only adds complexity without any advantage

#### The Solution: Immediate Binding

**What is Immediate?**
- PV is provisioned **as soon as PVC is created**
- Volume is created immediately, no waiting for pod scheduling
- In single-zone: volume created on any available node (same outcome as WaitForFirstConsumer)

**Why we chose Immediate:**

✅ **Fixes Velero Restore Issues**
- PVCs bind immediately upon creation during restore
- No chicken-and-egg deadlock
- Disaster recovery "just works" without manual intervention

✅ **Kubernetes Scheduler Handles Pod Distribution**
- Scheduler's built-in spreading logic distributes pods across nodes
- No manual topology constraints needed
- Pods naturally balance across worker nodes over time

✅ **Simpler Operations**
- No special handling required for restores
- No manual node annotations needed
- Fewer moving parts = fewer failure modes

✅ **Same Outcome in Single-Zone**
- Volume ends up on same node as pod (shared storage pool)
- No performance difference
- No locality benefit lost (there was none to begin with)

#### Technical Analysis: Immediate vs WaitForFirstConsumer

**When WaitForFirstConsumer is Essential:**

**Multi-Zone Topology** (NOT our setup)
- Nodes in different availability zones (us-east-1a, us-east-1b)
- Volumes must be created in same zone as pod (cross-zone attachment often impossible)
- Cloud providers charge for cross-zone traffic ($0.01-0.02/GB)
- Latency penalty for cross-zone access (5-10ms+ added latency)
- **This is the ONLY legitimate use case for WaitForFirstConsumer**

**Heterogeneous Storage** (NOT our setup)
- Different nodes have different storage types (local NVMe vs network SAN)
- Need to ensure volume created on node with correct backend
- **We have shared ZFS storage - all nodes access same datastore**

**When Immediate is Correct:**

**Single-Zone Clusters** (our setup)
- All nodes in same physical location, same storage pool
- No cross-zone penalties to avoid
- No topology constraints to enforce
- **WaitForFirstConsumer provides ZERO benefit, only operational complexity**

**Shared Storage Architecture** (our setup)
- Proxmox ZFS datastore accessible from all worker nodes
- Volume location is irrelevant - any node can attach any volume
- **No performance or cost difference based on volume placement**

#### Resource Usage Analysis

**Claim: "Immediate wastes resources by provisioning unused volumes"**

**Reality Check:**
1. **ZFS is thin-provisioned by default** - volumes only consume space for actual data written
   - Creating a 100Gi PVC allocates 0 bytes until data is written
   - No resource waste from "pre-provisioning"
2. **PVCs are created on-demand** - we don't create unused PVCs
   - StatefulSets create PVCs when pods are created
   - Manual PVCs are only created when needed
   - **Theoretical problem with no real-world occurrence**

**Measured Impact:** NONE
- Immediate binding has identical resource usage to WaitForFirstConsumer in practice
- Both modes result in same number of volumes, same data stored
- No measurable difference in storage consumption, API calls, or performance

#### What We Actually Gave Up: Nothing

**WaitForFirstConsumer Benefits:**
- ✅ Topology-aware placement → **Not applicable (single-zone)**
- ✅ Deferred provisioning → **Not useful (thin-provisioned storage)**
- ✅ Guaranteed co-location → **Not beneficial (shared storage pool)**

**WaitForFirstConsumer Costs:**
- ❌ Velero restore failures (chicken-and-egg deadlock)
- ❌ Manual intervention required for disaster recovery
- ❌ Unbalanced pod distribution after restores
- ❌ Increased operational complexity
- ❌ Harder to troubleshoot PVC binding issues

**Net Result:** WaitForFirstConsumer has ZERO benefits and significant costs in single-zone clusters with shared storage.

#### Decision Matrix

| Cluster Architecture | Correct Binding Mode | Reason |
|---------------------|---------------------|---------|
| **Single-zone cluster** | `Immediate` | No topology constraints, no cross-zone penalties, simpler DR |
| **Multi-zone cluster** | `WaitForFirstConsumer` | Essential for zone-aware placement, avoids cross-zone costs |
| **Heterogeneous storage** | `WaitForFirstConsumer` | Ensures volume created on node with correct storage backend |
| **Shared storage pool** | `Immediate` | Volume location irrelevant, all nodes access same storage |

**Our Setup:** Single-zone cluster + shared ZFS storage = **Immediate is objectively correct**

#### Migration Path to Multi-Zone

If expanding to multi-zone architecture:

1. **Change StorageClass to WaitForFirstConsumer**
   ```yaml
   volumeBindingMode: WaitForFirstConsumer
   allowedTopologies:
   - matchLabelExpressions:
     - key: topology.kubernetes.io/zone
       values: [zone-a, zone-b, zone-c]
   ```

2. **Update Velero backup strategy**
   - Document manual PVC node annotation procedure for restores
   - Or accept unbalanced distribution and rely on descheduler for rebalancing
   - Or use CSI snapshots instead of filesystem backups (if Proxmox CSI supports it)

3. **Test disaster recovery procedure**
   - Verify restores work with WaitForFirstConsumer deadlock
   - Document manual intervention steps for production runbooks

#### Implementation Notes

The Proxmox CSI Helm chart **hardcodes** `volumeBindingMode: WaitForFirstConsumer` in the StorageClass template. To override this:

**Modified Chart Template** (`charts/proxmox-csi-plugin/templates/storageclass.yaml`):
```yaml
volumeBindingMode: {{ default "WaitForFirstConsumer" $storage.volumeBindingMode }}
```

**Values Override** (`k8s/infrastructure/storage/proxmox-csi/values.yaml`):
```yaml
storageClass:
  - name: proxmox-csi
    volumeBindingMode: Immediate  # Override hardcoded value
    # ... other settings
```

This allows configuring the binding mode while maintaining chart upgrade compatibility.

#### Related Issues

- **Longhorn to Proxmox CSI Migration**: Velero restore deadlock was discovered during storage migration (see [Migration Guide](../infrastructure/storage/longhorn-to-proxmox-migration.md))
- **Pod Distribution**: Without topology constraints, Kubernetes scheduler naturally spreads pods across nodes based on resource availability
- **Future Multi-Zone Support**: If expanding to multi-zone cluster, change to `WaitForFirstConsumer` and add `allowedTopologies` to StorageClass

## Volume Management

### Listing Volumes

View all persistent volumes:

```bash
kubectl get pv
kubectl get pvc -A
```

### Expanding Volumes

If the StorageClass allows expansion (`allowVolumeExpansion: true`), you can resize volumes:

```bash
kubectl patch pvc my-app-data -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'
```

### Deleting Volumes

The reclaim policy determines what happens when a PVC is deleted:
- `Delete`: Volume is automatically deleted from Proxmox
- `Retain`: Volume is kept in Proxmox for manual recovery

```bash
kubectl delete pvc my-app-data
```

## Access Mode Limitations

### ReadWriteMany (RWX) Not Supported

Proxmox CSI **only supports ReadWriteOnce (RWO)** access mode. The plugin does not support ReadWriteMany (RWX) or ReadOnlyMany (ROX) access modes.

**Why RWX doesn't work:**
- Proxmox CSI creates dedicated virtual disks on ZFS datastores
- Each disk can only be attached to one VM/node at a time
- There is no shared filesystem backend (like NFS or CephFS) to support multi-node access

**If your application requires RWX:**
1. **Verify actual need**: Many applications claim RWX but work fine with RWO when pods are scheduled on the same node
2. **Use RWO with pod scheduling**: Deploy pods using `podAntiAffinity` rules to ensure all pods requiring shared storage run on the same node
3. **Deploy NFS storage**: For true multi-writer workloads, deploy a separate NFS-based StorageClass (e.g., from a dedicated NAS or cloud NFS service)

**Migrating from Longhorn RWX PVCs:**

When migrating workloads from Longhorn (which supported RWX), you must patch PVCs to use RWO:

```bash
# Find RWX PVCs
kubectl get pvc -A -o jsonpath='{range .items[?(@.spec.accessModes[0]=="ReadWriteMany")]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}'

# Patch each RWX PVC to RWO
kubectl patch pvc <pvc-name> -n <namespace> -p '{"spec":{"accessModes":["ReadWriteOnce"]}}'
```

**Important**: Patch RWX PVCs **before** creating Velero backups for migration. The storage class mapping only handles storage class transformation, not access mode changes.

## Troubleshooting

### Access Mode Limitations

Proxmox CSI **only supports ReadWriteOnce (RWO)** access mode. See the [Access Mode Limitations](#access-mode-limitations) section for details.

### CSI Plugin Not Provisioning Volumes

1. Check the CSI plugin is running:
   ```bash
   kubectl get pods -n csi-proxmox
   ```

2. Check CSI controller logs:
   ```bash
   kubectl logs -n csi-proxmox -l app=proxmox-csi-controller
   ```

3. Verify the Proxmox credentials secret:
   ```bash
   kubectl get secret -n csi-proxmox proxmox-csi-plugin -o yaml
   ```

### Volume Stuck in Pending

Check PVC events:
```bash
kubectl describe pvc <pvc-name>
```

Common issues:
- Insufficient storage on Proxmox datastore
- Network connectivity between Kubernetes and Proxmox
- Invalid storage backend name
- CSI plugin not running

### Permission Errors

Verify the CSI user has correct permissions in Proxmox:
```bash
pveum user list | grep kubernetes-csi
pveum acl list | grep kubernetes-csi
```

## References

- [Proxmox CSI Plugin Documentation](https://github.com/sergelogvinov/proxmox-csi-plugin)
- [Kubernetes CSI Documentation](https://kubernetes-csi.github.io/docs/)
- [Proxmox Storage Documentation](https://pve.proxmox.com/wiki/Storage)
