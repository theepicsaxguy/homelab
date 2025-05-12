---
title: Deploy and manage applications
---

This document outlines the strategy for managing and deploying user-facing applications on the Kubernetes cluster. The
core methodology is GitOps, orchestrated by ArgoCD.

## About application management

Applications are organized into functional categories within the `/k8s/applications/` directory. This structure promotes
clarity and ease of management.

### Typical application categories

- `ai/` (e.g., OpenWebUI, KaraKeep)
- `automation/` (e.g., Frigate, MQTT)
- `media/` (e.g., Jellyfin, \*arr stack, SABnzbd)
- `network/` (Network-related applications that are not core infrastructure, e.g., AdGuard Home)
- `tools/` (e.g., IT-Tools, Whoami)
- `web/` (e.g., BabyBuddy, custom web applications)
- `external/` (Definitions for services running outside the Kubernetes cluster but integrated or referenced by internal
  services)

Each category typically includes:

- `kustomization.yaml`: A Kustomize file that groups all applications within that category.
- `project.yaml`: An ArgoCD `AppProject` for the category, enabling granular Role-Based Access Control (RBAC) and
  resource restrictions if necessary.

Within each category, individual applications reside in their own subdirectories (e.g.,
`/k8s/applications/media/jellyfin/`). Each application subdirectory contains all its necessary Kubernetes manifests,
managed by its own `kustomization.yaml`.

## Core deployment mechanism: ArgoCD ApplicationSet

The primary tool for deploying these applications is the root `ApplicationSet` defined in:

- **File:** `/k8s/applications/application-set.yaml`

### How the ApplicationSet works

This `ApplicationSet` resource instructs ArgoCD to automatically discover and manage applications based on the directory
structure within `/k8s/applications/` in the Git repository.

#### 1. Application discovery: `generators`

The `git` generator is used to scan specific directories within the `homelab` GitHub repository
(`https://github.com/theepicsaxguy/homelab.git`).

- `repoURL`: Points to the homelab Git repository.
- `revision: main`: Always uses the `main` branch as the source of truth.
- `directories`: A list of paths such as `k8s/applications/media`, `k8s/applications/tools`, etc. :::info **Rationale
  for directory-based generation:** For each directory found in this list, ArgoCD generates an `Application` resource
  based on the `template` section. This means adding a new application involves creating its subdirectory (e.g.,
  `/k8s/applications/newapp/`) with its manifests and adding this new path to the `directories` list in the
  ApplicationSet. ArgoCD will then automatically detect and deploy it. :::

#### 2. Application configuration template: `template`

This section defines the configuration for each ArgoCD `Application` that is generated.

- `metadata.name: 'apps-{{ path.basename }}'`: The ArgoCD Application name is dynamically generated (e.g., `apps-media`,
  `apps-tools`). :::info **Rationale for `{{ path.basename }}`:** This convention makes Application names predictable
  and directly tied to the directory structure, improving traceability. :::
- `spec.project: applications`: All generated applications are assigned to the `applications` AppProject. :::info
  **Rationale for project assignment:** This provides a top-level grouping for RBAC and policies defined in the main
  `applications` AppProject (`/k8s/applications/project.yaml`), allowing for consistent permission management. :::
- `spec.source`:
  - `repoURL` and `targetRevision: main` are consistent with the generator.
  - `path: '{{ path }}'`: The source path for the application's manifests is the directory discovered by the generator.
  - `kustomize: {}`: Instructs ArgoCD to use Kustomize for building the manifests from the specified path. :::info
    **Rationale for Kustomize:** Kustomize allows for clean structuring of each application's manifests and facilitates
    management of common configurations or environment-specific patches. :::
- `spec.destination`:
  - `namespace: applications-system`: This is the _default_ deployment namespace if an application's Kustomize setup
    does not specify its own. Most applications in this setup define their target namespace within their own
    Kustomization.
  - `server: https://kubernetes.default.svc`: Deploys to the local Kubernetes cluster where ArgoCD is running.
- `spec.syncPolicy`:
  - `automated: { prune: true, selfHeal: true }`: Enables ArgoCD to automatically synchronize changes from Git, remove
    resources no longer defined in Git, and correct any drift in the live state. :::info **Rationale for automated
    sync:** This ensures a hands-off, truly GitOps-driven management style, where the Git repository is the single
    source of truth. :::
  - `syncOptions`:
    - `CreateNamespace=true`: ArgoCD will create the target namespace if it doesn't exist.
    - `ApplyOutOfSyncOnly=true`: Optimizes synchronization by only applying changes to resources that are out of sync.
    - `PruneLast=true`: If pruning resources, this option ensures pruning occurs after other synchronization operations,
      which can be safer.
    - `RespectIgnoreDifferences=true`: Allows specific fields to be ignored by ArgoCD during diffing, if configured
      within an Application.

### Root `kustomization.yaml` and `project.yaml` for applications

- **File:** `/k8s/applications/kustomization.yaml`

  - This is the top-level Kustomize configuration for all applications. It lists the category subdirectories (e.g.,
    `ai`, `media`, `tools`) as Kustomize resources.
  - `generatorOptions.disableNameSuffixHash: true`: Used for predictable resource names, simplifying DNS, service
    discovery, and overall management.

- **File:** `/k8s/applications/project.yaml`
  - Defines the main `applications` AppProject in ArgoCD.
  - `description`: "Applications components managed through GitOps (all resources allowed)".
  - `sourceRepos: ['*']`, `destinations: ['*']`, `clusterResourceWhitelist: ['*']`, `namespaceResourceWhitelist: ['*']`:
    These permissions are intentionally broad for flexibility in a homelab environment. In more restrictive settings,
    these would be significantly locked down.
  - `roles`: Defines `admin` and `readonly` roles scoped to this project.
  - `syncWindows`: Allows manual synchronization at any time.
  - `orphanedResources: { warn: true }`: Configures ArgoCD to issue a warning if it detects resources in the cluster
    that it believes it should manage but are not defined in Git.

