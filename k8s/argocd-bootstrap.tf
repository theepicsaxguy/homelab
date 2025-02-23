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

variable "kubeconfig_path" {
  description = "Path to your kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

# Helm release for ArgoCD
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.8.4"
  set {
    name  = "commonAnnotations.argocd.argoproj.io/sync-wave"
    value = "-1"
  }
}

# Apply the App-of-Apps manifests
data "kustomization_build" "app_of_apps" {
  path = "${path.module}/sets"
}

resource "kubectl_manifest" "app_of_apps" {
  depends_on = [helm_release.argocd]
  yaml_body  = join("\n", values(data.kustomization_build.app_of_apps.manifests))
  wait       = true
}
