# Manual bootstrap

## Pre-requisites

- Talos cluster is running
- kubeconfig is available

## Essential Bootstrap Steps

### 1. CRDs 

Apply CRDs required for core functionality:

```shell
kubectl apply -k infra/crds
kubectl apply -k infra/crossplane-crds
```

### 2. Network Layer

Apply Cilium CNI:

```shell
kubectl kustomize --enable-helm infra/network/cilium | kubectl apply -f -
```

Wait for Cilium to be ready:

```shell
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cilium -n kube-system --timeout=90s
```

### 3. ArgoCD Bootstrap

Install ArgoCD:

```shell
kustomize build --enable-helm infra/controllers/argocd | kubectl apply -f -
```

Wait for ArgoCD to be ready:

```shell
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=120s
```

### 4. Initialize GitOps

Apply the root ApplicationSet:

```shell
kubectl apply -k sets
```

ArgoCD will now manage the following components in order:

1. Core Infrastructure (sync-wave: -1)
   - Bitwarden Secrets Manager
   - Storage Controllers
   - Gateway API
   - Certificate Management
   - Authentication

2. Applications (sync-wave: 0)
   - Monitoring Stack
   - User Applications

## Access Information

Get initial ArgoCD admin password:

```shell
kubectl -n argocd get secret argocd-initial-admin-secret -ojson | jq -r '.data.password | @base64d'
```

## Post-Bootstrap Secret Configuration

After Bitwarden Secrets Manager is deployed by ArgoCD, configure the auth token:

```shell
kubectl create secret generic bw-auth-token -n sm-operator-system \
  --from-literal=token="<Auth-Token-Here>" \
  --from-literal=organization-id="4a014e57-f197-4852-9831-b287013e47b6"
```

This is a one-time setup required for the secrets manager to function.
