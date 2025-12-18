# Bootstrap Proxmox CSI Plugin
# This module sets up the Proxmox CSI plugin for dynamic storage provisioning
# It creates:
# - A Proxmox user and role with necessary permissions
# - An API token for the CSI plugin
# - A Kubernetes namespace and secret for the CSI plugin configuration
module "proxmox-csi-plugin" {
  source = "./bootstrap/proxmox-csi-plugin"

  providers = {
    kubernetes = kubernetes
    proxmox    = proxmox
  }

  proxmox = {
    cluster_name = var.proxmox_cluster
    endpoint     = var.proxmox.endpoint
    insecure     = var.proxmox.insecure
  }

  depends_on = [module.talos]
}

# Bootstrap Volumes (Optional)
# This module is ONLY needed if you want to pre-provision static Kubernetes persistent volumes
# For most use cases, you should rely on dynamic provisioning via StorageClass instead
# Use this only for:
# - Migrating existing volumes into Kubernetes
# - Specific manual control over volume placement
# - Legacy applications requiring static volumes
module "volumes" {
  count  = length(var.bootstrap_volumes) > 0 ? 1 : 0
  source = "./bootstrap/volumes"

  providers = {
    kubernetes = kubernetes
    restapi    = restapi
  }

  proxmox_api = {
    endpoint     = var.proxmox.endpoint
    insecure     = var.proxmox.insecure
    cluster_name = var.proxmox_cluster
  }

  volumes = var.bootstrap_volumes

  depends_on = [module.proxmox-csi-plugin]
}
