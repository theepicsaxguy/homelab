cluster_name          = "talos"
cluster_domain        = "cluster.local"
external_api_endpoint = "api.kube.peekoff.com"

network = {
  gateway     = "10.25.150.1"
  vip         = "10.25.150.10"
  api_lb_vip  = "10.25.150.9"
  cidr_prefix = 24
  dns_servers = ["10.25.150.1"]
  bridge      = "vmbr0"
  vlan_id     = 150
}

proxmox_cluster = "host3"

versions = {
  talos      = "v1.12.4" # renovate: github-releases=siderolabs/talos
  kubernetes = "1.35.2"  # renovate: github-releases=kubernetes/kubernetes versioning=loose
  #talos      = "v1.11.5"
  #kubernetes = "1.34.3"
}

oidc = {
  issuer_url = "https://sso.peekoff.com/application/o/kubectl/"
  client_id  = "kubectl"
}

lb_nodes = {
  lb-00 = {
    host_node     = "host3"
    ip            = "10.25.150.5"
    mac_address   = "bc:24:11:aa:aa:05"
    startup_order = 1
    vm_id         = 8005
  }
  lb-01 = {
    host_node     = "host3"
    ip            = "10.25.150.6"
    mac_address   = "bc:24:11:aa:aa:06"
    startup_order = 2
    vm_id         = 8006
  }
}
