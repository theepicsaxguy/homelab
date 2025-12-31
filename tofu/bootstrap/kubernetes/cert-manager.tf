resource "null_resource" "cert_manager_kustomize" {
  triggers = {
    manifests = sha256(join("", [for f in fileset("${path.module}/../../../k8s/infrastructure/controllers/cert-manager", "*.yaml") : filesha256("${path.module}/../../../k8s/infrastructure/controllers/cert-manager/${f}")]))
  }

  provisioner "local-exec" {
    command     = "kubectl apply -k ."
    working_dir = "${path.module}/../../../k8s/infrastructure/controllers/cert-manager"
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "kubectl delete -k . --ignore-not-found=true"
    working_dir = "${path.module}/../../../k8s/infrastructure/controllers/cert-manager"
  }
}

resource "kubernetes_labels" "cert_manager_namespace" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = "cert-manager"
  }
  labels = {
    "pod-security.kubernetes.io/enforce" = "privileged"
    "pod-security.kubernetes.io/audit"   = "privileged"
    "pod-security.kubernetes.io/warn"    = "privileged"
  }
  depends_on = [null_resource.cert_manager_kustomize]
}

resource "time_sleep" "wait_for_cert_manager" {
  depends_on = [null_resource.cert_manager_kustomize]

  create_duration = "90s"
}
