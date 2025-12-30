resource "kubernetes_namespace_v1" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = kubernetes_namespace_v1.external_secrets.metadata[0].name
  version    = var.external_secrets_version

  create_namespace = false

  set = [
    {
      name  = "installCRDs"
      value = "true"
    }
  ]

  values = [
    file("${path.module}/../../../k8s/infrastructure/controllers/external-secrets/values.yaml")
  ]
}

resource "time_sleep" "wait_for_external_secrets" {
  depends_on = [helm_release.external_secrets]

  create_duration = "60s"
}
