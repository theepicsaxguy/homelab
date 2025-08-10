data "talos_client_configuration" "this" {
  count = var.manage_cluster ? 1 : 0

  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this[0].client_configuration
  nodes                = [for k, v in var.nodes : v.ip]
  endpoints            = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
}
