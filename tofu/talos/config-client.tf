data "talos_client_configuration" "this" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for k, v in var.nodes : v.ip]
  endpoints            = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
}
