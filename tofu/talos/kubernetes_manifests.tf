locals {
  # Transform the inline manifests list into a map for easier dependency resolution
  inline_manifests_map = { for manifest in var.inline_manifests : manifest.name => manifest }

  # We'll use the raw content strings instead of trying to parse multi-document YAML
  cilium_content = try(local.inline_manifests_map["cilium-install"].content, "")
  coredns_content = try(local.inline_manifests_map["coredns-install"].content, "")
}

# Configure kubernetes provider with the cluster's kubeconfig
provider "kubernetes" {
  config_path = "${path.module}/../output/kube-config.yaml"
}

# The machine configuration is responsible for core bootstrap components
# Following GitOps principles, we don't directly manage Kubernetes resources here
# Instead, we include the necessary manifests in the Talos machine configuration

# Output variables for use by other modules
output "cilium" {
  description = "Cilium installation details"
  value = {
    values = var.cilium.values
  }
}

 output "core_dns" {
   description = "CoreDNS installation details"
   value = {
     install = var.coredns.install
   }
 }
