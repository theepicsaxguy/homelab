#!/bin/bash
set -euo pipefail

# Function to convert a BitwardenSecret to ExternalSecret
convert_secret() {
    local file="$1"
    local namespace=$(yq e '.metadata.namespace' "$file")
    local name=$(yq e '.metadata.name' "$file")
    local secret_name=$(yq e '.spec.secretName' "$file")
    
    # Create new ExternalSecret manifest
    cat > "${file%.yaml}-external.yaml" << EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ${name}
  namespace: ${namespace}
  labels:
    $(yq e '.metadata.labels' "$file")
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: bitwarden-backend
    kind: SecretStore
  target:
    name: ${secret_name}
    creationPolicy: Owner
  data:
EOF

    # Convert each secret mapping
    yq e '.spec.map[]' "$file" | while read -r mapping; do
        local bw_id=$(echo "$mapping" | yq e '.bwSecretId')
        local key_name=$(echo "$mapping" | yq e '.secretKeyName')
        echo "  - secretKey: ${key_name}
    remoteRef:
      key: ${bw_id}" >> "${file%.yaml}-external.yaml"
    done
    
    echo "Converted $file to ${file%.yaml}-external.yaml"
}

# Find and convert all BitwardenSecret files
find /root/homelab/k8s -type f -name "*.yaml" -exec grep -l "kind: BitwardenSecret" {} \; | while read -r file; do
    convert_secret "$file"
done

echo "Migration complete. Please review the generated -external.yaml files and update your Kustomization files accordingly."