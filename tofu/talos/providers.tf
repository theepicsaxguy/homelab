terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
    talos = {
      source = "siderolabs/talos"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
}
