# K8s UniFi Network Application Deployment

> NOTICE: under active development, currently facing pvc permissions issues

Spike busting gist of a **production-ready** Kubernetes manifest for running [Ubiquiti’s UniFi Network Application](https://www.ui.com/) (a.k.a. UniFi Controller) backed by a **MongoDB** database. All data is persisted in PersistentVolumeClaims (PVCs), and both containers ultimately run as non-root for better security.

---

## Overview

**UniFi Network Application** (sometimes called “UniFi Controller”) is the central management software for Ubiquiti access points, switches, routers, and more. It stores all configuration, device adoption data, and statistics in a MongoDB database.

### Source Docs

References:

- https://www.talos.dev/v1.9/kubernetes-guides/configuration/pod-security
- https://github.com/linuxserver/docker-unifi-network-application/blob/main/README.md
- https://github.com/bitnami/containers/blob/main/bitnami/mongodb/README.md
- https://docs.cilium.io/en/latest/network/l2-announcements

### Key Features of this Deployment

1. **Persistent Storage**  
   All UniFi and MongoDB data is stored in PVCs. This ensures any restarts or rescheduling on different nodes will retain your network configuration and statistics.

2. **Non-Root Operation**  
   The main containers run as non-root to reduce the attack surface and comply with many security standards. We use **initContainers** to fix volume permissions ahead of time, allowing the main processes to run under user IDs 1000 (UniFi) and 1001 (Mongo).

3. **Minimal Privilege**  
   We set `allowPrivilegeEscalation: false` and drop all capabilities in the main containers, relying only on ephemeral root in initContainers to handle volume ownership. This approach aligns with the “least privileged” principle while still ensuring data directories are writable.

4. **PodSecurity**  
   The example is placed in a **`privileged`** namespace to enable initContainers to run as root. If you require a stricter PodSecurity posture, additional steps (like manually pre-chowning the volumes on the host) would be necessary.

5. **Configurable Memory Usage**  
   UniFi uses environment variables to control Java heap usage (`MEM_LIMIT` and `MEM_STARTUP`). Adjust them for your environment.

---

## Prerequisites

- **Kubernetes cluster** with a working StorageClass  
  - In the examples, we use `ssd` as the `storageClassName`. Replace it with the relevant StorageClass name for your cluster.
- **LoadBalancer** capability (for example, MetalLB, Cilium with ARP mode, or a cloud provider) if you want an external IP. Otherwise, change Service type to `NodePort` or `ClusterIP`.
- **kubectl** or a similar tool to apply manifests.

---

## Quick Start

1. **Save** this deployment yaml locally.
2. **Review and edit** `deployment.yaml` to fit your cluster:
   - Change the **StorageClass** references if needed.  
   - Change the **base64** password in the **Secret**.  
3. **Apply** the manifest:
   ```bash
   kubectl apply -f deployment.yaml
   ```
4. Watch the pods come up:
   ```bash
   kubectl -n unifi get pods -w
   ```
   You should see something like:
   ```
   NAME                                READY   STATUS    RESTARTS   AGE
   unifi-controller-...                1/1     Running   0          1m
   unifi-db-...                        1/1     Running   0          1m
   ```
5. Once both pods are running, the UniFi Network Application is available on the **unifi-controller** Service. If using a LoadBalancer, check:
   ```bash
   kubectl -n unifi get svc unifi-controller
   ```
   to see the external IP (or the node ports if using NodePort).

---

## File-by-File Explanation

Everything is consolidated in a single **`deployment.yaml`** for convenience. Within it, you’ll find:

1. **Namespace**:  
   ```yaml
   kind: Namespace
   metadata:
     name: unifi
     labels:
       pod-security.kubernetes.io/enforce: privileged
       ...
   ```
   - We label it “privileged” so the initContainers can run as root. If you prefer “baseline,” be sure you’re allowed to run root initContainers. If you choose “restricted,” you must handle volume ownership by other means (e.g., manual `chown` on the host or external provisioning).

2. **PVCs**:  
   ```yaml
   kind: PersistentVolumeClaim
   metadata:
     name: unifi-data
   ...
   kind: PersistentVolumeClaim
   metadata:
     name: mongo-data
   ...
   ```
   - These request 5Gi each from the `ssd` StorageClass (example). Adjust as needed.

3. **Secret** for MongoDB Credentials:  
   ```yaml
   kind: Secret
   metadata:
     name: unifi-mongo-credentials
   data:
     password: "c3VwZXJzZWNyZXQK"
   ```
   - The example password is `supersecret` (base64-encoded). To generate your own:
     ```bash
     echo -n "mypassword" | base64
     ```
     Then replace the string in the manifest.

4. **UniFi Controller Deployment**  
   - An **initContainer** `fix-permissions-unifi` runs as `root` to `chown` the `/config` volume to user 1000.  
   - The main container then runs as user 1000 (`runAsUser: 1000`), with no extra capabilities.  
   - The environment variables `MONGO_...` point to the external MongoDB service.

5. **UniFi Controller Service**  
   - Exposes ports for discovery, STUN, syslog, HTTP/HTTPS, etc. Type is `LoadBalancer` by default.

6. **MongoDB Deployment**  
   - Another initContainer `fix-mongo-permissions` sets correct ownership (`1001:1001`) on `/bitnami/mongodb`.  
   - The main Bitnami Mongo container runs as `UID=1001`, referencing the password from the same Secret.  
   - By default, we create a `root` user and a separate `unifi` user with its own database.  
   - If needed, advanced scripts (like granting additional roles for `unifi_stat`) can be placed in a ConfigMap mounted into `/docker-entrypoint-initdb.d`.

7. **MongoDB Service**  
   - Exposes port 27017. If only used internally, you can keep it as a ClusterIP.  

---

## Security Considerations

- **initContainers as root**: This design uses ephemeral root just long enough to fix file ownership. After that, the main containers run as unprivileged users. This is typically a good balance of security and usability.  
- **Network**: The UniFi controller listens on multiple ports. If you only want to expose the HTTPS UI (port 8443) and other essential ports, you can remove the ones you don’t need from the Service to reduce attack surface.  
- **PodSecurity**: We label the namespace as `privileged`. If you want a stricter policy, you must ensure volume ownership is handled externally.  
- **Secrets**: By default, the password is stored in a basic Kubernetes Secret. For advanced scenarios, consider integrating with Pulumi ESC, HashiCorp Vault, or other secret managers.

---

## Troubleshooting

1. **Pods stuck in `CrashLoopBackOff`**  
   - Likely a permission error on the PVC volume. Check logs:
     ```bash
     kubectl -n unifi logs <pod> -f
     ```
     If you see `mkdir: cannot create directory... Permission denied`, ensure the initContainer or volume ownership is correct, or that your StorageClass is not preventing writes from container root.

2. **Cannot connect to the UniFi UI**  
   - Verify the **Service** type is correct and that the external IP is allocated.  
   - If using NodePort, visit `NodeIP:NodePort`.  

3. **Mongo user/permissions**  
   - If you require custom roles, create a ConfigMap with `.sh` or `.js` scripts in `/docker-entrypoint-initdb.d`. See [Bitnami docs for more details](https://github.com/bitnami/containers/tree/main/bitnami/mongodb).

4. **Memory constraints**  
   - The `MEM_LIMIT` and `MEM_STARTUP` environment variables (in MB) define how much memory the UniFi Java process is allowed to use. Adjust as necessary if you have many devices or a large data set.

---

## Maintenance

- **Upgrades**:  
  - Check for new versions of the UniFi image: [lscr.io/linuxserver/unifi-network-application](https://hub.docker.com/r/linuxserver/unifi-network-application)  
  - Check for new versions of the Bitnami MongoDB image.  
  - Update your `deployment.yaml` image tags, then reapply:
    ```bash
    kubectl apply -f deployment.yaml
    ```
  - Kubernetes will gracefully roll out the new versions.

- **Backups**:  
  - **Mongo**: Consider a scheduled backup job or snapshot of the PVC.  
  - **UniFi**: The built-in UniFi UI can export a backup, or you can snapshot the `unifi-data` PVC.
