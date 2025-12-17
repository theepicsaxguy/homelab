data "talos_machine_configuration" "this" {
  for_each           = var.nodes
  cluster_name       = var.cluster.name
  cluster_endpoint   = "https://${var.cluster.endpoint}:6443"
  talos_version      = var.cluster.talos_version
  machine_type       = each.value.machine_type
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  kubernetes_version = var.cluster.kubernetes_version

  config_patches = each.value.machine_type == "controlplane" ? [
    templatefile("${path.module}/machine-config/control-plane.yaml.tftpl", {
      hostname        = each.key
      node_name       = each.value.host_node
      cluster_name    = var.cluster.proxmox_cluster
      node_ip         = each.value.ip
      cluster         = var.cluster
      cluster_domain  = var.cluster_domain
      cilium_values   = var.cilium.values
      cilium_install  = var.cilium.install
      coredns_install = var.coredns.install
      oidc            = var.oidc
      vip             = var.network.vip
      disks           = each.value.disks
    })
    ] : concat(
    [
      templatefile("${path.module}/machine-config/worker.yaml.tftpl", {
        hostname           = each.key
        node_name          = each.value.host_node
        cluster_name       = var.cluster.proxmox_cluster
        node_ip            = each.value.ip
        cluster            = var.cluster
        cluster_domain     = var.cluster_domain
        disks              = each.value.disks
        igpu               = each.value.igpu
        gpu_node_exclusive = lookup(each.value, "gpu_node_exclusive", false)
        vip                = var.network.vip
      })
    ],
    # This conditionally adds the GPU patches
    lookup(each.value, "igpu", false) ? [
      file("${path.module}/patches/gpu-modules.yaml"),
      file("${path.module}/patches/gpu-runtime.yaml")
    ] : []
  )
}

resource "talos_machine_configuration_apply" "this" {
  depends_on = [
    talos_image_factory_schematic.main,
  ]
  for_each                    = var.nodes
  node                        = each.value.ip
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration

  lifecycle {
    # Depend on THIS specific VM - triggers reapply when VM is replaced
    replace_triggered_by = [
      proxmox_virtual_environment_vm.this[each.key]
    ]
  }
}
