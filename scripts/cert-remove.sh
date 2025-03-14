#!/bin/bash

set -euo pipefail

echo "[INFO] Deleting ClusterIssuers..."
if kubectl get clusterissuer --no-headers 2>/dev/null | grep -q .; then
  kubectl delete clusterissuer --all
else
  echo "[INFO] No ClusterIssuers found"
fi

echo "[INFO] Removing cert-manager finalizers (if stuck)..."
if kubectl get clusterissuer -o json 2>/dev/null | jq '.items | length' | grep -q '[1-9]'; then
  kubectl get clusterissuer -o json | jq '.items[].metadata.finalizers=null' | kubectl apply -f -
else
  echo "[INFO] No cert-manager finalizers found"
fi

echo "[INFO] Removing cert-manager namespace finalizers (if stuck)..."
if kubectl get namespace cert-manager -o json 2>/dev/null | jq '.metadata.finalizers | length' | grep -q '[1-9]'; then
  kubectl get namespace cert-manager -o json | jq '.spec.finalizers=[]' | kubectl replace --raw "/api/v1/namespaces/cert-manager/finalize" -f -
else
  echo "[INFO] No namespace finalizers found"
fi

echo "[INFO] Deleting cert-manager namespace..."
kubectl delete namespace cert-manager --ignore-not-found=true --wait=true || true

echo "[INFO] Deleting cert-manager CRDs..."
kubectl get crds | grep "cert-manager" | awk '{print $1}' | xargs -r kubectl delete crd
echo "[INFO] Cert-manager CRDs deleted"

echo "[INFO] Deleting cert-manager ClusterRoles and ClusterRoleBindings..."
kubectl get clusterrole,clusterrolebinding -l app.kubernetes.io/name=cert-manager -o name 2>/dev/null | xargs -r kubectl delete
echo "[INFO] Cert-manager ClusterRoles and ClusterRoleBindings deleted"

echo "[INFO] Deleting cert-manager RoleBindings..."
kubectl get rolebinding,role -A 2>/dev/null | grep cert-manager | awk '{print $1 " -n " $2}' | xargs -r -L1 kubectl delete
echo "[INFO] Cert-manager RoleBindings deleted"

echo "[INFO] Deleting cert-manager Mutating and Validating Webhooks..."
kubectl get mutatingwebhookconfiguration,validatingwebhookconfiguration -o name 2>/dev/null | grep cert-manager | xargs -r kubectl delete
echo "[INFO] Cert-manager Webhooks deleted"

echo "[INFO] Removing leftover cert-manager secrets..."
kubectl get secrets -A 2>/dev/null | grep cert-manager | awk '{print $1 " -n " $2}' | xargs -r -L1 kubectl delete
echo "[INFO] Cert-manager secrets removed"

echo "[INFO] Verifying cleanup..."
if kubectl get all -A 2>/dev/null | grep -q cert-manager; then
  echo "[ERROR] Some cert-manager resources are still present!"
  kubectl get all -A | grep cert-manager
else
  echo "[SUCCESS] cert-manager fully removed."
fi

echo "[INFO] Cleanup complete. You can now reinstall cert-manager."
