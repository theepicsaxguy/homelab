---
title: Bootstrap ArgoCD with Terraform
---

This document describes the `/k8s/argocd-bootstrap.tf` Terraform configuration. This configuration is used for the
initial installation of ArgoCD onto a Kubernetes cluster if ArgoCD is not already present. This process is typically a
one-time operation for a new cluster or if ArgoCD needs to be set up from scratch. Once ArgoCD is operational, it
assumes responsibility for managing itself and other applications through a GitOps workflow.

## About the ArgoCD bootstrap process

The primary purpose of this Terraform configuration is to:

1. Check for an existing `argocd` namespace within the Kubernetes cluster.
2. If the `argocd` namespace is absent, install ArgoCD using its official Helm chart.
3. Apply a set of ArgoCD `Application` manifests, following the "app-of-apps" pattern. These initial applications
   instruct ArgoCD to manage other collections of applications, including its own configuration, based on definitions in
   the Git repository.

### File Path

`/k8s/argocd-bootstrap.tf`

### Design rationale

- **Declarative Initial Setup:** Terraform is chosen for this initial bootstrap to define the ArgoCD installation in a
  declarative manner. While ArgoCD will manage its own configuration post-installation, an initial mechanism is required
  for its first deployment onto the cluster.
- **Helm for ArgoCD Installation:** The official ArgoCD Helm chart is the recommended method for installing ArgoCD. The
  `hashicorp/helm` Terraform provider facilitates the deployment of Helm charts. The chart version (`8.0.0`) is pinned
  to ensure a consistent and tested deployment.
- **Conditional Installation Logic:** The configuration utilizes a `kubernetes_namespace` data source to detect if the
  `argocd` namespace already exists. The `helm_release.argocd` resource then employs a `count` expression:
  `count = can(data.kubernetes_namespace.argocd[0]) ? 0 : 1`. :::info **Rationale for conditional installation:** This
  logic prevents Terraform from attempting to reinstall ArgoCD if it is already present from a previous run or manual
  setup. This makes the bootstrap script idempotent, meaning it can be run multiple times with the same outcome if the
  underlying state (ArgoCD not present) is the same. :::
- **App-of-Apps Deployment with Kustomize:**
  - The `data "kustomization_build" "app_of_apps"` and `resource "kubectl_manifest" "app_of_apps"` sections are
    responsible for applying the root ArgoCD ApplicationSet manifests. These manifests are sourced from the directory
    specified by `${path.module}/sets`. This path should point to the location where your root ArgoCD ApplicationSet
    definitions are stored (e.g., `/k8s/infrastructure/application-set.yaml` and
    `/k8s/applications/application-set.yaml`, if they are organized under a Kustomize setup in that `sets` directory).
    These ApplicationSets subsequently manage all other applications and infrastructure components.
  - The `kbst/kustomization` provider renders these Kustomize manifests, and the `gavinbunney/kubectl` provider applies
    them to the cluster. :::info **Rationale for App-of-Apps:** This pattern transfers control to ArgoCD itself to
    manage the remainder of the cluster's applications and infrastructure based on definitions stored in Git. This is a
    fundamental concept in the GitOps model. :::
- **Resource Dependencies (`depends_on`):** The `kubectl_manifest.app_of_apps` resource specifies
  `depends_on = [data.kubernetes_namespace.argocd]`. :::info **Rationale for dependency:** This ensures that the
  app-of-apps manifests are applied only after the `argocd` namespace is confirmed to exist, which serves as an
  indicator that the ArgoCD Helm chart installation has likely been initiated or completed. :::
- **Sync Wave Annotation for ArgoCD (`commonAnnotations.argocd.argoproj.io/sync-wave: "-1"`):**
  - This annotation is set for the ArgoCD Helm release within the `helm_release.argocd` resource. :::info **Rationale
    for sync wave:** Sync waves in ArgoCD control the order of resource synchronization. Assigning a negative sync wave
    (e.g., `-1`) to ArgoCD itself ensures that it is fully operational _before_ it attempts to synchronize other
    applications, which typically have sync waves of `0` or higher. This ordering is critical for the app-of-apps
    pattern to function correctly. :::

