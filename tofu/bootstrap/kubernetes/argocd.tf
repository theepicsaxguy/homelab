resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  version    = var.argocd_version

  create_namespace = false

  depends_on = [
    time_sleep.wait_for_cert_manager,
    time_sleep.wait_for_external_secrets,
    kubernetes_secret_v1.bitwarden_access_token
  ]

  values = [
    file("${path.module}/../../../k8s/infrastructure/controllers/argocd/values.yaml")
  ]
}

resource "time_sleep" "wait_for_argocd" {
  depends_on = [helm_release.argocd]

  create_duration = "90s"
}

resource "kubernetes_manifest" "infrastructure_project" {
  depends_on = [time_sleep.wait_for_argocd]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "infrastructure"
      namespace = "argocd"
    }
    spec = {
      description = "Project for core infrastructure components"
      sourceRepos = [var.git_repository_url]
      destinations = [
        { namespace = "argocd", server = "*" },
        { namespace = "kube-system", server = "*" },
        { namespace = "velero", server = "*" },
        { namespace = "infrastructure-system", server = "*" },
      ]
      clusterResourceWhitelist = [
        { group = "*", kind = "*" }
      ]
    }
  }
}

resource "kubernetes_manifest" "infrastructure_appset" {
  depends_on = [kubernetes_manifest.infrastructure_project]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "infrastructure"
      namespace = "argocd"
      labels = {
        "app.kubernetes.io/part-of"    = "infrastructure"
        "app.kubernetes.io/managed-by" = "argocd"
      }
      annotations = {
        "argocd.argoproj.io/sync-wave" = "-10"
      }
    }
    spec = {
      generators = [
        {
          git = {
            repoURL  = var.git_repository_url
            revision = "main"
            directories = [
              { path = "k8s/infrastructure/controllers" },
              { path = "k8s/infrastructure/network" },
              { path = "k8s/infrastructure/storage" },
              { path = "k8s/infrastructure/monitoring" },
              { path = "k8s/infrastructure/deployment" },
              { path = "k8s/infrastructure/auth" },
              { path = "k8s/infrastructure/database" },
            ]
          }
        }
      ]
      template = {
        metadata = {
          name      = "infra-{{path.basename}}"
          namespace = "argocd"
          labels = {
            "app.kubernetes.io/component" = "static-infrastructure"
            "app.kubernetes.io/part-of"   = "infrastructure"
          }
        }
        spec = {
          project = "infrastructure"
          source = {
            repoURL        = var.git_repository_url
            targetRevision = "main"
            path           = "{{path}}"
            kustomize      = {}
          }
          destination = {
            namespace = "infrastructure-system"
            server    = "https://kubernetes.default.svc"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = [
              "CreateNamespace=true",
              "ApplyOutOfSyncOnly=true",
              "ServerSideApply=true",
              "PruneLast=true",
              "RespectIgnoreDifferences=true"
            ]
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "applications_project" {
  depends_on = [time_sleep.wait_for_argocd]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "applications"
      namespace = "argocd"
    }
    spec = {
      description = "Project for user-facing applications"
      sourceRepos = [var.git_repository_url]
      destinations = [
        { namespace = "applications-system", server = "*" }
      ]
      namespaceResourceWhitelist = [
        { group = "*", kind = "*" }
      ]
      clusterResourceWhitelist = [
        { group = "", kind = "Namespace" }
      ]
    }
  }
}

resource "kubernetes_manifest" "applications_appset" {
  depends_on = [
    time_sleep.wait_for_argocd,
    kubernetes_manifest.infrastructure_appset
  ]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "applications"
      namespace = "argocd"
      labels = {
        "app.kubernetes.io/part-of"    = "applications"
        "app.kubernetes.io/managed-by" = "argocd"
      }
      annotations = {
        "argocd.argoproj.io/sync-wave" = "0"
      }
    }
    spec = {
      syncPolicy = {
        preserveResourcesOnDeletion = true
      }
      generators = [
        {
          git = {
            repoURL  = var.git_repository_url
            revision = "main"
            directories = [
              { path = "k8s/applications/media" },
              { path = "k8s/applications/tools" },
              { path = "k8s/applications/ai" },
              { path = "k8s/applications/external" },
              { path = "k8s/applications/web" },
              { path = "k8s/applications/network" },
              { path = "k8s/applications/automation" },
            ]
          }
        }
      ]
      template = {
        metadata = {
          name      = "apps-{{path.basename}}"
          namespace = "argocd"
          labels = {
            "app.kubernetes.io/component" = "static-applications"
            "app.kubernetes.io/part-of"   = "applications"
          }
        }
        spec = {
          project = "applications"
          source = {
            repoURL        = var.git_repository_url
            targetRevision = "main"
            path           = "{{path}}"
            kustomize      = {}
          }
          destination = {
            namespace = "applications-system"
            server    = "https://kubernetes.default.svc"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = [
              "CreateNamespace=true",
              "ApplyOutOfSyncOnly=true",
              "ServerSideApply=true",
              "PruneLast=true",
              "RespectIgnoreDifferences=true"
            ]
          }
        }
      }
    }
  }
}
