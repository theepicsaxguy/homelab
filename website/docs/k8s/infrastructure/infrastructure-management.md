---
title: Deploy and manage infrastructure services
---

This document details how core infrastructure services for the Kubernetes cluster are deployed and managed. Consistent
with application management, this process is governed by GitOps principles using ArgoCD. These services provide
essential capabilities like networking, storage, authentication, and monitoring.

## About infrastructure management

Infrastructure components are organized within the `/k8s/infrastructure/` directory, typically grouped by their
function.

### Infrastructure categories:

- `auth/` (e.g., Authentik for identity management)
- `controllers/` (e.g., ArgoCD (managed via app-of-apps), Cert-Manager, External Secrets Operator, Argo Rollouts, Trust
  Manager)
- `crds/` (Base Custom Resource Definitions (CRDs) like the Kubernetes Gateway API. Most component-specific CRDs are
  bundled with their Helm charts.)
- `database/` (e.g., Zalando PostgreSQL Operator for managing PostgreSQL instances)
- `deployment/` (e.g., Kubechecks for Kubernetes manifest validation)
- `monitoring/` (e.g., Kube Prometheus Stack, Hubble for network observability)
- `network/` (e.g., Cilium Container Network Interface (CNI) configuration, CoreDNS configuration, Cloudflared, Gateway
  API resources)
- `storage/` (e.g., Longhorn for persistent block storage)
- `overlays/` (Kustomize overlays, primarily "single" for infrastructure rollouts)

Each category typically contains:

- `kustomization.yaml`: A Kustomize file that groups components within that category.
- `project.yaml`: An ArgoCD `AppProject` for the category, allowing for scoped permissions and settings.

## Core deployment mechanism: Infrastructure `ApplicationSet`

The deployment of these infrastructure components is primarily driven by an ArgoCD `ApplicationSet` defined in:

- **File:** `/k8s/infrastructure/application-set.yaml`

### How the infrastructure ApplicationSet works

This `ApplicationSet` instructs ArgoCD to discover and manage infrastructure components based on the directory structure
within `/k8s/infrastructure/` in the Git repository.

#### 1. Component discovery: `generators`

The `git` generator is utilized, similar to the applications ApplicationSet.

- It scans directories such as `/k8s/infrastructure/controllers`, `/k8s/infrastructure/network`, etc. :::info
  **Rationale for directory-based generation:** This allows for the automatic discovery and management of new
  infrastructure components as their configurations are added to these designated directories. :::

#### 2. ArgoCD Application template: `template`

This section defines how each ArgoCD `Application` for an infrastructure component will be configured.

- `metadata.name: 'infra-{{ path.basename }}'`: Generates names like `infra-controllers`, `infra-network`.
- `spec.project: infrastructure`: Assigns all applications to the `infrastructure` AppProject.
- `spec.source.path: '{{ path }}'`: The source path is the directory discovered by the generator.
- `spec.source.kustomize: {}`: ArgoCD uses Kustomize to build the manifests.
- `spec.destination.namespace: infrastructure-system`: This is the default deployment namespace if not overridden by the
  component's Kustomize setup. Many infrastructure components are deployed into their own dedicated namespaces (e.g.,
  `cert-manager`, `longhorn-system`).
- `spec.syncPolicy`: Configured for automated synchronization with pruning of deleted resources and self-healing of
  configuration drift.
  - `CreateNamespace=true`, `ApplyOutOfSyncOnly=true`, `PruneLast=true`, `RespectIgnoreDifferences=true`: These sync
    options are chosen for convenient and robust synchronization.

### Root `kustomization.yaml` and `project.yaml` for infrastructure

- **File:** `/k8s/infrastructure/kustomization.yaml`

  - This is the top-level Kustomize configuration for infrastructure components, listing categories like `network`,
    `storage`, and `controllers` as resources.
  - `generatorOptions.disableNameSuffixHash: true` is used for predictable resource naming.

- **File:** `/k8s/infrastructure/project.yaml`
  - Defines the main `infrastructure` AppProject.
  - Permissions (`sourceRepos`, `destinations`, `clusterResourceWhitelist`, `namespaceResourceWhitelist`) are broad for
    homelab flexibility but would be more restricted in a production environment.
  - `argocd.argoproj.io/namespace-resource-allowlist: '[{"group": "", "kind": "Namespace"}]'`: This annotation
    explicitly allows this project to create `Namespace` resources, which is often necessary for infrastructure
    components that reside in their own namespaces.

## Key infrastructure components and design decisions

Below are highlights of key infrastructure components and the rationale behind their configuration:

