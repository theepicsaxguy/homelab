resource "talos_machine_bootstrap" "this" {
  count = var.manage_cluster ? 1 : 0

  depends_on = [
    talos_machine_configuration_apply.this
  ]

  # Bootstrap with the first controlplane node's IP
  node                 = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]
  client_configuration = talos_machine_secrets.this[0].client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  count = var.manage_cluster ? 1 : 0

  depends_on = [
    talos_machine_bootstrap.this
  ]

  node                 = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]
  endpoint             = var.cluster.endpoint
  client_configuration = talos_machine_secrets.this[0].client_configuration

  timeouts = { read = "1m" }
}

data "talos_cluster_health" "this" {
  count = var.manage_cluster ? 1 : 0

  depends_on = [
    talos_cluster_kubeconfig.this,
    talos_machine_configuration_apply.this
  ]

  client_configuration = data.talos_client_configuration.this[0].client_configuration
  control_plane_nodes  = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
  worker_nodes         = [for k, v in var.nodes : v.ip if v.machine_type == "worker"]
  endpoints            = data.talos_client_configuration.this[0].endpoints

  timeouts = { read = "3m" }
}
