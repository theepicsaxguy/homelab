#!/usr/bin/env bash
set -euo pipefail

ROOT="$(dirname "$0")/.."
PATH="$ROOT/tests/fake-bin:$PATH"

bash "$ROOT/scripts/upgrade_talos.sh" 0

echo "Test completed"
