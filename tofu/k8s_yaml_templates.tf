# This file is auto-generated to render all k8s YAML templates from .yaml.tftpl to .yaml using the cluster_domain variable.

# Frigate values

data "template_file" "frigate_values" {
  template = file("${path.module}/../k8s/applications/automation/frigate/values.yaml.tftpl")
  vars = {
    cluster_domain = var.cluster_domain
  }
}
resource "local_file" "frigate_values" {
  content  = data.template_file.frigate_values.rendered
  filename = "${path.module}/../k8s/applications/automation/frigate/values.yaml"
}

# Zigbee2MQTT config

data "template_file" "zigbee2mqtt_config" {
  template = file("${path.module}/../k8s/applications/automation/zigbee2mqtt/config/configuration.yaml.tftpl")
  vars = {
    cluster_domain = var.cluster_domain
  }
}
resource "local_file" "zigbee2mqtt_config" {
  content  = data.template_file.zigbee2mqtt_config.rendered
  filename = "${path.module}/../k8s/applications/automation/zigbee2mqtt/config/configuration.yaml"
}

# Cilium values

data "template_file" "cilium_values" {
  template = file("${path.module}/../k8s/infrastructure/network/cilium/values.yaml.tftpl")
  vars = {
    cluster_domain = var.cluster_domain
  }
}
resource "local_file" "cilium_values" {
  content  = data.template_file.cilium_values.rendered
  filename = "${path.module}/../k8s/infrastructure/network/cilium/values.yaml"
}

# CoreDNS values

data "template_file" "coredns_values" {
  template = file("${path.module}/../k8s/infrastructure/network/coredns/values.yaml.tftpl")
  vars = {
    cluster_domain = var.cluster_domain
  }
}
resource "local_file" "coredns_values" {
  content  = data.template_file.coredns_values.rendered
  filename = "${path.module}/../k8s/infrastructure/network/coredns/values.yaml"
}

data "template_file" "coredns_configmap" {
  template = file("${path.module}/../k8s/infrastructure/network/coredns/configmap.yaml.tftpl")
  vars = {
    cluster_domain = var.cluster_domain
  }
}
resource "local_file" "coredns_configmap" {
  content  = data.template_file.coredns_configmap.rendered
  filename = "${path.module}/../k8s/infrastructure/network/coredns/configmap.yaml"
}

# Gateway cert

data "template_file" "cert_pc_tips" {
  template = file("${path.module}/../k8s/infrastructure/network/gateway/cert-pc-tips.yaml.tftpl")
  vars = {
    cluster_domain = var.cluster_domain
  }
}
resource "local_file" "cert_pc_tips" {
  content  = data.template_file.cert_pc_tips.rendered
  filename = "${path.module}/../k8s/infrastructure/network/gateway/cert-pc-tips.yaml"
}

# Bitwarden issuer

data "template_file" "bitwarden_issuer" {
  template = file("${path.module}/../k8s/infrastructure/controllers/cert-manager/bitwarden-issuer.yaml.tftpl")
  vars = {
    cluster_domain = var.cluster_domain
  }
}
resource "local_file" "bitwarden_issuer" {
  content  = data.template_file.bitwarden_issuer.rendered
  filename = "${path.module}/../k8s/infrastructure/controllers/cert-manager/bitwarden-issuer.yaml"
}

# Cloudflared config

data "template_file" "cloudflared_config" {
  template = file("${path.module}/../k8s/infrastructure/network/cloudflared/config.yaml.tftpl")
  vars = {
    cluster_domain = var.cluster_domain
  }
}
resource "local_file" "cloudflared_config" {
  content  = data.template_file.cloudflared_config.rendered
  filename = "${path.module}/../k8s/infrastructure/network/cloudflared/config.yaml"
}

# PostgreSQL values

data "template_file" "postgresql_values" {
  template = file("${path.module}/../k8s/infrastructure/database/postgresql/values.yaml.tftpl")
  vars = {
    cluster_domain = var.cluster_domain
  }
}
resource "local_file" "postgresql_values" {
  content  = data.template_file.postgresql_values.rendered
  filename = "${path.module}/../k8s/infrastructure/database/postgresql/values.yaml"
}

# Bitwarden store

data "template_file" "bitwarden_store" {
  template = file("${path.module}/../k8s/infrastructure/controllers/external-secrets/bitwarden-store.yaml.tftpl")
  vars = {
    cluster_domain = var.cluster_domain
  }
}
resource "local_file" "bitwarden_store" {
  content  = data.template_file.bitwarden_store.rendered
  filename = "${path.module}/../k8s/infrastructure/controllers/external-secrets/bitwarden-store.yaml"
}

# Bitwarden certificate

data "template_file" "bitwarden_certificate" {
  template = file("${path.module}/../k8s/infrastructure/controllers/external-secrets/bitwarden-certificate.yaml.tftpl")
  vars = {
    cluster_domain = var.cluster_domain
  }
}
resource "local_file" "bitwarden_certificate" {
  content  = data.template_file.bitwarden_certificate.rendered
  filename = "${path.module}/../k8s/infrastructure/controllers/external-secrets/bitwarden-certificate.yaml"
}

# Kubechecks values

data "template_file" "kubechecks_values" {
  template = file("${path.module}/../k8s/infrastructure/deployment/kubechecks/values.yaml.tftpl")
  vars = {
    cluster_domain = var.cluster_domain
  }
}
resource "local_file" "kubechecks_values" {
  content  = data.template_file.kubechecks_values.rendered
  filename = "${path.module}/../k8s/infrastructure/deployment/kubechecks/values.yaml"
}

# ArgoCD TLS

data "template_file" "argocd_tls" {
  template = file("${path.module}/../k8s/infrastructure/controllers/argocd/argocd-tls.yaml.tftpl")
  vars = {
    cluster_domain = var.cluster_domain
  }
}
resource "local_file" "argocd_tls" {
  content  = data.template_file.argocd_tls.rendered
  filename = "${path.module}/../k8s/infrastructure/controllers/argocd/argocd-tls.yaml"
}
