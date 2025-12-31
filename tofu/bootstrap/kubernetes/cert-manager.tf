resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = var.cert_manager_version

  create_namespace = true

  depends_on = [null_resource.annotate_cert_manager]

  set = [
    {
      name  = "crds.enabled"
      value = "true"
    },
    {
      name  = "crds.keep"
      value = "true"
    }
  ]

  values = [
    file("${path.module}/../../../k8s/infrastructure/controllers/cert-manager/values.yaml")
  ]
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
  depends_on = [helm_release.cert_manager]
}

resource "time_sleep" "wait_for_cert_manager" {
  depends_on = [helm_release.cert_manager]

  create_duration = "90s"
}
