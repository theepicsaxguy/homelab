resource "talos_machine_secrets" "this" {
  talos_version = var.cluster.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for k, v in var.nodes : v.ip]
  endpoints            = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
}

data "talos_machine_configuration" "this" {
  for_each = { for k, v in var.nodes : k => v if v.machine_type == "controlplane" }

  cluster_name       = var.cluster.name
  cluster_endpoint   = "https://${var.cluster.endpoint}:6443"
  talos_version      = var.cluster.talos_version
  machine_type       = each.value.machine_type
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  kubernetes_version = var.cluster.kubernetes_version
  config_patches = [
    templatefile("${path.module}/machine-config/control-plane.yaml.tftpl", {
      hostname        = each.key
      node_name       = each.value.host_node
      cluster_name    = var.cluster.proxmox_cluster
      node_ip         = each.value.ip
      cluster         = var.cluster
      cilium_values   = var.cilium.values
      cilium_install  = var.cilium.install
      coredns_install = var.coredns.install

      # Add GPU flags
      enable_gpu = lookup(each.value, "igpu", false)
      gpu_id     = lookup(each.value, "gpu_id", null)
    })
  ]
}

data "talos_machine_configuration" "worker" {
  for_each = { for k, v in var.nodes : k => v if v.machine_type == "worker" }

  cluster_name       = var.cluster.name
  cluster_endpoint   = "https://${var.cluster.endpoint}:6443"
  talos_version      = var.cluster.talos_version
  machine_type       = each.value.machine_type
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  kubernetes_version = var.cluster.kubernetes_version
  config_patches = [
    templatefile("${path.module}/machine-config/worker.yaml.tftpl", {
      hostname     = each.key
      node_name    = each.value.host_node
      node_ip      = each.value.ip
      cluster_name = var.cluster.name # Pass cluster_name explicitly
      cluster      = var.cluster      # Pass the whole cluster object
      disks        = each.value.disks

      # Add GPU flags
      enable_gpu = lookup(each.value, "igpu", false)
      gpu_id     = lookup(each.value, "gpu_id", null)
    })
  ]
}

resource "talos_machine_configuration_apply" "this" {
  for_each = var.nodes

  client_configuration = data.talos_client_configuration.this.client_configuration
  # Conditionally select the correct machine configuration based on node type
  machine_configuration_input = (
    each.value.machine_type == "controlplane"
    ? data.talos_machine_configuration.this[each.key].machine_configuration
    : data.talos_machine_configuration.worker[each.key].machine_configuration
  )
  node = each.value.ip
  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.this[each.key]]
  }

  # wait for **all** VMs, avoid per-instance indexing
  depends_on = [
    proxmox_virtual_environment_vm.this,
    talos_image_factory_schematic.this,
    talos_image_factory_schematic.updated,
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.this
  ]
  # Bootstrap with the first node. VIP not yet available at this stage, so cant use var.cluster.endpoint as it may be set to VIP
  # ref - https://www.talos.dev/v1.9/talos-guides/network/vip/#caveats
  node                 = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  node                 = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]
  endpoint             = var.cluster.endpoint
  client_configuration = talos_machine_secrets.this.client_configuration
  timeouts = {
    read = "1m"
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
