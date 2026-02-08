resource "null_resource" "cert_manager_kustomize" {
  provisioner "local-exec" {
    command     = "kubectl delete job cert-manager-startupapicheck -n cert-manager --ignore-not-found=true && kustomize build --enable-helm . | kubectl apply -f - --server-side --force-conflicts"
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
