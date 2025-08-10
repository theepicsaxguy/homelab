resource "talos_machine_secrets" "this" {
  count         = var.manage_cluster ? 1 : 0
  talos_version = var.cluster.talos_version
}
