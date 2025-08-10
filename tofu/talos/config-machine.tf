locals {
  # Default Cilium/CoreDNS if not provided by root (keeps root DRY)
  cilium_values_default  = file("${path.root}/../k8s/infrastructure/network/cilium/values.yaml")
  cilium_install_default = file("${path.module}/inline-manifests/cilium-install.yaml")
  coredns_install_default = templatefile("${path.module}/inline-manifests/coredns-install.yaml.tftpl", {
    cluster_domain = var.cluster_domain
    dns_forwarders = join(" ", var.network.dns_servers)
  })

  cilium_values   = coalesce(try(var.cilium.values, null), local.cilium_values_default)
  cilium_install  = coalesce(try(var.cilium.install, null), local.cilium_install_default)
  coredns_install = coalesce(try(var.coredns.install, null), local.coredns_install_default)
}

data "talos_machine_configuration" "this" {
  for_each           = var.nodes

  cluster_name       = var.cluster.name
  cluster_endpoint   = "https://${var.cluster.endpoint}:6443"
  talos_version      = var.cluster.talos_version
  machine_type       = each.value.machine_type
  machine_secrets    = var.manage_cluster ? talos_machine_secrets.this[0].machine_secrets : null
  kubernetes_version = var.cluster.kubernetes_version

  config_patches = (
    each.value.machine_type == "controlplane" ?
    [
      templatefile("${path.module}/machine-config/control-plane.yaml.tftpl", {
        hostname        = each.key
        node_name       = each.value.host_node
        cluster_name    = var.cluster.proxmox_cluster
        node_ip         = each.value.ip
        cluster         = var.cluster
        cluster_domain  = var.cluster_domain
        cilium_values   = local.cilium_values
        cilium_install  = local.cilium_install
        coredns_install = local.coredns_install
        oidc            = var.oidc
        vip             = var.network.vip
      })
    ] :
    concat(
      [
        templatefile("${path.module}/machine-config/worker.yaml.tftpl", {
          hostname           = each.key
          node_name          = each.value.host_node
          cluster_name       = var.cluster.proxmox_cluster
          node_ip            = each.value.ip
          cluster            = var.cluster
          cluster_domain     = var.cluster_domain
          disks              = coalesce(each.value.disks, {})
          igpu               = lookup(each.value, "igpu", false)
          gpu_node_exclusive = lookup(each.value, "gpu_node_exclusive", false)
          vip                = var.network.vip
        })
      ],
      lookup(each.value, "igpu", false) ? [
        file("${path.module}/patches/gpu-modules.yaml"),
        file("${path.module}/patches/gpu-runtime.yaml")
      ] : []
    )
  )
}

resource "talos_machine_configuration_apply" "this" {
  depends_on = [terraform_data.image_version]

  for_each                    = var.nodes
  node                        = each.value.ip
  client_configuration        = var.manage_cluster ? talos_machine_secrets.this[0].client_configuration : null
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration

  lifecycle {
    # Avoid churn when template files touch unrelated whitespace
    ignore_changes = [machine_configuration_input]
  }
}
