#!/usr/bin/env bash
set -euo pipefail

for cmd in tofu jq kubectl talosctl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Required tool '$cmd' is not installed" >&2
    exit 1
  fi
done

# Ensure talos image variables are present
TFVARS_DIR="$(dirname "$0")/../tofu"
if [[ ! -f "$TFVARS_DIR/talos_image.auto.tfvars" ]]; then
  echo "Missing $TFVARS_DIR/talos_image.auto.tfvars" >&2
  echo "Copy talos_image.auto.tfvars.example and adjust versions" >&2
  exit 1
fi

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
if [[ ! -s "$SNAPSHOT" ]]; then
  echo "etcd snapshot failed" >&2
  exit 1
fi

echo "Checking Longhorn volume health"
if ! kubectl -n longhorn-system get volumes.longhorn.io >/tmp/longhorn_volumes; then
  echo "Failed to query Longhorn volumes" >&2
  exit 1
fi
# Fail if any volume robustness is not Healthy
if grep -E "Degraded|Faulted" /tmp/longhorn_volumes >/dev/null; then
  cat /tmp/longhorn_volumes >&2
  echo "Longhorn volumes are not healthy" >&2
  exit 1
fi

CONTROL=$(echo "$INFO" | jq -r '.state.sequence[0]')

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
