# Manual bootstrap

## Pre-requisites

- Talos cluster is running
- kubeconfig is available

## CRDs

First apply CRDs to avoid dependency issues:

```shell
kubectl apply -k infrastructure/crds
```

## Core Infrastructure

Apply Cilium networking before other components:

```shell
kubectl kustomize --enable-helm infrastructure/network/cilium | kubectl apply -f -
```

Wait for Cilium to be ready:

```shell
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cilium -n kube-system --timeout=90s
```

## ArgoCD Bootstrap

Install ArgoCD:

```shell
# Apply ArgoCD network policy first to ensure connectivity
kubectl apply -f infrastructure/controllers/argocd/network-policy.yaml

# Create namespace if it doesn't exist
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD components
kustomize build --enable-helm infrastructure/controllers/argocd | kubectl apply -f -

kubectl apply -k infrastructure/controllers/argo-rollouts

# Check if network policy is correctly applied
kubectl get ciliumnetworkpolicies -n argocd

# If controller pod is stuck, try restarting it
kubectl rollout restart statefulset/argocd-application-controller -n argocd

argocd admin redis-initial-password -n argocd
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
kubectl apply -f infrastructure/project.yaml
kubectl apply -f infrastructure/application-set.yaml
```

## External Secrets Bootstrap

The external-secrets operator requires certificates to be trusted before it can function. Follow these steps:

```shell
 ./scripts/bootstrap-external-secrets.sh
```

## Secrets

Add bitwarden token then apply it.

kubectl apply -f infrastructure/controllers/external-secrets/bitwarden-access-token.yaml

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

kubectl apply -k infrastructure/crds

kubectl kustomize --enable-helm infrastructure/network/cilium | kubectl apply -f -

kubectl kustomize --enable-helm argocd | kubectl apply -f -

kubectl apply -k sets

kubectl kustomize --enable-helm infrastructure/storage/longhorn | kubectl apply -f -
