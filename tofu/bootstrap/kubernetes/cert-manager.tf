resource "null_resource" "cert_manager_kustomize" {
  triggers = {
    manifests = sha256(join("", [for f in fileset("${path.module}/../../../k8s/infrastructure/controllers/cert-manager", "*.yaml") : filesha256("${path.module}/../../../k8s/infrastructure/controllers/cert-manager/${f}")]))
  }

  provisioner "local-exec" {
    command     = "kustomize build --enable-helm . | kubectl apply -f - --server-side --force-conflicts"
    working_dir = "${path.module}/../../../k8s/infrastructure/controllers/cert-manager"
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "kustomize build --enable-helm . | kubectl delete -f - --ignore-not-found=true"
    working_dir = "${path.module}/../../../k8s/infrastructure/controllers/cert-manager"
  }
}

resource "null_resource" "cert_manager_namespace_labels" {
  depends_on = [null_resource.cert_manager_kustomize]

  provisioner "local-exec" {
    command = "kubectl label namespace cert-manager pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/audit=privileged pod-security.kubernetes.io/warn=privileged --overwrite"
  }
}

resource "null_resource" "wait_for_cert_manager" {
  depends_on = [null_resource.cert_manager_kustomize]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=available --timeout=300s deployment/cert-manager deployment/cert-manager-webhook deployment/cert-manager-cainjector -n cert-manager"
  }
}
