output "machine_config" {
  value = {
    for k, v in data.talos_machine_configuration.this :
    k => { machine_configuration = v.machine_configuration }
  }
}

output "client_configuration" {
  value     = var.manage_cluster ? data.talos_client_configuration.this[0] : null
  sensitive = true
}

output "kube_config" {
  value     = var.manage_cluster ? talos_cluster_kubeconfig.this[0] : null
  sensitive = true
}
