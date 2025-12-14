#!/bin/bash
# Complete solution: Fix authentication and align database with CNPG secret
# This script modifies config files directly in the running pod, then aligns the database

set -e

NAMESPACE="auth"
POD_NAME="authentik-postgresql-1"

echo "=== COMPLETE FIX: AUTHENTICATION + DATABASE ALIGNMENT ==="
echo ""

# Step 1: Fix config files directly in the running pod
echo "=== Step 1: Fixing PostgreSQL config files in running pod ==="
if [ -f "$(dirname "$0")/24-fix-config-in-pod.sh" ]; then
  bash "$(dirname "$0")/24-fix-config-in-pod.sh"
else
  echo "ERROR: Config fix script not found: 24-fix-config-in-pod.sh"
  exit 1
fi

# Step 2: Wait for pod to be ready (in case it was restarted)
echo ""
echo "=== Step 2: Ensuring pod is ready ==="
if kubectl wait --for=condition=ready --timeout=300s pod/"$POD_NAME" -n "$NAMESPACE" 2>/dev/null; then
  echo "✓ Pod is ready"
else
  echo "⚠️  Pod did not become ready in time, checking status..."
  kubectl get pod "$POD_NAME" -n "$NAMESPACE"
  echo "Continuing with database alignment anyway..."
fi

# Step 3: Align database using the script
echo ""
echo "=== Step 3: Aligning database with CNPG secret ==="
if [ -f "$(dirname "$0")/22-align-database-script.sh" ]; then
  bash "$(dirname "$0")/22-align-database-script.sh"
else
  echo "⚠️  Alignment script not found, skipping database alignment"
  echo "You can run it manually: $(dirname "$0")/22-align-database-script.sh"
fi

echo ""
echo "=== FIX COMPLETE ==="
echo "Authentication and database should now be aligned with CNPG expectations."
echo "Check cluster status:"
echo "  kubectl get cluster authentik-postgresql -n auth"

