# Proxmox CSI Storage

This guide explains how storage works in the homelab using the Proxmox CSI (Container Storage Interface) plugin for dynamic volume provisioning.

## Overview

The homelab uses the [Proxmox CSI Plugin](https://github.com/sergelogvinov/proxmox-csi-plugin) (`csi.proxmox.sinextra.dev`) as the **primary storage provisioner** for new Kubernetes workloads. This provides dynamic volume provisioning directly from Proxmox datastores without requiring additional storage layers.

**Current Storage Classes:**
- `proxmox-csi` — Primary storage class (Retain policy, WaitForFirstConsumer binding, expandable)
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

The storage bootstrap is managed through Terraform in the `tofu/bootstrap.tf` file.

### Proxmox CSI Plugin Setup

The `proxmox-csi-plugin` module in `tofu/bootstrap.tf` automatically configures:

1. **Proxmox User & Role**: Creates a `kubernetes-csi@pve` user with appropriate permissions
2. **API Token**: Generates an API token for the CSI plugin to authenticate with Proxmox
3. **Kubernetes Resources**:
   - Creates `csi-proxmox` namespace
   - Stores Proxmox credentials in a Kubernetes secret

**Command to deploy:**

```bash
cd tofu
tofu apply -target=module.proxmox-csi-plugin
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

### Required Proxmox Permissions

The Terraform `proxmox-csi-plugin` module automatically creates a Proxmox user and role with these minimal permissions:

- `Sys.Audit` - Required for CSI controller to query system capacity
- `VM.Audit` - View VM information
- `VM.Config.Disk` - Modify VM disk configuration
- `Datastore.Allocate` - Allocate storage space
- `Datastore.AllocateSpace` - Manage datastore capacity
- `Datastore.Audit` - View datastore information

These permissions are sufficient for basic CSI operations (creating, attaching, deleting volumes).

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
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

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

## Troubleshooting

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
