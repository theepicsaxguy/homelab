# Manual bootstrap

## Pre-requisites

- Talos cluster is running
- kubeconfig is available

## CRDs

First apply CRDs to avoid dependency issues:

```shell
kubectl apply -k infra/crds
kubectl apply -k infra/crossplane-crds
```

## Core Infrastructure

Apply Cilium networking before other components:

```shell
kubectl kustomize --enable-helm infra/network/cilium | kubectl apply -f -
```

Wait for Cilium to be ready:

```shell
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cilium -n kube-system --timeout=90s
```

## Bitwarden Secrets

```shell
kustomize build --enable-helm infra/controllers/bitwarden | kubectl apply -f -
```

Create secrets token (required for sm-operator):

```shell
kubectl create secret generic bw-auth-token -n sm-operator-system --from-literal=token="<Auth-Token-Here>"
```

## Storage Setup

```shell
kustomize build --enable-helm infra/storage/proxmox-csi | kubectl apply -f -
```

Verify storage classes:

```shell
kubectl get csistoragecapacities -ocustom-columns=CLASS:.storageClassName,AVAIL:.capacity,ZONE:.nodeTopology.matchLabels -A
```

## ArgoCD Bootstrap

Install ArgoCD:

```shell
kustomize build --enable-helm infra/controllers/argocd | kubectl apply -f -
```

Wait for ArgoCD to be ready:

```shell
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=120s
```

Get initial admin password:

```shell
kubectl -n argocd get secret argocd-initial-admin-secret -ojson | jq -r '.data.password | @base64d'
```

## GitOps Configuration

Apply root applications in order:

```shell
kubectl apply -k sets
```

This will trigger the following applications with sync-waves:

1. infrastructure (-1): Core infrastructure components
2. applications (0): User applications

# Components Status

## Core Components

- [x] Cilium CNI
- [x] Hubble Network Monitoring
- [x] ArgoCD
- [x] Proxmox CSI Plugin
- [x] Cert-manager
- [x] Gateway API
- [x] Authentication (Keycloak)
- [x] CNPG - Cloud Native PostgreSQL

## Required CRDs

- [x] Gateway API (via infra/crds)
- [x] ArgoCD (via operator)
- [x] Sealed-secrets (via operator)
- [x] Crossplane (via crossplane-crds)

## Implemented Features

- [x] Remotely managed cloudflared tunnel
- [x] Keycloak authentication
- [x] ArgoCD sync-waves
- [x] Automated infrastructure healing
