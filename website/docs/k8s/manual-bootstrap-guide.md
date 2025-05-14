---
sidebar_position: 3
title: Manual Bootstrap Guide
description: Step-by-step instructions for manually bootstrapping the cluster
---

# Manual Cluster Bootstrap Guide

This guide provides the steps necessary to bootstrap a new cluster manually. This is typically only needed for initial cluster setup or disaster recovery.

## Prerequisites

- A running Talos Linux cluster
- `kubectl` configured with cluster access
- `kustomize` CLI installed
- `argocd` CLI installed (optional)

## 1. CRD Installation

First, apply all Custom Resource Definitions (CRDs) to avoid dependency issues:

```shell
kubectl apply -k k8s/infrastructure/crds
```

## 2. Core Infrastructure Components

### 2.1 Cilium CNI

Install Cilium networking (must be done before other components):

```shell
kubectl kustomize --enable-helm k8s/infrastructure/network/cilium | kubectl apply -f -

# Wait for Cilium to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cilium -n kube-system --timeout=90s
```

### 2.2 cert-manager

Install cert-manager for certificate management:

```shell
kustomize build --enable-helm k8s/infrastructure/controllers/cert-manager | kubectl apply -f -

# Wait for cert-manager webhook to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=webhook -n cert-manager --timeout=90s
```

### 2.3 ArgoCD

Install ArgoCD for GitOps:

```shell
# Install ArgoCD components
kustomize build --enable-helm k8s/infrastructure/controllers/argocd | kubectl apply -f -

# Wait for ArgoCD server to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=120s

# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

### 2.4 Storage, DNS, and Secrets Management

Install remaining core components:

```shell
# Longhorn storage
kustomize build --enable-helm k8s/infrastructure/storage/longhorn | kubectl apply -f -

# CoreDNS for cluster DNS
kustomize build --enable-helm k8s/infrastructure/network/coredns | kubectl apply -f -

# External Secrets Operator
kustomize build --enable-helm k8s/infrastructure/controllers/external-secrets | kubectl apply -f -
```

## 3. Secrets Configuration

### 3.1 External Secrets Setup

Create the Bitwarden secrets operator token:

```shell
# Replace <your-token> with your actual Bitwarden API token
kubectl create secret generic bitwarden-access-token \
  --namespace external-secrets \
  --from-literal=token=<your-token>
```

Trust Let's Encrypt certificates for External Secrets:

```shell
# Download Let's Encrypt Root certificate
curl -Lo isrgrootx1.pem https://letsencrypt.org/certs/isrgrootx1.pem

# Create the certificate trust secret
kubectl create secret generic letsencrypt-ca \
  --namespace external-secrets \
  --from-file=ca.crt=isrgrootx1.pem
```

## 4. GitOps Configuration

Apply the ApplicationSet configurations in order:

```shell
# Infrastructure components
kubectl apply -f k8s/infrastructure/project.yaml
kubectl apply -f k8s/infrastructure/application-set.yaml

# Wait for infrastructure components to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=authentik-worker -n auth --timeout=300s

# Applications
kubectl apply -f k8s/applications/project.yaml
kubectl apply -f k8s/applications/application-set.yaml
```

## Verification

1. Verify ArgoCD applications:
```shell
kubectl get applications -A
```

2. Check External Secrets:
```shell
kubectl get externalsecrets -A
```

3. Verify core services:
```shell
kubectl get pods -n kube-system
kubectl get pods -n cert-manager
kubectl get pods -n external-secrets
kubectl get pods -n argocd
```

## Troubleshooting

- If ArgoCD applications fail to sync, check:
  1. Git repository access
  2. Helm repository access
  3. Application dependency order (sync waves)

- If External Secrets fail:
  1. Verify Bitwarden token secret
  2. Check certificate trust configuration
  3. Validate ClusterSecretStore configuration