- **Cilium (`/k8s/infrastructure/network/cilium/`)**

  - **Function:** Provides CNI capabilities, network observability, and security features.
  - **Deployment:** Deployed via its Helm chart. The initial bootstrap is handled by the Talos machine configuration
    (see [Provision the Talos Kubernetes cluster with Terraform](../tofu/README.md)). This ArgoCD application manages
    its configuration post-bootstrap. It includes a `CiliumL2AnnouncementPolicy` for exposing LoadBalancer services on
    the Local Area Network (LAN) and a `CiliumLoadBalancerIPPool` to define IP ranges for these services. :::info
    **Rationale for Cilium:** Cilium is chosen for its powerful eBPF-based networking, robust network policy
    enforcement, integrated Kubernetes Gateway API implementation, and observability features with Hubble.
    `kubeProxyReplacement: true` is enabled for improved performance and efficiency. The `k8sServiceHost` and
    `k8sServicePort` are set to `localhost` and `7445` respectively, specific to the Talos setup where the Kubelet
    proxies kube-apiserver access. `bpf.hostLegacyRouting: true` was necessary in the Talos environment for correct host
    networking integration. Kubernetes handles Pod Classless Inter-Domain Routing (CIDR) allocation
    (`ipam.mode: kubernetes`), and the `CiliumLoadBalancerIPPool` provides Cilium with a specific IP address Management
    (IPAM) range (`10.25.150.220-10.25.150.255`) for `LoadBalancer` services. L2 Announcements
    (`l2announcements.enabled: true`), along with the `CiliumL2AnnouncementPolicy`, enable Cilium to advertise
    LoadBalancer IPs on the local network. :::

- **CoreDNS (`/k8s/infrastructure/network/coredns/`)**

  - **Function:** Serves as the cluster's Domain Name System (DNS) service.
  - **Deployment:** Initial deployment is managed via the Talos machine configuration. This Kustomization primarily
    manages its `ConfigMap` (the `Corefile`) and ensures the deployment state aligns with the Git repository. :::info
    **Rationale for Corefile configuration:** The `Corefile` includes standard Kubernetes DNS resolution for services
    and pods within the `kube.pc-tips.se` internal domain. It forwards external DNS queries to public resolvers (e.g.,
    `1.1.1.1`, `8.8.8.8`) and enables caching and standard operational plugins like `loop`, `reload`, and `loadbalance`.
    :::

- **Gateway API (`/k8s/infrastructure/network/gateway/` and CRDs in `/k8s/infrastructure/crds/`)**

  - **Function:** A modern Kubernetes API for configuring L4/L7 traffic routing.
  - **Deployment:** The Gateway API CRDs are applied directly. `Gateway` resources are then defined:
    - `external`: For services exposed to the internet (potentially via Cloudflare), using IP `10.25.150.222`.
    - `internal`: For services exposed only on the internal network, using IP `10.25.150.220`.
    - `tls-passthrough`: For services that manage their own TLS termination (e.g., Proxmox, TrueNAS, Omada controller),
      using IP `10.25.150.221`.
  - **TLS Management:** Cert-Manager is used to provision certificates (defined in `cert-pc-tips.yaml`) for
    `*.pc-tips.se`. These certificates are attached to the HTTPS listeners on the `external` and `internal` gateways.
    For `tls-passthrough` gateways, TLS termination is handled by the backend services themselves. :::info **Rationale
    for Gateway API:** It is the designated successor to the Ingress API, offering enhanced features, improved role
    separation for managing traffic routing, and a more expressive API. Cilium provides the underlying implementation
    for these Gateway resources. :::

- **Cert-Manager (`/k8s/infrastructure/controllers/cert-manager/`)**

  - **Function:** Automates the management and issuance of TLS certificates.
  - **Deployment:** Deployed via its Helm chart. _ `cloudflare-issuer.yaml`: A `ClusterIssuer` configured to use
    Cloudflare for DNS01 challenges to obtain Let's Encrypt certificates. The Cloudflare API token is managed by an
    `ExternalSecret` (`cert-manager-secrets-external.yaml`) that syncs it from Bitwarden. _ `internal-ca-issuer.yaml`:
    Establishes a self-signed Certificate Authority (CA) and a `ClusterIssuer` (`internal-issuer`) that uses this CA to
    issue certificates for internal services. This is useful for mutual TLS (mTLS) or services not exposed publicly.
    :::info **Rationale for Cert-Manager setup:** This configuration provides an automated and secure certificate
    lifecycle for both public-facing and internal services. The DNS01 challenge type is robust for obtaining wildcard
    certificates. :::

- **External Secrets Operator (ESO) (`/k8s/infrastructure/controllers/external-secrets/`)**

  - **Function:** Synchronizes secrets from external secret management systems (in this case, Bitwarden) into Kubernetes
    `Secret` objects.
  - **Deployment:** Deployed via its Helm chart. \* `bitwarden-store.yaml`: Defines a `ClusterSecretStore` named
    `bitwarden-backend` configured to connect to the Bitwarden instance. It uses an access token stored as a Kubernetes
    secret (`bitwarden-access-token`). The Bitwarden SDK server requires a certificate for secure communication, which
    is issued by the `internal-issuer` via `bitwarden-certificate.yaml`. :::info **Rationale for External Secrets
    Operator:** This approach keeps sensitive data out of the Git repository and allows for centralized management of
    secrets in a dedicated system like Bitwarden. :::

