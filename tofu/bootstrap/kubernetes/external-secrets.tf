resource "null_resource" "external_secrets_kustomize" {
  triggers = {
    manifests = sha256(join("", [for f in fileset("${path.module}/../../../k8s/infrastructure/controllers/external-secrets", "*.yaml") : filesha256("${path.module}/../../../k8s/infrastructure/controllers/external-secrets/${f}")]))
  }

  provisioner "local-exec" {
    command     = "kubectl apply -k ."
    working_dir = "${path.module}/../../../k8s/infrastructure/controllers/external-secrets"
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "kubectl delete -k . --ignore-not-found=true"
    working_dir = "${path.module}/../../../k8s/infrastructure/controllers/external-secrets"
  }
}

resource "time_sleep" "wait_for_external_secrets" {
  depends_on = [null_resource.external_secrets_kustomize]

  create_duration = "60s"
}
