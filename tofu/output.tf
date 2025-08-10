resource "local_file" "machine_configs" {
  for_each = merge(
    module.talos_owner.machine_config,
    length(module.talos_nuc) > 0 ? module.talos_nuc[0].machine_config : {}
  )
  content         = each.value.machine_configuration
  filename        = "output/talos-machine-config-${each.key}.yaml"
  file_permission = "0600"
}

resource "local_file" "talos_config" {
  count           = module.talos_owner.client_configuration != null ? 1 : 0
  content         = module.talos_owner.client_configuration.talos_config
  filename        = "output/talos-config.yaml"
  file_permission = "0600"
}

resource "local_file" "kube_config" {
  count           = module.talos_owner.kube_config != null ? 1 : 0
  content         = module.talos_owner.kube_config.kubeconfig_raw
  filename        = "output/kube-config.yaml"
  file_permission = "0600"
}

output "kube_config" {
  value     = module.talos_owner.kube_config != null ? module.talos_owner.kube_config.kubeconfig_raw : null
  sensitive = true
}

output "talos_config" {
  value     = module.talos_owner.client_configuration != null ? module.talos_owner.client_configuration.talos_config : null
  sensitive = true
}
