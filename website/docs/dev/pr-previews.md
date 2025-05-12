---
title: PR Preview Environments
---

# Pull Request Preview Environments

This document outlines how Pull Request (PR) Preview Environments are set up and utilized in this homelab repository. These environments allow for isolated testing of changes introduced in a PR before merging to the `main` branch.

## Overview

PR Preview Environments are dynamically created Kubernetes namespaces that deploy a version of the applications affected by the changes in a pull request. This provides a live, testable instance of the proposed changes.

## Configuration

The core configuration for PR Preview Environments can be found in the `/k8s/pr-preview/` directory. Key components typically include:

-   **ApplicationSet or similar ArgoCD configurations:** To automatically detect PRs and deploy resources into a unique namespace for that PR.
-   **Kustomize overlays:** To tailor application manifests for the preview environment (e.g., using different hostnames, disabling certain production-only features).
-   **Namespace generator/manager:** Logic to create and tear down namespaces associated with PRs.
-   **Ingress/Gateway configuration:** To expose services running in the preview namespace, often using a PR-specific subdomain.

## Workflow

1.  A developer creates a Pull Request with changes to application manifests or configurations.
2.  CI/CD automation (e.g., GitHub Actions) triggers the creation of a PR Preview Environment.
    -   A new namespace is created (e.g., `pr-<pr-number>`).
    -   ArgoCD (or a similar tool) deploys the modified application(s) into this namespace, using configurations from `/k8s/pr-preview/`.
3.  The preview environment is accessible via a unique URL (e.g., `app-pr-<pr-number>.your.domain.tld`).
4.  Reviewers and the developer can test the changes live in this isolated environment.
5.  Once the PR is merged or closed:
    -   The associated preview namespace and all its resources are automatically deleted.

## Key Considerations

-   **Resource Management:** Ensure that preview environments do not consume excessive cluster resources. Implement quotas and cleanup mechanisms.
-   **Secrets Management:** Determine how secrets will be handled for preview environments. They might use non-sensitive dummy data or a dedicated, isolated secrets store.
-   **Data Isolation:** Preview environments should use their own isolated data stores or mock data to avoid impacting production or other environments.
-   **DNS and Ingress:** A wildcard DNS entry and a flexible Ingress/Gateway setup are usually required to dynamically route traffic to preview services.

Refer to the manifests and scripts within `/k8s/pr-preview/` for the specific implementation details in this repository.
