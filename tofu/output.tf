output "kube_config" {
  value     = module.talos.kube_config.kubeconfig_raw
  sensitive = true
}

output "talos_config" {
  value     = module.talos.client_configuration.talos_config
  sensitive = true
}
