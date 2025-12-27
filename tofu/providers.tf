terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0.0" # This ensures you get the latest 2.37.x version
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.90.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.10.0"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = ">= 2.0.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox.endpoint
  insecure = var.proxmox.insecure

  api_token = var.proxmox.api_token
  ssh {
    agent    = true
    username = var.proxmox.username
  }
}


provider "kubernetes" {
  host                   = "https://${var.external_api_endpoint}:6443"
  client_certificate     = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.ca_certificate)
}

provider "restapi" {
  uri                  = var.proxmox.endpoint
  insecure             = var.proxmox.insecure
  write_returns_object = true

  headers = {
    "Authorization" = var.proxmox.api_token
    "Content-Type"  = "application/x-www-form-urlencoded"
  }
}
