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

# Apply Gateway API CRDs
resource "kubectl_manifest" "gateway_api_crds" {
  yaml_body = file("${path.module}/infra/crds/kustomization.yaml")
  wait      = true
}

# Deploy Cilium with Helm and Kustomize
resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = "kube-system"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = "1.17.1"
  values     = [file("${path.module}/infra/network/cilium/values.yaml")]
}


# Deploy Proxmox CSI Plugin
data "kustomization_build" "proxmox_csi" {
  path = "${path.module}/infra/storage/proxmox-csi"
  kustomize_options {
    enable_helm = true
  }
}

resource "kubectl_manifest" "proxmox_csi" {
  yaml_body = join("\n", values(data.kustomization_build.proxmox_csi.manifests))
  wait      = true
}

# Helm release for ArgoCD
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.8.2"
  values     = [file("${path.module}/infra/controllers/argocd/values.yaml")]
  set {
    name  = "commonAnnotations.argocd.argoproj.io/sync-wave"
    value = "-1"
  }
}

# Apply the infra directory
data "kustomization_build" "infra" {
  path = "${path.module}/infra"
}

resource "kubectl_manifest" "infra" {
  yaml_body = join("\n", values(data.kustomization_build.infra.manifests))
  wait      = true
}

# Apply the App-of-Apps manifests
data "kustomization_build" "app_of_apps" {
  path = "${path.module}/sets"
}

resource "kubectl_manifest" "app_of_apps" {
  depends_on = [helm_release.argocd, kubectl_manifest.infra]
  yaml_body  = join("\n", values(data.kustomization_build.app_of_apps.manifests))
  wait       = true
}

# Display Proxmox CSI Storage Capacities
resource "null_resource" "proxmox_csi_check" {
  provisioner "local-exec" {
    command = "kubectl get csistoragecapacities -ocustom-columns=CLASS:.storageClassName,AVAIL:.capacity,ZONE:.nodeTopology.matchLabels -A"
  }
}
