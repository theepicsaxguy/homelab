resource "kubernetes_secret_v1" "bitwarden_access_token" {
  metadata {
    name      = "bitwarden-access-token"
    namespace = "external-secrets"
  }
  type = "Opaque"
  data = {
    token = var.bitwarden_token
  }
  depends_on = [null_resource.external_secrets_kustomize]
}
