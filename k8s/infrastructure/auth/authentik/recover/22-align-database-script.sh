#!/bin/bash
# Script to align database with CNPG auto-generated secret
# Run this script to execute SQL commands directly in the running pod
#
# PREREQUISITE: The CNPG Cluster must have enableSuperuserAccess: true
# This script uses 'psql -U postgres' which requires superuser access.
# Without enableSuperuserAccess, the postgres user has no password and
# peer authentication will fail.

set -e

NAMESPACE="auth"
POD_NAME="authentik-postgresql-1"
CONTAINER="postgres"

echo "=== ALIGNING DATABASE WITH CNPG AUTO-GENERATED SECRET ==="
echo ""

# Get CNPG secret values
APP_USER=$(kubectl get secret authentik-postgresql-app -n "$NAMESPACE" -o jsonpath='{.data.username}' | base64 -d)
APP_PASSWORD=$(kubectl get secret authentik-postgresql-app -n "$NAMESPACE" -o jsonpath='{.data.password}' | base64 -d)
APP_DB=$(kubectl get secret authentik-postgresql-app -n "$NAMESPACE" -o jsonpath='{.data.dbname}' | base64 -d)

echo "CNPG expects:"
echo "  User: $APP_USER"
echo "  Database: $APP_DB"
echo ""

# Check if pod is running
if ! kubectl get pod "$POD_NAME" -n "$NAMESPACE" | grep -q Running; then
  echo "ERROR: Pod $POD_NAME is not running"
  exit 1
fi

echo "=== Step 1: Checking current database state ==="
echo "Databases:"
# Note: This requires enableSuperuserAccess: true in the Cluster manifest
# If this fails with "Peer authentication failed", check that enableSuperuserAccess is enabled
kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- psql -U postgres -d postgres -c "\l" || {
  echo "ERROR: Cannot connect to PostgreSQL as postgres user"
  echo "HINT: Ensure the Cluster manifest has 'enableSuperuserAccess: true'"
  echo "      After enabling, wait for the cluster to reconcile before retrying"
  exit 1
}

echo ""
echo "Users:"
kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- psql -U postgres -d postgres -c "\du" || true

echo ""
echo "=== Step 2: Ensuring app database exists ==="
DB_EXISTS=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- psql -U postgres -d postgres -t -c "SELECT 1 FROM pg_database WHERE datname='$APP_DB';" | xargs || echo "0")
if [ "$DB_EXISTS" != "1" ]; then
  echo "Creating database $APP_DB..."
  kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- psql -U postgres -d postgres -c "CREATE DATABASE $APP_DB;"
  echo "✓ Database $APP_DB created"
else
  echo "✓ Database $APP_DB already exists"
fi

echo ""
echo "=== Step 3: Ensuring app user exists with CNPG password ==="
USER_EXISTS=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- psql -U postgres -d postgres -t -c "SELECT 1 FROM pg_roles WHERE rolname='$APP_USER';" | xargs || echo "0")
if [ "$USER_EXISTS" != "1" ]; then
  echo "Creating user $APP_USER..."
  kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- psql -U postgres -d postgres -c "CREATE USER $APP_USER WITH PASSWORD '$APP_PASSWORD';"
  echo "✓ User $APP_USER created"
else
  echo "Updating password for user $APP_USER to match CNPG secret..."
  kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- psql -U postgres -d postgres -c "ALTER USER $APP_USER WITH PASSWORD '$APP_PASSWORD';"
  echo "✓ Password updated for user $APP_USER"
fi

echo ""
echo "=== Step 4: Ensuring app user owns app database ==="
kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- psql -U postgres -d postgres -c "ALTER DATABASE $APP_DB OWNER TO $APP_USER;"
echo "✓ Database $APP_DB ownership set to $APP_USER"

echo ""
echo "=== Step 5: Granting necessary permissions ==="
kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- psql -U postgres -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE $APP_DB TO $APP_USER;"
kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- psql -U postgres -d "$APP_DB" -c "GRANT ALL ON SCHEMA public TO $APP_USER;"
echo "✓ Permissions granted"

echo ""
echo "=== Step 6: Verifying final state ==="
echo "Database owner:"
kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- psql -U postgres -d postgres -c "SELECT datname, pg_catalog.pg_get_userbyid(datdba) as owner FROM pg_database WHERE datname='$APP_DB';"

echo ""
echo "Testing connection with CNPG credentials:"
kubectl exec -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER" -- bash -c "PGPASSWORD='$APP_PASSWORD' psql -U $APP_USER -d $APP_DB -c 'SELECT current_user, current_database();'" && {
  echo "✓ User can connect with password from CNPG secret"
} || {
  echo "⚠️  WARNING: User cannot connect with password auth"
}

echo ""
echo "=== ALIGNMENT COMPLETE ==="
echo "Database and user are now configured to match CNPG secret."
echo "CNPG should be able to connect and complete recovery."

