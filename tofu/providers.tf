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
      version = "0.8.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox[keys(var.proxmox)[0]].endpoint
  insecure = var.proxmox[keys(var.proxmox)[0]].insecure

  api_token = var.proxmox[keys(var.proxmox)[0]].api_token
  ssh {
    agent    = true
    username = var.proxmox[keys(var.proxmox)[0]].username
  }
}


provider "kubernetes" {
  host                   = module.talos.kube_config.kubernetes_client_configuration.host
  client_certificate     = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.ca_certificate)
}
