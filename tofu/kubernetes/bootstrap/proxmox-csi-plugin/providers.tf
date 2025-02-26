terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">=2.35.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.66.1"
    }
  }
}
