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
  talos      = "v1.12.5"
  kubernetes = "1.35.2"
}

talos_image = {
  schematic_path = "talos/image/schematic.yaml.tftpl"
  update_version = "v1.13.2" # renovate: github-releases=siderolabs/talos
}

kubernetes_image = {
  update_version = "1.36.1" # renovate: github-releases=kubernetes/kubernetes versioning=loose
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

enable_ble_proxy = true

ble_proxy_nodes = {
  ble-proxy-00 = {
    host_node   = "host3"
    ip          = "10.25.150.40"
    mac_address = "bc:24:11:aa:aa:10"
    vm_id       = 110
    usb_host    = "0a12:0001" # TP-Link UB400 (CSR8510 A10)
  }
}

# Dedicated LoadBalancer Service (matter-server-ble), not the internal Gateway's
# TCPRoute: Cilium 1.19.4 still drops pure-TCP Gateway listeners from the
# Gateway's backing Service (see k8s/applications/automation/matter-server/svc.yaml).
matter_server_ble_url = "ws://10.25.150.229:5580/ble"
