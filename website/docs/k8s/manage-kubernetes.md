# Manage Kubernetes Configuration with GitOps

Once your Kubernetes cluster is provisioned (see [Provision the Talos Kubernetes cluster with OpenTofu](../tofu/provisioning-task-guide.md)), all ongoing configurations, applications, and core services are managed using a GitOps workflow powered by ArgoCD.

---

## Why Use GitOps and ArgoCD?

GitOps makes your Git repository the single source of truth for all Kubernetes resources. You define your desired state in YAML files. ArgoCD automatically keeps the cluster in sync with this state, so manual `kubectl apply` isn't needed for persistent changes.

### Benefits of GitOps

- **Version Control:** All changes are tracked, straightforward to audit, and quick to roll back.
- **Consistency:** The actual cluster state always matches your Git files, preventing drift.
- **Automation:** Deployments and updates happen automatically.
- **Collaboration:** Multiple users can safely propose, review, and merge changes.

---

## Directory Structure Overview

Your `/k8s` directory organizes Kubernetes manifests by purpose:

- **`applications/`**: User-facing apps (media servers, AI tools).
  See: [Deploy and manage applications](applications/application-management.md)
- **`infrastructure/`**: Core services (networking, storage, monitoring, authentication).
  See: [Deploy and manage infrastructure services](infrastructure/infrastructure-management.md)
- **`crds/`**: Shared or prerequisite Custom Resource Definitions, such as the Gateway API CRDs.

---

## Core Technologies

I use several tools and operators to support this workflow:

- **ArgoCD**: Watches Git for changes and syncs them to the cluster.
  - **ApplicationSets:** Dynamically creates ArgoCD Applications based on your directory layout.
  - **AppProjects:** Groups applications and restricts permissions (RBAC, source/repos, target namespaces).
- **Kustomize**: Modularizes and patches YAML files for flexible, reusable configs.
  - Look for `kustomization.yaml` in each directory.
  - `disableNameSuffixHash: true` keeps resource names consistent for quick reference.
- **Helm**: Deploys complex third-party workloads; managed through ArgoCD or wrapped by Kustomize.
- **External Secrets Operator (ESO)**: Automatically syncs secrets from Bitwarden into Kubernetes, so secrets stay out of Git repositories.
- **Cert-Manager**: Issues and renews TLS certificates from Let’s Encrypt or internal Certificate Authorities.
- **Gateway API**: Modernizes ingress/routing, using Cilium as the implementation.

---

## Typical Workflow for Changes

1. **Edit manifests:** Add or update YAML files for Deployments, Services, HTTPRoutes, etc.
2. **Commit and push:** Save changes to your repository (typically the `main` branch).
3. **Sync with ArgoCD:**
   - Automatic sync: Most ArgoCD Applications and ApplicationSets watch for changes and sync automatically.
   - Manual sync (optional): Trigger syncs via the ArgoCD UI or CLI if needed.
4. **Verify:** Review deployment status in ArgoCD, test with `kubectl`, or inspect app logs.

---

## Entry Points: Where to Look

The following files control how most of your cluster is managed:

- **`k8s/infrastructure/application-set.yaml`:**
  Deploys infrastructure services by scanning `/k8s/infrastructure/`.
- **`k8s/applications/application-set.yaml`:**
  Deploys user applications by scanning `/k8s/applications/`.

These ApplicationSets let ArgoCD manage large portions of your cluster automatically. Just create a new directory, add manifests, and update the ApplicationSet. ArgoCD handles the rest.

---

By managing your cluster this way (with Git, ArgoCD, Kustomize, and Helm), you gain automation, safety, and clarity. All cluster changes are repeatable, traceable, and auditable, making operations predictable and resilient.
