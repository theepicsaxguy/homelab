module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  image = {
    version = "v1.9.4"
    update_version = "v1.9.4" # renovate: github-releases=siderolabs/talos
    schematic = file("${path.module}/talos/image/schematic.yaml")
  }

  cilium = {
    values = file("${path.module}/../../k8s/infra/network/cilium/values.yaml")
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
  }

  cluster = {
    name            = "talos"
    endpoint        = "10.25.150.11"
    gateway         = "10.25.150.1"
    talos_version   = "v1.9.4"
    proxmox_cluster = "kube"
  }

  nodes = {
    "ctrl-00" = {
      host_node     = "host3"
      machine_type  = "controlplane"
      ip            = "10.25.150.11"
      mac_address   = "bc:24:11:e6:ba:07"
      vm_id         = 8101
      cpu           = 8
      ram_dedicated = 2672
      igpu          = false
    }
    "ctrl-01" = {
      host_node     = "host3"
      machine_type  = "controlplane"
      ip            = "10.25.150.12"
      mac_address   = "bc:24:11:44:94:5c"
      vm_id         = 8102
      cpu           = 4
      ram_dedicated = 2480
      igpu          = false
      #update        = true
    }
    "ctrl-02" = {
      host_node     = "host3"
      machine_type  = "controlplane"
      ip            = "10.25.150.13"
      mac_address   = "bc:24:11:1e:1d:2f"
      vm_id         = 8103
      cpu           = 4
      ram_dedicated = 2480
      #update        = true
    }
        "work-00" = {
          host_node     = "host3"
          machine_type  = "worker"
          ip            = "10.25.150.21"
          mac_address   = "bc:24:11:64:5b:cb"
          vm_id         = 8201
          cpu           = 4
          ram_dedicated = 2480
        }
  }

}

module "sealed_secrets" {
  depends_on = [module.talos]
  source = "./bootstrap/sealed-secrets"

  providers = {
    kubernetes = kubernetes
  }

  // openssl req -x509 -days 365 -nodes -newkey rsa:4096 -keyout sealed-secrets.key -out sealed-secrets.cert -subj "/CN=sealed-secret/O=sealed-secret"
  cert = {
    cert = file("${path.module}/bootstrap/sealed-secrets/certificate/sealed-secrets.cert")
    key = file("${path.module}/bootstrap/sealed-secrets/certificate/sealed-secrets.key")
  }
}

module "proxmox_csi_plugin" {
  depends_on = [module.talos]
  source = "./bootstrap/proxmox-csi-plugin"

  providers = {
    proxmox    = proxmox
    kubernetes = kubernetes
  }

  proxmox = var.proxmox
}

module "volumes" {
  depends_on = [module.proxmox_csi_plugin]
  source = "./bootstrap/volumes"

  providers = {
    restapi    = restapi
    kubernetes = kubernetes
  }
  proxmox_api = var.proxmox
  volumes = {
    pv-sonarr = {
      node = "host3"
      size = "4G"
    }
    pv-radarr = {
      node = "host3"
      size = "4G"
    }
    pv-lidarr = {
      node = "host3"
      size = "4G"
    }
    pv-prowlarr = {
      node = "host3"
      size = "1G"
    }
    pv-torrent = {
      node = "host3"
      size = "1G"
    }
    pv-remark42 = {
      node = "host3"
      size = "1G"
    }
    pv-authelia-postgres = {
      node = "host3"
      size = "2G"
    }
    pv-lldap-postgres = {
      node = "host3"
      size = "2G"
    }
    pv-keycloak-postgres = {
      node = "host3"
      size = "2G"
    }
    pv-jellyfin = {
      node = "host3"
      size = "12G"
    }
    pv-netbird-signal = {
      node = "host3"
      size = "512M"
    }
    pv-netbird-management = {
      node = "host3"
      size = "512M"
    }
    pv-plex = {
      node = "host3"
      size = "12G"
    }
    pv-prometheus = {
      node = "host3"
      size = "10G"
    }
  }
}
