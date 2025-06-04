#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <upgrade-index>" >&2
  exit 1
fi

INDEX="$1"
INFO=$(tofu -chdir="$(dirname "$0")/.." output -json upgrade_info)
NODE=$(echo "$INFO" | jq -r ".state.sequence[$INDEX]")

if [[ -z "$NODE" || "$NODE" == "null" ]]; then
  echo "Invalid upgrade index: $INDEX" >&2
  exit 1
fi

echo "Current Kubernetes version:"
kubectl version --short

echo "Cordon and drain $NODE"
kubectl cordon "$NODE"
kubectl drain "$NODE" --ignore-daemonsets --delete-emptydir-data

cd "$(dirname "$0")/.."

tofu apply -var "upgrade_control={enabled=true,index=$INDEX}"

kubectl wait --for=condition=Ready node/$NODE --timeout=300s
kubectl uncordon "$NODE"

echo "Kubernetes upgrade for $NODE completed"
