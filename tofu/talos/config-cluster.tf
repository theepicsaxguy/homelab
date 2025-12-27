resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.this
  ]
  # Bootstrap with the first node. VIP not yet available at this stage, so cant use var.cluster.endpoint as it may be set to VIP
  # ref - https://www.talos.dev/v1.9/talos-guides/network/vip/#caveats
  node                 = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "terraform_data" "kubeconfig_endpoint_trigger" {
  input = coalesce(var.external_api_endpoint, var.cluster.endpoint)
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this,
    talos_machine_configuration_apply.this
  ]
  node                 = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]
  endpoint             = coalesce(var.external_api_endpoint, var.cluster.endpoint)
  client_configuration = talos_machine_secrets.this.client_configuration
  timeouts = {
    read = "1m"
  }

  lifecycle {
    replace_triggered_by = [
      terraform_data.kubeconfig_endpoint_trigger
    ]
  }
}

data "talos_cluster_health" "this" {
  depends_on = [
    talos_cluster_kubeconfig.this,
    talos_machine_configuration_apply.this
  ]
  client_configuration = data.talos_client_configuration.this.client_configuration
  control_plane_nodes  = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
  worker_nodes         = [for k, v in var.nodes : v.ip if v.machine_type == "worker"]
  endpoints            = data.talos_client_configuration.this.endpoints
  timeouts = {
    read = "3m"
  }
}
