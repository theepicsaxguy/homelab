---
title: Manage Kubernetes configuration with GitOps
---

Once the Kubernetes cluster is provisioned (as detailed in the
[Provision the Talos Kubernetes cluster with Terraform](../tofu/opentofu-provisioning.md) documentation), all subsequent
configurations, applications, and infrastructure services are managed using a GitOps workflow. This workflow is powered
by ArgoCD.

## About GitOps and ArgoCD

The primary goal of this system is to establish the Git repository as the definitive source of truth for all
configurations running in the Kubernetes cluster. Manual changes to the cluster using `kubectl apply` for persistent
resources are generally avoided. Instead, the desired state is defined in YAML manifests within this repository, and
ArgoCD ensures that the cluster's actual state converges to this defined state.

:::info **Rationale for using GitOps:**

- **Version Control:** All changes are versioned, auditable, and easily revertible.
- **Consistency:** Ensures the cluster state aligns with the Git definitions, reducing configuration drift.
- **Automation:** ArgoCD automates the deployment and lifecycle management of applications and services.
- **Collaboration (if applicable):** Simplifies collaborative work on the cluster configuration by providing a central,
  versioned truth.

:::

## Directory structure overview

The `/k8s` directory is structured to organize Kubernetes manifests logically:

- **`applications/`:** Contains manifests for user-facing applications like media servers and AI tools. (See
  [Deploy and manage applications](./applications/application-management.md)).
- **`infrastructure/`:** Contains manifests for core cluster services such as networking, storage, authentication, and
  monitoring. (See [Deploy and manage infrastructure services](./infrastructure/infrastructure-management.md)).
- **`crds/`:** While many Custom Resource Definitions (CRDs) are installed by Helm charts managed by ArgoCD, this
  directory includes a Kustomization to apply CRDs that are prerequisites or globally required, such as the Kubernetes
  Gateway API CRDs. This centralization ensures their presence before controllers dependent on them are deployed.

## Key technologies

The following technologies are central to the Kubernetes configuration management:

- **ArgoCD:** The core of the GitOps workflow. It monitors this repository and applies any detected changes to the
  cluster.
  - **ApplicationSets:** Used extensively to dynamically generate ArgoCD `Application` resources. This is achieved based
    on directory structures or other generators, enabling management of most applications and infrastructure components
    without manual ArgoCD `Application` definitions for each.
  - **AppProjects:** Employed for logical grouping of applications and for defining Role-Based Access Control (RBAC),
    restricting sources, destinations, and resource kinds that applications within a project can manage.
- **Kustomize:** Utilized for managing variations and structuring Kubernetes YAML manifests. It allows for a base
  configuration to be defined and then customized with patches or overlays for different environments or specific needs.
  - **`kustomization.yaml` files:** Found throughout the `/k8s` directory, these files define how to build the manifests
    for particular components or groups.
  - **`disableNameSuffixHash: true`:** This option is often set in `generatorOptions` within Kustomize configurations to
    ensure predictable resource names, which simplifies referencing and management.
- **Helm:** Used for deploying third-party applications. ArgoCD can deploy Helm charts directly. In some instances,
  Kustomize might be used to manage Helm chart values or integrate Helm chart resources into a larger Kustomized
  application structure.
- **External Secrets Operator (ESO):** Manages sensitive data. The `external-secrets.io` controller syncs secrets from
  Bitwarden into Kubernetes `Secret` objects, keeping actual secret values out of the Git repository.
- **Cert-Manager:** Automates TLS certificate provisioning and management. It is used with Let's Encrypt for
  public-facing services and for managing internal Certificate Authorities (CAs).
- **Gateway API:** Adopted as the standard for ingress and traffic routing, utilizing Cilium's implementation.
  `HTTPRoute` and `TLSRoute` resources define how traffic reaches services.

## General workflow for changes

1. **Define Manifests:** You create or update Kubernetes YAML manifests (Deployments, Services, HTTPRoutes, Kustomize
   files, etc.) within this repository.
2. **Commit and Push:** You commit the changes to the appropriate branch (typically `main`).
3. **ArgoCD Synchronization:** ArgoCD detects the changes in the Git repository.
   - If an `Application` or `ApplicationSet` is configured for automatic synchronization (as most are in this setup),
     ArgoCD automatically applies the changes to the cluster.
   - Otherwise, you can trigger a synchronization manually via the ArgoCD User Interface (UI) or Command Line Interface
     (CLI).
4. **Verification:** You monitor the deployment status through the ArgoCD UI, `kubectl`, or application-specific logs.

## Key configuration entrypoints

To understand how most components are managed, you should review these primary ArgoCD ApplicationSets:

- **`k8s/infrastructure/application-set.yaml`:** This ApplicationSet is responsible for deploying the majority of the
  _infrastructure_ components. It scans specified directories within `/k8s/infrastructure/` and creates an ArgoCD
  Application for each.
- **`k8s/applications/application-set.yaml`:** Similarly, this ApplicationSet deploys most of the user-facing
  _applications_ by scanning directories within `/k8s/applications/`.

These two ApplicationSets serve as the main entry points for ArgoCD to manage the bulk of the cluster's declared state
based on the contents of this Git repository. This GitOps-centric approach, combined with ArgoCD and Kustomize, provides
a powerful and maintainable way to manage the Kubernetes cluster.
