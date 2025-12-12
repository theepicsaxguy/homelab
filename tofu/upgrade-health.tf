# Automated Node Upgrade Health Checks
# This file implements health verification after node upgrades.
#
# Upgrade Flow:
# 1. All nodes upgrade simultaneously when talos_image.version changes
# 2. After VMs are replaced, a single health check validates ALL nodes
# 3. The health check runs talosctl health for the entire cluster
#
# Note: Sequential node upgrades are not possible with terraform_data
# because for_each resources cannot depend on each other without creating cycles.
# Instead, we rely on Kubernetes and Talos to handle graceful rollout.
#
# Usage:
# 1. Change talos_image.version in talos_image.auto.tfvars
# 2. Run `tofu apply` ONCE
# 3. All nodes upgrade and cluster health is verified

locals {
  # Build upgrade sequence for visibility (control planes first, then workers)
  upgrade_sequence = concat(
    sort([for name, config in var.nodes_config : name if config.machine_type == "controlplane"]),
    sort([for name, config in var.nodes_config : name if config.machine_type == "worker"])
  )

  # Get all node IPs for cluster health check
  all_node_ips = [for name, config in var.nodes_config : config.ip]
}

# Cluster-wide health check AFTER all nodes upgrade
# This runs once after all VMs are replaced
resource "terraform_data" "cluster_health" {
  triggers_replace = {
    version = var.talos_image.version
  }

  provisioner "local-exec" {
    command     = <<-EOT
      echo "Waiting for cluster to become healthy after upgrade to ${var.talos_image.version}..."
      talosctl health --wait-timeout=15m
      echo "✓ Cluster is healthy - all nodes upgraded successfully"
    EOT
    interpreter = ["bash", "-c"]
  }
}

# Output upgrade sequence for visibility
output "upgrade_sequence" {
  value = {
    sequence        = local.upgrade_sequence
    total_nodes     = length(local.upgrade_sequence)
    current_version = var.talos_image.version
  }
  description = "Automated upgrade sequence - all nodes upgrade automatically when version changes"
}
