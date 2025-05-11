---
title: Homelab Kubernetes configuration
---

This document provides an overview of the Kubernetes setup for this homelab environment, which is designed to run
various applications and services. It aims to explain the system's structure and the rationale behind key design
decisions, enabling an IT administrator to understand, operate, and maintain the system.

## About this system

This Kubernetes setup is built upon several guiding principles:

1. **GitOps as the Source of Truth:** The state of the cluster (applications, infrastructure components) is defined
   entirely within this Git repository. ArgoCD is employed to continuously reconcile the cluster state with these
   definitions. This ensures that all changes are made via Git commits, providing a comprehensive audit trail and a
   single, reliable source of truth.
2. **Declarative Configuration:** The system favors declarative tools such as Kubernetes YAML, Kustomize, and Terraform.
   The desired state of components is defined, and the tools are responsible for achieving that state.
3. **Automation:** A high degree of automation is implemented, covering processes from application deployment with
   ArgoCD ApplicationSets to certificate management with Cert-Manager.
4. **Security Considerations:** Although this is a homelab environment, security best practices are applied. These
   include running containers as non-root users, utilizing network policies for traffic control, and managing secrets
   externally to the Git repository.
5. **Modularity and Organization:** Configurations are structured using Kustomize and ArgoCD projects and
   ApplicationSets. This approach promotes organization and simplifies the process of adding new applications or
   components.

## Documentation structure

This `/docs` directory contains detailed documentation for various parts of the system:

- **[Provision the Talos Kubernetes cluster with Terraform](./tofu/README.md):** Explains how the underlying Kubernetes
  cluster, running Talos on Proxmox, is provisioned using Terraform.
- **[Manage Kubernetes configuration with GitOps](./k8s/README.md):** Describes the overall structure of Kubernetes
  manifests, with a focus on ArgoCD for implementing GitOps, and details how applications and infrastructure services
  are managed.
  - **[Bootstrap ArgoCD](./k8s/argocd-bootstrap.md):** Details the initial setup process for ArgoCD on the cluster.
  - **[Deploy and manage applications](./k8s/applications/README.md):** Explains the deployment and management
    strategies for user-facing applications.
  - **[Deploy and manage infrastructure services](./k8s/infrastructure/README.md):** Covers the deployment and
    management of core cluster services, including networking, storage, authentication, and monitoring.
  - **[Automate PR preview environments](./k8s/pr-preview/README.md):** Describes the system used to automatically
    create temporary environments for testing pull requests.
- **[Utilize utility and bootstrapping scripts](./scripts/README.md):** Provides documentation for various utility and
  bootstrapping scripts used within the system.
- **[Configure the GitHub repository](./github/README.md):** Contains information about CI/CD workflows and Dependabot
  settings for repository maintenance.

This documentation aims to be clear, concise, and actionable. For each component, it explains its function, operational
details, and the rationale behind its specific design or configuration choices.
