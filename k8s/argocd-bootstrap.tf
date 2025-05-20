terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    kustomization = {
      source  = "kbst/kustomization"
      version = ">= 0.9.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.5.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36.0"
    }
  }
}

provider "kubectl" {
  config_path = pathexpand(var.kubeconfig_path)
}

provider "kustomization" {
  kubeconfig_path = pathexpand(var.kubeconfig_path)
}

provider "helm" {
  kubernetes {
    config_path = pathexpand(var.kubeconfig_path)
  }
}

provider "kubernetes" {
  config_path = pathexpand(var.kubeconfig_path)
}

variable "kubeconfig_path" {
  description = "Path to your kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

# Check if ArgoCD namespace exists
data "kubernetes_namespace" "argocd" {
  count = 1
  metadata {
    name = "argocd"
  }
}

# Helm release for ArgoCD - Only installs if not present
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.0.6"

  create_namespace = true
  cleanup_on_fail  = true

  # Skip installation if ArgoCD already exists
  count = can(data.kubernetes_namespace.argocd[0]) ? 0 : 1

  set {
    name  = "commonAnnotations.argocd.argoproj.io/sync-wave"
    value = "-1"
  }
}

# Apply the App-of-Apps manifests only if ArgoCD is running
data "kustomization_build" "app_of_apps" {
  path = "${path.module}/sets"
}

resource "kubectl_manifest" "app_of_apps" {
  depends_on = [data.kubernetes_namespace.argocd]
  yaml_body  = join("\n", values(data.kustomization_build.app_of_apps.manifests))
  wait       = true
}
