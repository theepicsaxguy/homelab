locals {
  cluster_domain = coalesce(var.cluster_domain_extra, "b.${var.cluster_domain}")
}
