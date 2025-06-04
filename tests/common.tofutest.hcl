mock_provider "proxmox" { alias = "mock" }
mock_provider "talos" { alias = "mock" }
mock_provider "kubernetes" { alias = "mock" }
mock_provider "restapi" { alias = "mock" }
mock_provider "http" { alias = "mock" }

override_data {
  target = module.talos.data.http.schematic_id
  values = { response_body = "{\"id\":\"test\"}" }
}

override_data {
  target = module.talos.data.http.updated_schematic_id
  values = { response_body = "{\"id\":\"test\"}" }
}

override_module {
  target = module.talos
  outputs = {
    client_configuration = {
      talos_config = "dummy"
      client_configuration = {
        ca_certificate     = ""
        client_certificate = ""
        client_key         = ""
      }
      endpoints = []
    }
    kube_config = {
      kubeconfig_raw = "dummy"
      kubernetes_client_configuration = {
        host               = ""
        client_certificate = ""
        client_key         = ""
        ca_certificate     = ""
      }
    }
    machine_config = {}
  }
}

override_data {
  target = data.talos_cluster_health.upgrade
  values = {}
}

variables {
  proxmox = {
    name         = "mock"
    cluster_name = "mock"
    endpoint     = "https://mock"
    insecure     = true
    username     = "root@pam"
    api_token    = "token"
  }
  talos_image = {
    schematic_path = "talos/image/schematic.yaml.tftpl"
    version        = "v1.0.0"
  }
}
