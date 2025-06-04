#!/usr/bin/env bash
set -euo pipefail

ROOT="$(dirname "$0")/.."
PATH="$ROOT/tests/fake-bin:$PATH"

bash "$ROOT/scripts/upgrade_talos.sh" 0

SNAPSHOT=$(ls -1t etcd-snapshot-ctrl-00-*.db | head -n 1)
if [[ ! -f "$SNAPSHOT" ]]; then
  echo "Snapshot file not created" >&2
  exit 1
fi
rm "$SNAPSHOT"

echo "Test completed"
