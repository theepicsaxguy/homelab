#!/usr/bin/env bash
# Usage: hubble-check.sh <namespace> [namespace2 ...]
# Checks for Cilium-dropped flows in one or more namespaces via Hubble relay.
# Verifies connectivity before trusting empty DROPPED results.

set -euo pipefail

NAMESPACES=("$@")
if [[ ${#NAMESPACES[@]} -eq 0 ]]; then
  echo "Usage: hubble-check.sh <namespace> [namespace2 ...]" >&2
  exit 1
fi

HUBBLE_PORT=4245
RELAY_SVC=hubble-relay
RELAY_NS=kube-system

# Start port-forward
kubectl -n "$RELAY_NS" port-forward "svc/$RELAY_SVC" "${HUBBLE_PORT}:80" &>/tmp/hubble-pf.log &
PF_PID=$!
trap 'kill $PF_PID 2>/dev/null; exit' EXIT INT TERM

sleep 3

# Sanity check — confirm Hubble is reachable and returning flows
echo "=== Hubble status ==="
hubble status 2>&1

for NS in "${NAMESPACES[@]}"; do
  echo ""
  echo "=== Dropped flows: $NS ==="
  hubble observe --namespace "$NS" --verdict DROPPED --last 100 2>&1

  echo ""
  echo "=== Recent flows (sanity check): $NS ==="
  hubble observe --namespace "$NS" --last 5 2>&1
done
