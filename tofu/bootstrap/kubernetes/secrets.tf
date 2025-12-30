resource "kubernetes_secret_v1" "bitwarden_access_token" {
  metadata {
    name      = "bitwarden-access-token"
    namespace = kubernetes_namespace_v1.external_secrets.metadata[0].name
  }
  type = "Opaque"
  data = {
    token = var.bitwarden_token
  }
  depends_on = [helm_release.external_secrets]
}
