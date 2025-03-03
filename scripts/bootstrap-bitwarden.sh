#!/bin/bash
set -euo pipefail

# Check if BW_ACCESS_TOKEN is set, otherwise prompt the user
if [[ -z "${BW_ACCESS_TOKEN:-}" ]]; then
  read -sp "Enter Bitwarden Access Token: " BW_ACCESS_TOKEN
  echo
  if [[ -z "${BW_ACCESS_TOKEN}" ]]; then
    echo "Error: BW_ACCESS_TOKEN must be provided."
    exit 1
  fi
fi

# Get the list of namespaces
namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

# Loop through each namespace and create or replace the secret
for namespace in $namespaces; do
  # Skip default or kube-system namespaces, you can adjust this list as needed
  if [[ "$namespace" == "default" || "$namespace" == "kube-system" ]]; then
    continue
  fi

  # Create or replace the secret in each namespace
  kubectl apply -n "${namespace}" -f <(echo "
apiVersion: v1
kind: Secret
metadata:
  name: bw-auth-token
data:
  token: $(echo -n "${BW_ACCESS_TOKEN}" | base64 | tr -d '\n')
")

  # Verify if the secret was successfully created or replaced
  if kubectl get secret bw-auth-token -n "${namespace}" &>/dev/null; then
    echo "Secret 'bw-auth-token' successfully created or replaced in namespace '${namespace}'"
  else
    echo "Error: Secret 'bw-auth-token' not found in namespace '${namespace}', moving on..."
  fi
done

# Wait for the operator to become ready in each namespace
for namespace in $namespaces; do
  # Skip default or kube-system namespaces
  if [[ "$namespace" == "default" || "$namespace" == "kube-system" ]]; then
    continue
  fi

  kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=sm-operator -n "${namespace}" --timeout=60s || echo "Operator in namespace '${namespace}' did not become ready within the timeout"
done

echo "Bitwarden SM Operator bootstrapped successfully in all namespaces"
