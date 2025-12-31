resource "null_resource" "bitwarden_access_token" {
  depends_on = [null_resource.external_secrets_kustomize]

  triggers = {
    token = var.bitwarden_token
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl create secret generic bitwarden-access-token \
        --namespace=external-secrets \
        --from-literal=token='${var.bitwarden_token}' \
        --dry-run=client -o yaml | \
      kubectl apply -f -
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete secret bitwarden-access-token -n external-secrets --ignore-not-found=true"
  }
}
