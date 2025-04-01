talos_cluster_config = {
  name                         = "talos"
  # This should point to the vip as below(if nodes on layer 2) or one of the nodes (if nodes not on layer 2)
  # Note: Nodes are not on layer 2 if there is a router between them (even a mesh router)
  #       Not sure how it works if connected to the same router via ethernet (does it act as a switch then???)
  # Ref: https://www.talos.dev/v1.9/talos-guides/network/vip/#requirements
  # Note This is Kubernetes API endpoint. Different from all mentions of Talos endpoints.

  endpoint                     = "api.kube.pc-tips.se:"
  vip                          = "10.25.150.10"
  gateway                      = "10.25.150.1"
  talos_machine_config_version = "v1.9.5"
  proxmox_cluster              = "homelab"
  kubernetes_version           = "1.32.3"

  cilium = {
    bootstrap_manifest_path = "talos/inline-manifests/cilium-install.yaml"
    values_file_path        = "../k8s/infrastructure/network/cilium/values.yaml"
  }
  coredns = {
    bootstrap_manifest_path = "talos/inline-manifests/coredns-install.yaml"
    values_file_path        = "../k8s/infrastructure/network/coredns/values.yaml"
  }

  extra_manifests = [
    "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml",
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.1/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml"
  ]

  kubelet = <<-EOT
    clusterDNS:
      - 10.96.0.10
    defaultRuntimeSeccompProfileEnabled: true
    disableManifestsDirectory: true
    extraArgs:
      rotate-server-certificates: 'true'
    image: ghcr.io/siderolabs/kubelet:v1.32.3
  EOT

  api_server = <<-EOT
    admissionControl:
      - name: PodSecurity
        configuration:
          apiVersion: pod-security.admission.config.k8s.io/v1alpha1
          defaults:
            audit: restricted
            audit-version: latest
            enforce: baseline
            enforce-version: latest
            warn: restricted
            warn-version: latest
          exemptions:
            namespaces:
              - kube-system
            runtimeClasses: []
            usernames: []
          kind: PodSecurityConfiguration
  EOT

  sysctls = <<-EOT
    vm.nr_hugepages: "1024"
  EOT

  kernel = <<-EOT
    modules:
      - name: nvme_tcp
      - name: vfio_pci
  EOT
}
