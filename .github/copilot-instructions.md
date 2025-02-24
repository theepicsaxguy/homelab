# GitHub Copilot Context & Instructions

This repository manages a GitOps-only homelab infrastructure with

- Kubernetes (Talos)
- OpenTofu (Terraform)
- ArgoCD-based deployments
- Monitoring and security components

## Core Principles

### GitOps-Only: No Manual Changes

- All infrastructure changes must be defined in Git and applied automatically.
- ArgoCD is responsible for all deployments.
  - kubectl is only allowed for troubleshooting.
  - Manual `kubectl apply` or `helm install` is strictly prohibited.
- All changes must maintain a reproducible, fully documented state.

## Repository Structure and Rules

### Kubernetes (k8s)

#### ArgoCD (k8s/argocd/)

- The only entry point for deployments
- Uses ApplicationSets for dynamic app management
- All apps must be defined here

#### Applications (k8s/apps/)

- Functional workloads such as authentication and monitoring
- Must use Kustomization overlays
- No raw manifests

#### Infrastructure Components (k8s/infra/)

- Covers networking, DNS, storage, and other foundational services
- Networking must use Cilium instead of Talos' default setup
- Ingress must be managed via ArgoCD using predefined templates

#### Monitoring and Security (k8s/monitoring/)

- Covers observability components such as Prometheus, Loki, and Falco
- Must prioritize self-healing and alerting

### OpenTofu (tofu)

#### Clusters (tofu/kubernetes/)

- Manages Talos cluster definitions
- Control planes must remain immutable and be rebuilt via GitOps if necessary

#### Stateful Apps (tofu/apps/)

- Covers workloads requiring persistent storage
- All persistent storage must be declared here

#### IoT and Home Assistant (tofu/home-assistant/)

- Covers home automation and IoT-related deployments
- Uses Terraform only for provisioning external dependencies

### Documentation (docs)

#### Architecture (docs/architecture/)

- Covers high-level infrastructure design

#### Best Practices (docs/best-practices/)

- Defines guidelines for GitOps, ArgoCD, Kubernetes, and Terraform usage

## Development Workflow

### READMEs (README.md)

- Must always reflect the current state of the repository

### CI/CD and Automation

- GitHub Actions enforce commit standardization
- ArgoCD ensures state reconciliation and prevents configuration drift

### Best Practices and Documentation Sync

Every code change must

1. Verify and update documentation to prevent drift
2. Maintain GitOps principles with no manual interventions
3. Follow Kubernetes best practices for manifests and resource allocation
4. Ensure ArgoCD ApplicationSets are structured correctly
5. Assess security and monitoring implications before recommending changes

## Conventions and Best Practices

- Kubernetes applications must be grouped by functionality
- Kustomization overlays must be used for all applications
- ArgoCD ApplicationSet patterns must be followed, no direct ArgoCD app definitions
- Terraform must follow OpenTofu best practices with modular, declarative configurations

## Enforcement Rules

- kubectl usage is strictly for troubleshooting. Getting logs, states or bootstraping is okay. But state should always
  match git.
  - If a change is required, it must go through Git
- Manual edits to cluster resources are not permitted
  - Exceptions apply only in emergency recovery scenarios and must be reverted via Git
- ArgoCD is the single source of truth
- All implementations must be correct before merging
