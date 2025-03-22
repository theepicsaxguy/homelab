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

```shell
kustomize build --enable-helm infrastructure/controllers/cert-manager | kubectl apply -f -
```

## ArgoCD Bootstrap

Install ArgoCD:

```shell

# Install ArgoCD components
kustomize build --enable-helm infrastructure/controllers/argocd | kubectl apply -f -

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

```shell
kustomize build --enable-helm infrastructure/storage/longhorn | kubectl apply -f -
```

```shell
kustomize build --enable-helm infrastructure/network/coredns | kubectl apply -f -
```

```shell
kustomize build --enable-helm infrastructure/controllers/external-secrets | kubectl apply -f -
```

```shell
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: bitwarden-access-token
  namespace: external-secrets
type: Opaque
data:
  token: base64token==
EOF
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
