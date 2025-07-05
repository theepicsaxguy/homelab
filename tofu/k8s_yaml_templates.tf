# This file is auto-generated to render all k8s YAML templates from .yaml.tftpl to .yaml using the cluster_domain variable.

locals {
  resource_template_definitions = {
    frigate_values = {
      template_path = "${path.module}/../k8s/applications/automation/frigate/values.yaml.tftpl"
      output_path   = "${path.module}/../k8s/applications/automation/frigate/values.yaml"
    },
    zigbee2mqtt_config = {
      template_path = "${path.module}/../k8s/applications/automation/zigbee2mqtt/config/configuration.yaml.tftpl"
      output_path   = "${path.module}/../k8s/applications/automation/zigbee2mqtt/config/configuration.yaml"
    },
    cilium_values = {
      template_path = "${path.module}/../k8s/infrastructure/network/cilium/values.yaml.tftpl"
      output_path   = "${path.module}/../k8s/infrastructure/network/cilium/values.yaml"
    },
    coredns_values = {
      template_path = "${path.module}/../k8s/infrastructure/network/coredns/values.yaml.tftpl"
      output_path   = "${path.module}/../k8s/infrastructure/network/coredns/values.yaml"
    },
    coredns_configmap = {
      template_path = "${path.module}/../k8s/infrastructure/network/coredns/configmap.yaml.tftpl"
      output_path   = "${path.module}/../k8s/infrastructure/network/coredns/configmap.yaml"
    },
    cert_pc_tips = {
      template_path = "${path.module}/../k8s/infrastructure/network/gateway/cert-pc-tips.yaml.tftpl"
      output_path   = "${path.module}/../k8s/infrastructure/network/gateway/cert-pc-tips.yaml"
    },
    bitwarden_issuer = {
      template_path = "${path.module}/../k8s/infrastructure/controllers/cert-manager/bitwarden-issuer.yaml.tftpl"
      output_path   = "${path.module}/../k8s/infrastructure/controllers/cert-manager/bitwarden-issuer.yaml"
    },
    cloudflared_config = {
      template_path = "${path.module}/../k8s/infrastructure/network/cloudflared/config.yaml.tftpl"
      output_path   = "${path.module}/../k8s/infrastructure/network/cloudflared/config.yaml"
    },
    postgresql_values = {
      template_path = "${path.module}/../k8s/infrastructure/database/postgresql/values.yaml.tftpl"
      output_path   = "${path.module}/../k8s/infrastructure/database/postgresql/values.yaml"
    },
    bitwarden_store = {
      template_path = "${path.module}/../k8s/infrastructure/controllers/external-secrets/bitwarden-store.yaml.tftpl"
      output_path   = "${path.module}/../k8s/infrastructure/controllers/external-secrets/bitwarden-store.yaml"
    },
    bitwarden_certificate = {
      template_path = "${path.module}/../k8s/infrastructure/controllers/external-secrets/bitwarden-certificate.yaml.tftpl"
      output_path   = "${path.module}/../k8s/infrastructure/controllers/external-secrets/bitwarden-certificate.yaml"
    },
    kubechecks_values = {
      template_path = "${path.module}/../k8s/infrastructure/deployment/kubechecks/values.yaml.tftpl"
      output_path   = "${path.module}/../k8s/infrastructure/deployment/kubechecks/values.yaml"
    },
    argocd_tls = {
      template_path = "${path.module}/../k8s/infrastructure/controllers/argocd/argocd-tls.yaml.tftpl"
      output_path   = "${path.module}/../k8s/infrastructure/controllers/argocd/argocd-tls.yaml"
    }
  }
}

resource "local_file" "rendered_templates" {
  for_each = local.resource_template_definitions
  content  = templatefile(each.value.template_path, { cluster_domain = var.cluster_domain })
  filename = each.value.output_path
}
