# Kubechecks Integration

## Overview

Kubechecks is integrated into our GitOps workflow to validate Kubernetes manifests before they're applied by ArgoCD.
This ensures that our manifests follow best practices and won't cause issues when deployed.

## Architecture

Kubechecks is deployed in the `kubechecks` namespace and works alongside ArgoCD to validate manifests. Due to
initialization ordering requirements, Kubechecks is bootstrapped manually before being handed over to ArgoCD for GitOps
management.

## Bootstrap Process

Since ArgoCD has some issues when first initializing Kubechecks, we use a bootstrap script to install it initially:

1. Run the bootstrap script with a GitHub token:

   ```bash
   export GITHUB_TOKEN=your_github_token
   ./scripts/bootstrap-kubechecks.sh
   ```

2. After bootstrapping, ArgoCD takes over management of the Kubechecks installation.

## Configuration

Kubechecks is configured to:

- Monitor all ArgoCD applications automatically
- Use GitHub as the VCS provider
- Run with local Kubernetes access
- Connect to ArgoCD services within the cluster

## Secret Management

The GitHub token required by Kubechecks is stored as a Kubernetes Secret named `kubechecks-vcs-token` in the
`kubechecks` namespace. In production, this should be managed using a proper secret management solution like Sealed
Secrets or External Secrets.

## GitOps Management

After the initial bootstrap, Kubechecks is managed entirely through GitOps via the ArgoCD application defined in
`/k8s/infra/base/kubechecks/application.yaml`.
