#!/bin/bash
set -e

# This script creates the required secrets for Bitwarden Secrets Manager integration with External Secrets Operator

# Check if the BITWARDEN_ACCESS_TOKEN is provided
if [ -z "$BITWARDEN_ACCESS_TOKEN" ]; then
  echo "ERROR: BITWARDEN_ACCESS_TOKEN environment variable is required"
  echo "Usage: BITWARDEN_ACCESS_TOKEN=your_token ./bootstrap-bitwarden-secrets.sh"
  exit 1
fi

# Namespace for the ArgoCD installation
NAMESPACE="argocd"

# Create the bitwarden-access-token secret
echo "Creating bitwarden-access-token secret in $NAMESPACE namespace..."
kubectl create secret generic bitwarden-access-token \
  --namespace "$NAMESPACE" \
  --from-literal=token="$BITWARDEN_ACCESS_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

# Get the CA certificate from the bitwarden-sdk-server in the external-secrets namespace
echo "Fetching CA certificate from bitwarden-sdk-server..."
SDK_CA=$(kubectl get secret -n external-secrets bitwarden-sdk-server-tls -o jsonpath='{.data.ca\.crt}')

if [ -z "$SDK_CA" ]; then
  echo "ERROR: Could not fetch CA certificate from bitwarden-sdk-server-tls secret"
  echo "Make sure the bitwarden-sdk-server is properly installed in the external-secrets namespace"
  exit 1
fi

# Create the bitwarden-sdk-ca secret
echo "Creating bitwarden-sdk-ca secret in $NAMESPACE namespace..."
kubectl create secret generic bitwarden-sdk-ca \
  --namespace "$NAMESPACE" \
  --from-literal=tls.crt="$(echo $SDK_CA | base64 -d)" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Bitwarden secrets created successfully!"
echo "The External Secrets Operator should now be able to fetch secrets from Bitwarden."
