# Manual Post-Bootstrap Steps

## Pre-requisites

- Talos cluster is running (via OpenTofu)
- kubeconfig is available (from OpenTofu output)

## Steps

### 1. ArgoCD Bootstrap

```shell
cd k8s
tofu init && tofu apply
```

### 2. Create Bitwarden Auth Token

Once ArgoCD installs the Bitwarden Secrets Manager operator, create the auth token:

```shell
kubectl create secret generic bw-auth-token \
  -n sm-operator-system \
  --from-literal=token="<Auth-Token-Here>"
```

Get your auth token from Bitwarden EU region: https://api.bitwarden.eu

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
- [x] Authentication (Keycloak)
- [x] CNPG - Cloud Native PostgreSQL

## Next Steps

1. Get the ArgoCD admin password:

```shell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

2. Monitor the App-of-Apps sync status:

```shell
kubectl get applications -n argocd
```
