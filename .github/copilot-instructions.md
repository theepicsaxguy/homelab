# GitHub Copilot Context & Instructions

This document provides context and instructions for GitHub Copilot to better assist with this homelab infrastructure repository.

## Project Overview

This is a **GitOps-focused homelab infrastructure repository**, managing:

- **Kubernetes** cluster deployments using Talos
- **Infrastructure as Code** using OpenTofu (Terraform)
- **ArgoCD-based** application deployments
- **Monitoring & Security** components

## Key Preferences

### Infrastructure Patterns

- **GitOps-Only**: All infrastructure is managed declaratively via GitOps.
- **Networking**: Prefer **Cilium** over Talos' default setup.

---

## Code Structure

### Kubernetes (`k8s/` Directory)

- **Applications**: `k8s/apps/` (e.g., authentication, controllers, monitoring)
- **Infrastructure Components**: `k8s/infra/` (e.g., DNS, networking, storage)
- **ArgoCD Configuration**: `k8s/argocd/`
  - ApplicationSets: `k8s/argocd/apps/`
  - Infrastructure Configs: `k8s/argocd/infra/`

### OpenTofu (`tofu/` Directory)

- **Cluster Configuration**: `tofu/kubernetes/`
- **Stateful Applications**: `tofu/apps/`
- **Home Assistant & IoT**: `tofu/home-assistant/`

---

## Development Workflow

- **Commit Standards**: Follow [Conventional Commits](https://www.conventionalcommits.org/)
  _(feat | fix | docs | style | refactor | perf | test | build | ci | chore | revert)_
- **CI/CD Automation**: Use **GitHub Actions** to enforce commit standardization.
- **Performance-First**: Prioritize optimization with minimal overhead.

---

## Best Practices & Documentation Sync Requirement

Whenever **code changes**, Copilot **must**:

1. **Ensure documentation remains correct and up to date**—it should **never** drift from the actual implementation.
2. **Verify and update all relevant documentation** (including README files, comments, and any architectural overviews) to reflect the latest codebase state.
3. **Explicitly check for outdated information**—if any discrepancies are found, documentation **must** be revised accordingly.
4. **Maintain GitOps principles**—all changes must be **declarative, version-controlled, and reproducible**.
5. **Evaluate the impact on the entire infrastructure** before recommending modifications.
6. **Follow Kubernetes best practices** for manifests and resource allocation.
7. **Consider monitoring & security implications** for all infrastructure changes.
8. **Update this file whenever new relevant project information is gathered** that is not yet documented here.

🚨 **Failure to update documentation means the change is incomplete.**
🚨 **Every change must result in a consistent, fully documented state.**

---

## Repository Structure Conventions

### Kubernetes Applications

- **Group by functionality** (e.g., auth, controllers, monitoring).
- **Use Kustomization** for environment overlays.
- **Follow ArgoCD ApplicationSet patterns** for deployments.

### Infrastructure as Code (OpenTofu)

- **Separate Stateful & Stateless Components**.
- **Follow OpenTofu Best Practices**.

---

### **File Maintenance Requirement**

This document itself must always be updated when:

- New relevant information about the project is gathered.
- Infrastructure design, tools, or best practices evolve.
- Any part of the instructions here becomes outdated or incomplete.

🚨 **If this document is outdated, it must be corrected immediately to maintain an accurate reference for Copilot.**
