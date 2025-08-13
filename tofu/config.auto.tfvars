cluster_name   = "talos"
cluster_domain = "kube.pc-tips.se"

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
  talos      = "v1.10.3"
  kubernetes = "1.33.2"
}

oidc = {
  issuer_url = "https://sso.pc-tips.se/application/o/kubectl/"
  client_id  = "kubectl"
}

lb_nodes = {
  lb-00 = {
    host_node   = "host3"
    ip          = "10.25.150.5"
    mac_address = "bc:24:11:aa:aa:05"
    vm_id       = 8005
  }
  lb-01 = {
    host_node   = "host3"
    ip          = "10.25.150.6"
    mac_address = "bc:24:11:aa:aa:06"
    vm_id       = 8006
  }
}
