# Proxmox CSI Storage

This guide explains how storage works in the homelab using the Proxmox CSI (Container Storage Interface) plugin for dynamic volume provisioning.

## Overview

The homelab uses the [Proxmox CSI Plugin](https://github.com/sergelogvinov/proxmox-csi-plugin) to provide dynamic storage provisioning for Kubernetes workloads. This allows applications to automatically request and receive persistent storage without manual intervention.

## Architecture

### Dynamic Storage Provisioning (Recommended)

The Proxmox CSI plugin enables **dynamic provisioning** through Kubernetes StorageClasses. When a PersistentVolumeClaim (PVC) is created, Kubernetes automatically:

1. Creates a volume on Proxmox storage
2. Creates a PersistentVolume (PV) in Kubernetes
3. Binds the PVC to the PV
4. Mounts the volume to the requesting pod

**This is the recommended approach for most workloads.**

```yaml
# Example PVC using dynamic provisioning
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-csi  # Uses the Proxmox CSI StorageClass
  resources:
    requests:
      storage: 10Gi
```

### Static Volume Provisioning (Legacy)

For specific use cases like migrating existing data or manual volume placement, you can pre-provision static volumes. The `bootstrap/volumes` module supports this workflow.

**Use static provisioning only when:**
- Migrating existing Proxmox volumes into Kubernetes
- Requiring specific volume placement across Proxmox nodes
- Working with legacy applications that need pre-created volumes

## Bootstrap Configuration

The storage bootstrap is managed through Terraform in the `tofu/bootstrap.tf` file.

### Proxmox CSI Plugin Setup

The `proxmox-csi-plugin` module automatically configures:

1. **Proxmox User & Role**: Creates a `kubernetes-csi@pve` user with appropriate permissions
2. **API Token**: Generates an API token for the CSI plugin to authenticate with Proxmox
3. **Kubernetes Resources**:
   - Creates the `csi-proxmox` namespace
   - Stores the Proxmox credentials in a Kubernetes secret

```hcl
# Automatically configured when you run tofu apply
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

The CSI plugin user is granted these permissions:
- `VM.Audit` - View VM information
- `VM.Config.Disk` - Modify VM disk configuration
- `Datastore.Allocate` - Allocate storage space
- `Datastore.AllocateSpace` - Manage datastore capacity
- `Datastore.Audit` - View datastore information

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

### Static Volume Example (Optional)

To pre-provision volumes, add them to `tofu/bootstrap_volumes.auto.tfvars`:

```hcl
bootstrap_volumes = {
  "pv-prometheus" = {
    node    = "host3"        # Proxmox node
    size    = "50G"          # Volume size
    storage = "local-zfs"    # Storage backend
  }
  "pv-postgres" = {
    node    = "host3"
    size    = "20G"
  }
}
```

Then reference the pre-created volume in your PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-csi
  volumeName: pv-prometheus  # Bind to pre-created PV
  resources:
    requests:
      storage: 50Gi
```

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