## Structure of an individual application (Example: KaraKeep)

The KaraKeep application (located at `/k8s/applications/ai/karakeep/`) serves as a typical example of how individual
applications are structured:

- **`kustomization.yaml`:**

  - Defines the target `namespace: karakeep`.
  - Uses `configMapGenerator` to create a `karakeep-configuration` ConfigMap for non-sensitive settings (e.g.,
    `NEXTAUTH_URL`). :::info **Rationale for ConfigMap generator:** Keeps configuration proximal to the application
    definition and avoids hardcoding values in deployment manifests. :::
  - Lists all other YAML files in its directory as `resources`.
  - Includes `replacements` to patch the image tag in `web-deployment.yaml` with the `KARAKEEP_VERSION` from the
    ConfigMap. :::info **Rationale for Kustomize replacements:** This allows for managing the application version from a
    single point (the ConfigMap generator); Kustomize then propagates this version to the Deployment's image field. :::

- **`namespace.yaml`:** Defines the `karakeep` namespace.

- **Deployment Manifests (e.g., `web-deployment.yaml`, `chrome-deployment.yaml`):**

  - Standard Kubernetes `Deployment`s.
  - `replicas: 1`: Sufficient for most homelab applications.
  - `securityContext`: Generally configured to enhance security:
    - `runAsNonRoot: true`, `runAsUser`, `runAsGroup`, `fsGroup`: Ensures containers do not run with root privileges.
    - `allowPrivilegeEscalation: false`.
    - `readOnlyRootFilesystem: true` (where feasible, e.g., for `prowlarr`). If `false`, it's typically because the
      application requires write access to its root filesystem.
    - `capabilities: { drop: ["ALL"] }`: Drops all Linux capabilities by default.
    - `seccompProfile: { type: RuntimeDefault }`: Applies the default seccomp profile from the container runtime.
      :::info **Rationale for security settings:** These measures reduce the potential impact of a container compromise,
      following a defense-in-depth strategy. :::
  - `resources`: CPU and memory `requests` and `limits` are set. :::info **Rationale for resource requests/limits:**
    Ensures fair resource allocation and prevents resource starvation among applications. Values are based on observed
    usage or application recommendations. :::
  - `envFrom`: Often uses `secretRef` to inject secrets managed by ExternalSecrets (e.g., `karakeep-secrets`) and
    `configMapRef` for non-sensitive configuration.
  - `volumeMounts` and `volumes`: Define how PersistentVolumeClaims (PVCs) or `emptyDir` volumes are mounted.

- **Service Manifests (`*-service.yaml`):**

  - Define how applications are exposed, either internally (`ClusterIP`) or externally (`LoadBalancer`).
  - `io.cilium/lb-ipam-ips`: For `LoadBalancer` services, this Cilium-specific annotation requests a specific IP from a
    predefined IP pool. :::info **Rationale for specific LoadBalancer IP:** Provides predictable external IP addresses
    for certain services. :::

- **PersistentVolumeClaim Manifests (`*-pvc.yaml`):**

  - Define `PersistentVolumeClaim`s for stateful data.
  - `storageClassName: longhorn`: Longhorn is used for distributed, replicated block storage.
  - `accessModes`: Typically `ReadWriteOnce` for Longhorn. For shared NFS mounts like `media-share`, `ReadWriteMany` is
    used.

- **Ingress/Gateway Manifests (`http-route.yaml`):**

  - Defines a Gateway API `HTTPRoute` to expose the application externally via a hostname (e.g., `karakeep.pc-tips.se`).
  - `parentRefs`: Links to `internal` and/or `external` Gateway resources in the `gateway` namespace. :::info
    **Rationale for multiple parentRefs:** Allows a single route definition to be attached to different gateways, for
    instance, one for internal network access and another for Cloudflare-proxied external access. :::
  - `backendRefs`: Points to the application's `Service` and port.

- **ExternalSecret Manifests (e.g., `karakeep-secrets-external.yaml`):**

  - Defines an `ExternalSecret` resource.
  - `secretStoreRef: { name: bitwarden-backend, kind: ClusterSecretStore }`: Instructs ExternalSecrets to use the
    Bitwarden `ClusterSecretStore`.
  - `target.name`: Specifies the name of the Kubernetes `Secret` that will be created or synchronized.
  - `data`: Maps keys in the Kubernetes `Secret` to specific items or fields in Bitwarden using their unique IDs.
    :::info **Rationale for ExternalSecrets:** This is the method for securely managing API keys, passwords, and other
    sensitive data without committing them to the Git repository. :::

- **NFS PV/PVC for Shared Media (`/k8s/applications/media/nfs-pv.yaml`,
  `/k8s/applications/media/media-share-pvc.yaml`):**
  - A `PersistentVolume` (`nfs-pv.yaml`) is manually defined to point to a TrueNAS NFS share
    (`172.20.20.103:/mnt/wd1/media_share`).
  - A `PersistentVolumeClaim` (`media-share-pvc.yaml`) then claims this specific PV using `volumeName: media-share` and
    `storageClassName: ""`. :::info **Rationale for NFS for media:** This configuration provides a large, shared
    `ReadWriteMany` storage pool accessible by all media applications, allowing them to use a common library of files.
    Network File System (NFS) is suitable for this shared file access requirement. The
    `persistentVolumeReclaimPolicy: Retain` setting on the PV is important to prevent data loss if the PVC is
    inadvertently deleted. :::

This structured approach, leveraging ArgoCD ApplicationSets and Kustomize, enables consistent and automated management
of a diverse range of applications.
