resource "null_resource" "annotate_cert_manager" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl annotate namespace cert-manager meta.helm.sh/release-name=cert-manager meta.helm.sh/release-namespace=cert-manager --overwrite 2>/dev/null || true
      kubectl annotate -n cert-manager serviceaccount,deployment,service,configmap,secret --all meta.helm.sh/release-name=cert-manager meta.helm.sh/release-namespace=cert-manager --overwrite 2>/dev/null || true
    EOT
  }
}

resource "null_resource" "annotate_external_secrets" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl annotate namespace external-secrets meta.helm.sh/release-name=external-secrets meta.helm.sh/release-namespace=external-secrets --overwrite 2>/dev/null || true
      kubectl annotate -n external-secrets serviceaccount,deployment,service,configmap,secret --all meta.helm.sh/release-name=external-secrets meta.helm.sh/release-namespace=external-secrets --overwrite 2>/dev/null || true
    EOT
  }
}

resource "null_resource" "annotate_argocd" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl annotate namespace argocd meta.helm.sh/release-name=argocd meta.helm.sh/release-namespace=argocd --overwrite 2>/dev/null || true
      kubectl annotate -n argocd serviceaccount,deployment,service,configmap,secret --all meta.helm.sh/release-name=argocd meta.helm.sh/release-namespace=argocd --overwrite 2>/dev/null || true
    EOT
  }
}
