# Manual bootstrap

## Pre-requisites

- Talos cluster is running
- kubeconfig is available

## CRDs

First apply CRDs to avoid dependency issues:

```shell
kubectl apply -k infrastructure/base/crds
kubectl apply -k infrastructure/base/crossplane-crds
```

## Core Infrastructure

Apply Cilium networking before other components:

```shell
kubectl kustomize --enable-helm infrastructure/base/network/cilium | kubectl apply -f -
```

Wait for Cilium to be ready:

```shell
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cilium -n kube-system --timeout=90s
```

## Bitwarden Secrets

```shell
kustomize build --enable-helm infrastructure/base/controllers/bitwarden | kubectl apply -f -
```

Create secrets token (required for sm-operator):

```shell
kubectl create secret generic bw-auth-token -n sm-operator-system --from-literal=token="Auth-Token-Here"
```

## ArgoCD Bootstrap

temporary set redis password.

```shell
openssl rand -base64 32 | kubectl create secret generic argocd-redis --namespace argocd --from-file=auth=/dev/stdin
secret/argocd-redis created
```

Install ArgoCD:

```shell
kustomize build --enable-helm infrastructure/base/controllers/argocd | kubectl apply -f -

kubectl apply -k infrastructure/base/controllers/argo-rollouts
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

## Components Status

### Pre-installed via Talos

- [x] Cilium CNI
- [x] Gateway API CRDs
- [x] Kubernetes API
- [x] etcd

### Auto-deployed via ArgoCD

- [x] Bitwarden Secrets Manager
- [x] Hubble Network Monitoring
- [x] Cert-manager
- [x] CNPG - Cloud Native PostgreSQL

---

kubectl apply -k infrastructure/base/crds

kubectl kustomize --enable-helm infrastructure/base/network/cilium | kubectl apply -f -

kubectl kustomize --enable-helm argocd | kubectl apply -f -

kubectl apply -k sets