- **Longhorn (`/k8s/infrastructure/storage/longhorn/`)**

  - **Function:** Provides distributed block storage for Kubernetes.
  - **Deployment:** Deployed via its Helm chart. _ `defaultClass: true`: Configures Longhorn as the default
    `StorageClass` for the cluster. _ `defaultDataPath: /var/lib/longhorn/`: Specifies the path on worker nodes where
    Longhorn stores data. Worker nodes are provisioned with dedicated disks mounted at this location (see
    [Provision the Talos Kubernetes cluster with Terraform](../tofu/README.md)). \* `http-route.yaml`: Exposes the
    Longhorn UI for management and monitoring. :::info **Rationale for Longhorn:** Longhorn offers replicated,
    persistent storage suitable for stateful applications, providing features like snapshots and backups. It is
    relatively straightforward to set up and manage in a homelab environment. :::

- **Kube Prometheus Stack (`/k8s/infrastructure/monitoring/prometheus-stack/`)**

  - **Function:** A comprehensive monitoring solution including Prometheus, Alertmanager, and Grafana.
  - **Deployment:** Deployed via its Helm chart. This bundle provides Prometheus for metrics collection, Alertmanager
    for handling alerts, and Grafana for dashboards, along with various service monitors and exporters. \* `HTTPRoute`
    resources are defined to expose the Prometheus, Grafana, and Alertmanager UIs. :::info **Rationale for Kube
    Prometheus Stack:** This stack is a de-facto standard for Kubernetes monitoring, offering deep insights into cluster
    and application health. It is managed via a dedicated ArgoCD `Application` resource (`kube-prometheus-stack.yaml`)
    due to its complexity and the benefits of server-side apply for CRD-heavy charts. :::

- **Authentik (`/k8s/infrastructure/auth/authentik/`)**

  - **Function:** Serves as an identity provider (IdP) and Single Sign-On (SSO) solution.
  - **Deployment:** Deployed via its Helm chart. _ It uses PostgreSQL as a backend, which is intended to be provisioned
    by the Zalando Postgres Operator (defined in `database.yaml`). _ Secrets (database credentials, Redis password,
    bootstrap tokens) are managed via `ExternalSecret` resources (`externalsecret.yaml`) sourced from Bitwarden. _
    `httproute.yaml` exposes the Authentik user interface and API. _ `blueprints/`: Authentik flow configurations,
    provider setups, and other internal settings are stored as blueprints in this directory. These are applied via a
    ConfigMap referenced in the Helm values. :::info **Rationale for Authentik blueprints:** This enables declarative
    management of Authentik's internal configuration through Git, aligning with GitOps principles. ::: \*
    `outpost.yaml`: Defines a deployment for Authentik's proxy outpost, which can be used to protect applications with
    authentication and authorization policies. :::info **Rationale for Authentik:** Authentik provides a powerful and
    flexible solution for managing user authentication and authorization across various services in the homelab. :::

- **Zalando Postgres Operator (`/k8s/infrastructure/database/postgresql/`)**

  - **Function:** Manages PostgreSQL database instances within Kubernetes.
  - **Deployment:** Deployed via its Helm chart into its own `postgres-operator` namespace. :::info **Rationale for
    Zalando Postgres Operator:** This operator allows for declarative definition and management of PostgreSQL clusters
    (such as the one required by Authentik, defined in `/k8s/infrastructure/auth/authentik/database.yaml`). The operator
    handles provisioning, high availability (if configured with multiple instances), backups, and other management
    tasks, offering a more robust and Kubernetes-native solution than deploying PostgreSQL as a simple Deployment. :::

- **Trust Manager (`/k8s/infrastructure/controllers/trust-manager/`)**

  - **Function:** Distributes CA bundles to namespaces within the cluster.
  - **Deployment:** Deployed via its Helm chart, along with its Container Storage Interface (CSI) driver for injecting
    trust anchors into pods. The `/k8s/infrastructure/controllers/trust-manager/trust-manager-bundle.yaml` file defines
    a `Bundle` resource. This bundle takes the `internal-ca-tls` secret (which contains the CA certificate created by
    Cert-Manager for internal use) and makes its `ca.crt` available in a ConfigMap. This ConfigMap can then be consumed
    by pods in any namespace labeled with `trust-manager.cert-manager.io/inject-trust: "true"`. :::info **Rationale for
    Trust Manager:** When services within the cluster need to securely communicate with other internal services that use
    certificates issued by the internal CA (e.g., for mTLS or accessing internal HTTPS endpoints protected by internal
    certificates), Trust Manager ensures that the necessary CA certificate is available to them for validation. :::

- **Argo Rollouts (`/k8s/infrastructure/controllers/argo-rollouts/`)**
  - **Function:** Provides advanced deployment strategies such as blue/green and canary deployments.
  - **Deployment:** Installed from its upstream manifest URL via Kustomize. This includes its dashboard component for
    visualizing rollout status. :::info **Rationale for Argo Rollouts:** This component enables safer and more
    controlled application updates, allowing for automated analysis during deployment and progressive traffic shifting,
    with options for automated promotion or rollback based on metrics. Common analysis templates are defined in
    `/k8s/applications/common/analysis-template.yaml`. :::

This infrastructure setup aims to provide a solid and automated foundation for running a variety of applications and
services with a good degree of security and observability.
