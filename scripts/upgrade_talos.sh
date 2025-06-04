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

echo "Upgrading $NODE (index $INDEX)"

echo "Cordon and drain $NODE"
kubectl cordon "$NODE"
kubectl drain "$NODE" --ignore-daemonsets --delete-emptydir-data

SNAPSHOT="etcd-snapshot-$NODE-$(date +%Y%m%d%H%M%S).db"
CONTROL=$(echo "$INFO" | jq -r '.sequence[0]')

echo "Taking etcd snapshot on $CONTROL -> $SNAPSHOT"
talosctl etcd snapshot --nodes "$CONTROL" --output "$SNAPSHOT"

cd "$(dirname "$0")/.."

tofu apply -var "upgrade_control={enabled=true,index=$INDEX}"

echo "Waiting for Talos health"
talosctl health --wait

echo "Waiting for Kubernetes node readiness"
kubectl wait --for=condition=Ready node/$NODE --timeout=300s

kubectl uncordon "$NODE"

echo "Upgrade of $NODE completed"
