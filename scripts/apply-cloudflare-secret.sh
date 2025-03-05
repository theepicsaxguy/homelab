#!/bin/bash

# This script applies the Cloudflare API token secret temporarily
# It should be used only during bootstrap when external-secrets is not fully functional
# DO NOT commit your API token to git!

set -e

# Check if API token is provided
if [ -z "$1" ]; then
  echo "Error: Cloudflare API token not provided"
  echo "Usage: $0 <YOUR_CLOUDFLARE_API_TOKEN>"
  exit 1
fi

# Create temporary file with the token
cat << EOF > /tmp/cloudflare-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: infrastructure-secrets
  namespace: cert-manager
type: Opaque
stringData:
  cloudflare_api_token: $1
EOF

# Apply the secret
kubectl apply -f /tmp/cloudflare-secret.yaml

# Clean up
rm /tmp/cloudflare-secret.yaml

echo "Cloudflare API token secret applied successfully"
echo "NOTE: This is a temporary solution until external-secrets is fully functional"
echo "The secret will not be tracked by Git"
