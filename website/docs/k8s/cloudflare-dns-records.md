---
title: 'External DNS records with Crossplane and Cloudflare'
---

This document explains how we deploy Crossplane with the Cloudflare provider to declaratively manage external CNAME DNS records in our GitOps workflow.

## About external DNS records with Crossplane and Cloudflare

Crossplane transforms cloud services into Kubernetes APIs, enabling GitOps-friendly management of DNS entries. By installing the Crossplane control plane, configuring the Cloudflare provider, and declaring `Record` resources, we automate the lifecycle of CNAME records.

:::info
Maintain manifest definitions in `k8s/infrastructure/controllers/crossplane/` and each application’s directory to prevent documentation drift.
:::

### More details about the Cloudflare provider setup

- **Crossplane chart**
  Deploys Crossplane into the `crossplane-system` namespace to enable its CRDs and controllers.

- **ExternalSecret**
  Retrieves the Cloudflare API token from a Bitwarden-backed `ClusterSecretStore` into a Kubernetes Secret.

- **Provider**
  Installs the Crossplane Cloudflare provider package.

- **ProviderConfig**
  References the synced Secret to supply credentials to the provider.

## Prerequisites

- A Kubernetes cluster with `kubectl` access.
- A `ClusterSecretStore` containing a valid Cloudflare API token under the key `cloudflare_api_token`.
- GitOps tooling (Argo CD, Flux, etc.) configured to apply this repository.

## Overview of steps

1. **Deploy Crossplane**: Install the Crossplane Helm chart into `crossplane-system`.
2. **Fetch Cloudflare token**: Create an `ExternalSecret` to sync the API token into a Secret.
3. **Install Cloudflare provider**: Apply the `Provider` and `ProviderConfig` manifests.
4. **Declare DNS records**: Edit `dns-records.yaml` under `k8s/infrastructure/controllers/crossplane/` to add new `Record` entries.
5. **Apply and verify**: Deploy manifests and confirm records in Crossplane and Cloudflare.

## Deploy Crossplane and configure the Cloudflare provider

1. **Install Crossplane chart**
   Apply the official Crossplane Helm chart into `crossplane-system` via your GitOps tool.

2. **Configure external secrets**
   Define an `ExternalSecret` pointing to the Bitwarden-backed `ClusterSecretStore` to sync `cloudflare_api_token` into a Kubernetes Secret named `cloudflare-api-token`.

3. **Install provider and credentials**
   Apply the Crossplane `Provider` for Cloudflare and a `ProviderConfig` that references `cloudflare-api-token`.

## Apply DNS records for each service

DNS records are defined centrally. Update `k8s/infrastructure/controllers/crossplane/dns-records.yaml` with a new `Record` block for each service. ArgoCD reconciles the file and provisions the records in Cloudflare.

## Verify the configuration

- **Crossplane resources**
  Run `kubectl get records.dns.cloudflare.upbound.io -A` and confirm each record’s status is `READY`.

- **Cloudflare dashboard**
  In Cloudflare UI, go to **DNS → pc-tips.se** and verify that CNAME entries point to the correct Tunnel hostnames.
