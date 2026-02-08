resource "null_resource" "argocd_kustomize" {
  depends_on = [
    null_resource.wait_for_cert_manager,
    null_resource.wait_for_external_secrets,
    null_resource.bitwarden_access_token
  ]

  provisioner "local-exec" {
    command     = "kustomize build --enable-helm . | kubectl apply -f - --server-side --force-conflicts"
    working_dir = "${path.module}/../../../k8s/infrastructure/controllers/argocd"
  }
}

resource "null_resource" "wait_for_argocd" {
  depends_on = [null_resource.argocd_kustomize]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=available --timeout=300s deployment/argocd-server deployment/argocd-repo-server deployment/argocd-applicationset-controller -n argocd"
  }
}

resource "null_resource" "infrastructure_project" {
  depends_on = [null_resource.wait_for_argocd]

  provisioner "local-exec" {
    command = <<-EOT
      cat <<EOF | kubectl apply -f -
      apiVersion: argoproj.io/v1alpha1
      kind: AppProject
      metadata:
        name: infrastructure
        namespace: argocd
      spec:
        description: Project for core infrastructure components
        sourceRepos:
          - ${var.git_repository_url}
        destinations:
          - namespace: argocd
            server: '*'
          - namespace: kube-system
            server: '*'
          - namespace: velero
            server: '*'
          - namespace: infrastructure-system
            server: '*'
        clusterResourceWhitelist:
          - group: '*'
            kind: '*'
      EOF
    EOT
  }
}

resource "null_resource" "infrastructure_appset" {
  depends_on = [null_resource.infrastructure_project]

  provisioner "local-exec" {
    command = <<-EOT
      cat <<EOF | kubectl apply -f -
      apiVersion: argoproj.io/v1alpha1
      kind: ApplicationSet
      metadata:
        name: infrastructure
        namespace: argocd
        labels:
          app.kubernetes.io/part-of: infrastructure
          app.kubernetes.io/managed-by: argocd
        annotations:
          argocd.argoproj.io/sync-wave: "-10"
      spec:
        generators:
          - git:
              repoURL: ${var.git_repository_url}
              revision: main
              directories:
                - path: k8s/infrastructure/controllers
                - path: k8s/infrastructure/network
                - path: k8s/infrastructure/storage
                - path: k8s/infrastructure/monitoring
                - path: k8s/infrastructure/deployment
                - path: k8s/infrastructure/auth
                - path: k8s/infrastructure/database
        template:
          metadata:
            name: infra-{{path.basename}}
            namespace: argocd
            labels:
              app.kubernetes.io/component: static-infrastructure
              app.kubernetes.io/part-of: infrastructure
          spec:
            project: infrastructure
            source:
              repoURL: ${var.git_repository_url}
              targetRevision: main
              path: '{{path}}'
              kustomize: {}
            destination:
              namespace: infrastructure-system
              server: https://kubernetes.default.svc
            syncPolicy:
              automated:
                prune: true
                selfHeal: true
              syncOptions:
                - CreateNamespace=true
                - ApplyOutOfSyncOnly=true
                - ServerSideApply=true
                - PruneLast=true
                - RespectIgnoreDifferences=true
      EOF
    EOT
  }
}

resource "null_resource" "applications_project" {
  depends_on = [null_resource.wait_for_argocd]

  provisioner "local-exec" {
    command = <<-EOT
      cat <<EOF | kubectl apply -f -
      apiVersion: argoproj.io/v1alpha1
      kind: AppProject
      metadata:
        name: applications
        namespace: argocd
      spec:
        description: Project for user-facing applications
        sourceRepos:
          - ${var.git_repository_url}
        destinations:
          - namespace: applications-system
            server: '*'
        namespaceResourceWhitelist:
          - group: '*'
            kind: '*'
        clusterResourceWhitelist:
          - group: ''
            kind: Namespace
      EOF
    EOT
  }
}

resource "null_resource" "applications_appset" {
  depends_on = [
    null_resource.wait_for_argocd,
    null_resource.infrastructure_appset
  ]

  provisioner "local-exec" {
    command = <<-EOT
      cat <<EOF | kubectl apply -f -
      apiVersion: argoproj.io/v1alpha1
      kind: ApplicationSet
      metadata:
        name: applications
        namespace: argocd
        labels:
          app.kubernetes.io/part-of: applications
          app.kubernetes.io/managed-by: argocd
        annotations:
          argocd.argoproj.io/sync-wave: "0"
      spec:
        syncPolicy:
          preserveResourcesOnDeletion: true
        generators:
          - git:
              repoURL: ${var.git_repository_url}
              revision: main
              directories:
                - path: k8s/applications/media
                - path: k8s/applications/tools
                - path: k8s/applications/ai
                - path: k8s/applications/external
                - path: k8s/applications/web
                - path: k8s/applications/network
                - path: k8s/applications/automation
        template:
          metadata:
            name: apps-{{path.basename}}
            namespace: argocd
            labels:
              app.kubernetes.io/component: static-applications
              app.kubernetes.io/part-of: applications
          spec:
            project: applications
            source:
              repoURL: ${var.git_repository_url}
              targetRevision: main
              path: '{{path}}'
              kustomize: {}
            destination:
              namespace: applications-system
              server: https://kubernetes.default.svc
            syncPolicy:
              automated:
                prune: true
                selfHeal: true
              syncOptions:
                - CreateNamespace=true
                - ApplyOutOfSyncOnly=true
                - ServerSideApply=true
                - PruneLast=true
                - RespectIgnoreDifferences=true
      EOF
    EOT
  }
}
