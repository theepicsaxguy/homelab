output "machine_config" {
  value = data.talos_machine_configuration.this
}

output "client_configuration" {
  value     = data.talos_client_configuration.this
  sensitive = true
}

output "kube_config" {
  #value     = data.talos_cluster_kubeconfig.this
  value =  talos_cluster_kubeconfig.this
  sensitive = true
}
resource "local_file" "talos_config_home" {
  content         = jsonencode(data.talos_client_configuration.this.client_configuration)
  filename        = "/root/.talos/config"
  file_permission = "0600"
}

resource "local_file" "kube_config_home" {
  content         = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename        = "/root/.kube/config"
  file_permission = "0600"
}
