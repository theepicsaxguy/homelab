resource "null_resource" "external_secrets_kustomize" {
  triggers = {
    manifests = sha256(join("", [for f in fileset("${path.module}/../../../k8s/infrastructure/controllers/external-secrets", "*.yaml") : filesha256("${path.module}/../../../k8s/infrastructure/controllers/external-secrets/${f}")]))
  }

  provisioner "local-exec" {
    command     = "kustomize build --enable-helm . | kubectl apply -f - --server-side --force-conflicts"
    working_dir = "${path.module}/../../../k8s/infrastructure/controllers/external-secrets"
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "kustomize build --enable-helm . | kubectl delete -f - --ignore-not-found=true"
    working_dir = "${path.module}/../../../k8s/infrastructure/controllers/external-secrets"
  }
}

resource "null_resource" "wait_for_external_secrets" {
  depends_on = [null_resource.external_secrets_kustomize]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=available --timeout=300s deployment/external-secrets deployment/external-secrets-webhook deployment/external-secrets-cert-controller -n external-secrets"
  }
}