## How it works

1. **Provider Configuration:**

   - Terraform providers for `kubectl`, `kustomization`, `helm`, and `kubernetes` are configured.
   - All providers utilize the `kubeconfig_path` variable (defaulting to `~/.kube/config`) to establish a connection
     with the Kubernetes cluster.

2. **ArgoCD Namespace Check:**

   - The `data "kubernetes_namespace" "argocd"` block attempts to retrieve information about the `argocd` namespace. The
     result of this check determines if ArgoCD needs to be installed.

3. **ArgoCD Helm Release:**

   - The `resource "helm_release" "argocd"` block defines the parameters for the ArgoCD installation via Helm.
   - `name`, `namespace`, `repository`, `chart`, and `version` specify the details of the Helm chart to be deployed.
   - `create_namespace = true`: Instructs the Helm chart to create the `argocd` namespace if it does not already exist.
   - `cleanup_on_fail = true`: If the Helm release encounters an error during installation, Terraform will attempt to
     remove any partially deployed resources.
   - The `count` logic, based on the namespace check, ensures this resource is processed only if the `argocd` namespace
     was not found initially.
   - The `set` block is used to configure the `sync-wave` annotation for the ArgoCD deployment.

4. **App-of-Apps Manifests Deployment:**
   - `data "kustomization_build" "app_of_apps"`: This block renders the Kustomize manifests located at the path defined
     by `${path.module}/sets`. This path must point to the Kustomize setup for your root ArgoCD ApplicationSets.
   - `resource "kubectl_manifest" "app_of_apps"`: This block applies the rendered YAML to the cluster. The
     `join("\n", values(data.kustomization_build.app_of_apps.manifests))` pattern is a common way to combine multiple
     YAML documents produced by Kustomize into a single apply operation.
   - `wait = true`: Instructs Terraform to wait for these applied resources to report a ready state before proceeding.

## Prerequisites

Before running this Terraform configuration, ensure the following conditions are met:

- An operational Kubernetes cluster is accessible.
- A `kubeconfig` file is correctly configured, providing access to the cluster.
- Terraform (version compatible with provider requirements) is installed on the machine where the commands will be run.
- The directory specified in `data.kustomization_build.app_of_apps.path` (e.g., `./sets` relative to the Terraform file,
  or an alternative path) exists and contains the Kustomize setup for your root ArgoCD ApplicationSets.

## How to run the bootstrap

1. Navigate to the directory that contains the `argocd-bootstrap.tf` file.
2. Initialize Terraform to download necessary providers:

   ```bash
   terraform init
   ```

3. Apply the Terraform configuration to bootstrap ArgoCD:

   ```bash
   terraform apply
   ```

   You might be prompted for the `kubeconfig_path` if it deviates from the default `~/.kube/config` and is not set as an
   environment variable.

## Maintenance and troubleshooting

- **If ArgoCD is Already Installed:** If ArgoCD is already present on the cluster, this script should ideally make no
  changes due to the namespace existence check.
- **Upgrading ArgoCD Post-Bootstrap:** For upgrading ArgoCD itself after this initial bootstrap, the recommended
  practice is to allow ArgoCD to manage its own Helm chart via an `Application` resource (which should be part of your
  app-of-apps definition). This Terraform script is primarily intended for the _first-time_ setup.
- **Helm Installation Failures:** If the Helm installation fails, check the status of the Helm release and review pod
  logs in the `argocd` namespace for specific error messages.

  ```bash
  helm status argocd -n argocd
  kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
  # Check logs for other ArgoCD components like the application-controller as well.
  ```

- **Failures Applying `app_of_apps`:**
  - Verify that the Kustomization path specified in `data.kustomization_build.app_of_apps.path` is correct and that the
    manifests within that path are valid.
  - If ArgoCD is partially operational, check its logs (particularly the `argocd-application-controller` logs) for
    issues related to applying these initial applications.

This Terraform configuration provides a reliable method for deploying ArgoCD onto a Kubernetes cluster for the first
time, effectively bridging the gap from a cluster without ArgoCD to one where ArgoCD manages all further configurations
via GitOps.
