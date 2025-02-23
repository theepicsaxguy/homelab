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

> **Note**: If ArgoCD is already installed, the bootstrap process will skip the installation and only ensure the App-of-Apps configuration is applied.

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

1. Verify ArgoCD status:
```shell
kubectl get pods -n argocd
```

2. Get the ArgoCD admin password (if newly installed):
```shell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

3. Monitor the App-of-Apps sync status:
```shell
kubectl get applications -n argocd
```

## Troubleshooting

If you need to reinstall ArgoCD:

1. Remove the existing installation:
```shell
kubectl delete ns argocd
```

2. Run the bootstrap process again:
```shell
tofu apply
