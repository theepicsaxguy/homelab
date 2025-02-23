#!/bin/bash
set -euo pipefail

if [[ -z "${BW_ACCESS_TOKEN:-}" ]]; then
  echo "Error: BW_ACCESS_TOKEN environment variable must be set"
  exit 1
fi

# Create initial auth token secret
kubectl create secret generic bw-auth-token \
  -n sm-operator-system \
  --from-literal=token="${BW_ACCESS_TOKEN}"

# Wait for operator to become ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=sm-operator -n sm-operator-system --timeout=60s

echo "Bitwarden SM Operator bootstrapped successfully"