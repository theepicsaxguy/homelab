module "persistent-volume" {
  for_each = var.volumes
  source   = "./persistent-volume"

  providers = {
    kubernetes = kubernetes
  }

  volume = {
    name     = each.key
    capacity = each.value.size
  }
}
