// tofu/config.tfvars.example

cluster_name   = "talos"
cluster_domain = "kube.pc-tips.se"

# Network settings
# All nodes must be on the same L2 network
network = {
  gateway     = "10.25.150.1"
  vip         = "10.25.150.10" # Control plane Virtual IP
  cidr_prefix = 24
  dns_servers = ["10.25.150.1"]
  bridge      = "vmbr0"
  vlan_id     = 150
}

# Proxmox settings
proxmox_cluster = "host3"

# Software versions
versions = {
  talos      = "v1.10.3"
  kubernetes = "1.33.2"
}

# OIDC settings (optional)
oidc = {
  issuer_url = "https://sso.pc-tips.se/application/o/kubectl/"
  client_id  = "kubectl"
}
