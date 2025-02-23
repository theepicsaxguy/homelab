terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
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

# Deploy ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  create_namespace = true
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.8.4"
  values     = [file("${path.module}/infra/controllers/argocd/values.yaml")]
  
  set {
    name  = "commonAnnotations.argocd\\.argoproj\\.io/sync-wave"
    value = "-1"
  }
}

# Wait for ArgoCD to be ready
resource "null_resource" "wait_for_argocd" {
  depends_on = [helm_release.argocd]
  provisioner "local-exec" {
    command = "kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=120s"
  }
}

# Apply the root ApplicationSet that will manage everything else
resource "kubectl_manifest" "root_applicationset" {
  depends_on = [null_resource.wait_for_argocd]
  yaml_body = file("${path.module}/sets/root-applicationset.yaml")
  wait      = true
}
