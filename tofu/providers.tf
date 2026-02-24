terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0.0" # This ensures you get the latest 2.37.x version
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.15.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.97.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.10.1"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = ">= 2.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12.0"
    }
  }

  # State and plan encryption using pbkdf2 + AES-GCM
  # Encryption passphrase must be set in terraform.tfvars
  encryption {
    key_provider "pbkdf2" "encryption_passphrase" {
      passphrase = var.encryption_passphrase
    }
    method "aes_gcm" "encryption_method" {
      keys = key_provider.pbkdf2.encryption_passphrase
    }
    state {
      method   = method.aes_gcm.encryption_method
      enforced = true
    }
    plan {
      method   = method.aes_gcm.encryption_method
      enforced = true
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
  host                   = "https://${coalesce(var.external_api_endpoint, "api.${var.cluster_domain}")}:6443"
  client_certificate     = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = "https://${coalesce(var.external_api_endpoint, "api.${var.cluster_domain}")}:6443"
    client_certificate     = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.ca_certificate)
  }
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
