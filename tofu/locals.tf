locals {
  cluster_domain_extra = coalesce(var.cluster_domain_extra, "b.${var.cluster_domain}")
}
