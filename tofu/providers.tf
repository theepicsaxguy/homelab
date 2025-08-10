terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.2"
    }
  }
}

# Explicit provider configurations per cluster alias (no default provider).
provider "proxmox" {


  alias     = "host3"
  endpoint  = var.proxmox["host3"].endpoint
  insecure  = var.proxmox["host3"].insecure
  api_token = var.proxmox["host3"].api_token
  ssh {
    agent    = true
    username = var.proxmox["host3"].username
  }
}

provider "proxmox" {
  alias     = "nuc"
  endpoint  = var.proxmox["nuc"].endpoint
  insecure  = var.proxmox["nuc"].insecure
  api_token = var.proxmox["nuc"].api_token
  ssh {
    agent    = true
    username = var.proxmox["nuc"].username
  }
}

# Using kubeconfig from the owner module (guarded for plan-time nulls).
provider "kubernetes" {
  host                   = module.talos_owner.kube_config != null ? module.talos_owner.kube_config.kubernetes_client_configuration.host : null
  client_certificate     = module.talos_owner.kube_config != null ? base64decode(module.talos_owner.kube_config.kubernetes_client_configuration.client_certificate) : null
  client_key             = module.talos_owner.kube_config != null ? base64decode(module.talos_owner.kube_config.kubernetes_client_configuration.client_key) : null
  cluster_ca_certificate = module.talos_owner.kube_config != null ? base64decode(module.talos_owner.kube_config.kubernetes_client_configuration.ca_certificate) : null
}
