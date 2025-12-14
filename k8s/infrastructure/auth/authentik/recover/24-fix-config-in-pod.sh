#!/bin/bash
# EMERGENCY WORKAROUND: Fix pg_hba.conf and pg_ident.conf directly in the running pod
# This avoids multi-attach issues by modifying files in-place
#
# ⚠️  WARNING: This is NOT the recommended approach. CNPG manages these files and may overwrite changes.
#     - pg_hba.conf: MUST be configured via Cluster spec (postgresql.pg_hba)
#     - pg_ident.conf: CNPG automatically adds fixed rule; manual edits may be overwritten
#     Use this script only as a last resort if cluster cannot start without immediate fixes.

set -e

NAMESPACE="auth"
POD_NAME="authentik-postgresql-1"
CONTAINER="postgres"
PGDATA="/var/lib/postgresql/data/pgdata"

echo "=== FIXING POSTGRESQL CONFIG IN RUNNING POD ==="
echo ""

# Check if pod is running
if ! kubectl get pod "$POD_NAME" -n "$NAMESPACE" | grep -q Running; then
  echo "ERROR: Pod $POD_NAME is not running"
  exit 1
fi

echo "=== Step 1: Checking current pg_hba.conf ==="
kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- cat "$PGDATA/pg_hba.conf" | grep "^local" || echo "No local rules found"

echo ""
echo "=== Step 2: Checking current pg_ident.conf ==="
kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- cat "$PGDATA/pg_ident.conf"

echo ""
echo "=== Step 3: Backing up config files ==="
TIMESTAMP=$(date +%s)
kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- bash -c "cp $PGDATA/pg_hba.conf $PGDATA/pg_hba.conf.backup-$TIMESTAMP"
kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- bash -c "cp $PGDATA/pg_ident.conf $PGDATA/pg_ident.conf.backup-$TIMESTAMP"
echo "✓ Backups created"

echo ""
echo "=== Step 4: Ensuring pg_ident.conf has postgres->postgres mapping ==="
# Check if mapping exists
if ! kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- grep -q "^local[[:space:]]*postgres[[:space:]]*postgres" "$PGDATA/pg_ident.conf" 2>/dev/null; then
  echo "Adding postgres->postgres mapping to pg_ident.conf..."
  # Insert before USER-DEFINED RULES
  kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- bash -c "
    awk '/^# USER-DEFINED RULES/ {print \"local postgres postgres\"}1' $PGDATA/pg_ident.conf > /controller/tmp/pg_ident.conf.tmp && \
    mv /controller/tmp/pg_ident.conf.tmp $PGDATA/pg_ident.conf
  "
  echo "✓ Mapping added"
else
  echo "✓ Mapping already exists in pg_ident.conf"
fi

echo ""
echo "=== Step 5: Adding temporary trust rule to pg_hba.conf ==="
# Add trust rule BEFORE peer rule (PostgreSQL uses first match)
if ! kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- grep -q "^# Temporary trust rule for recovery" "$PGDATA/pg_hba.conf" 2>/dev/null; then
  echo "Adding temporary trust rule..."
  kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- bash -c "
    awk '/^# Grant local access/ {print \"# Temporary trust rule for recovery fix\"; print \"local all all trust\"}1' $PGDATA/pg_hba.conf > /controller/tmp/pg_hba.conf.tmp && \
    mv /controller/tmp/pg_hba.conf.tmp $PGDATA/pg_hba.conf
  "
  echo "✓ Trust rule added"
else
  echo "✓ Trust rule already exists"
fi

echo ""
echo "=== Step 6: Verifying updated configuration ==="
echo "Updated pg_hba.conf local rules:"
kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- grep "^local" "$PGDATA/pg_hba.conf" || echo "No local rules"

echo ""
echo "Updated pg_ident.conf local mappings:"
kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- grep "^local" "$PGDATA/pg_ident.conf" || echo "No local mappings"

echo ""
echo "=== Step 7: Reloading PostgreSQL configuration ==="
# Try to reload config without restart
if kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- bash -c "pg_ctl reload -D $PGDATA" 2>/dev/null; then
  echo "✓ Configuration reloaded (no restart needed)"
else
  echo "⚠️  Could not reload config, PostgreSQL will need restart"
  echo "Deleting pod to force restart..."
  kubectl delete pod "$POD_NAME" -n "$NAMESPACE"
  echo "Waiting for pod to restart..."
  kubectl wait --for=condition=ready --timeout=300s pod/"$POD_NAME" -n "$NAMESPACE" || {
    echo "⚠️  Pod did not become ready in time"
    kubectl get pod "$POD_NAME" -n "$NAMESPACE"
  }
fi

echo ""
echo "=== CONFIG FIX COMPLETE ==="
echo "pg_hba.conf and pg_ident.conf have been updated."
echo "PostgreSQL should now accept peer authentication for the postgres user."
echo ""
echo "Next step: Run the database alignment script:"
echo "  ./22-align-database-script.sh"

