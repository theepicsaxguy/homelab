terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.81.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.8.1"
    }
  }
}

# Default provider (must exist to decode prior state)
provider "proxmox" {
  endpoint  = var.proxmox.endpoint
  insecure  = var.proxmox.insecure
  api_token = var.proxmox.api_token

  ssh {
    agent    = true
    username = var.proxmox.username
  }
}

# Kubernetes provider wired to original module outputs (no contract change)
provider "kubernetes" {
  host                   = module.talos.kube_config.kubernetes_client_configuration.host
  client_certificate     = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.ca_certificate)
}

provider "proxmox" {
  alias     = "extra"
  endpoint  = var.proxmox_extra != null ? var.proxmox_extra.endpoint : var.proxmox.endpoint
  insecure  = var.proxmox_extra != null ? var.proxmox_extra.insecure : var.proxmox.insecure
  api_token = var.proxmox_extra != null ? var.proxmox_extra.api_token : var.proxmox.api_token

  ssh {
    agent    = true
    username = var.proxmox_extra != null ? var.proxmox_extra.username : var.proxmox.username
  }
}
