#!/usr/bin/env bash
set -euo pipefail

# Require yq and awk to be installed
command -v yq >/dev/null 2>&1 || { echo >&2 "❌ yq is required (https://github.com/mikefarah/yq)"; exit 1; }
command -v awk >/dev/null 2>&1 || { echo >&2 "❌ awk is required but not found."; exit 1; }

# Check yq version is v4+
echo "🔎 Checking yq version..."
if ! yq --version 2>/dev/null | grep -q 'version v4'; then
    echo "❌ This script requires yq version 4. Please upgrade."
    echo "   (https://github.com/mikefarah/yq#install)"
    exit 1
fi
echo "✅ yq version 4 detected."

INPUT="${1:-build.yaml}"
OUTPUT="${2:-mastodon.cleaned.yaml}"
TMP_OUTPUT="${OUTPUT}.tmp"

echo "📝 Reading from $INPUT and writing to $OUTPUT"

# ==============================================================================
# PRE-FLIGHT CHECK
# ==============================================================================
echo "🔎 Performing pre-flight check for malformed YAML with duplicate keys..."
if ! awk '
    BEGIN { doc_num = 1 }
    /^---/ {
        doc_num++;
        delete seen_keys;
        next
    }
    /^\S/ {
        key = $1;
        sub(/:$/, "", key);
        if (seen_keys[key]++) {
            print "❌ FATAL: Duplicate key '\''" key "'\'' found in document #" doc_num " near line " FNR "." > "/dev/stderr";
            exit 1;
        }
    }
' "$INPUT"; then
    echo "🔥 Pre-flight check failed. Please fix the duplicate keys in the input file before proceeding."
    exit 1
fi
echo "✅ Pre-flight check passed."

cp "$INPUT" "$OUTPUT"

# ==============================================================================
# CLEANING STEPS
# Each step now writes to a temporary file and then replaces the main output file.
# This avoids any issues with in-place editing (-i).
# ==============================================================================

echo "🧹 Step 1: Purging all Helm-related labels, annotations, and other cruft..."
yq ea '
  del(.metadata.annotations) |
  del(.status) |
  del(.metadata.creationTimestamp) |
  del(.spec.template.metadata.creationTimestamp) |
  ( .metadata.labels |= with_entries(select(.key | test("helm.sh/|app.kubernetes.io/") | not)) ) |
  ( .spec.selector.matchLabels |= with_entries(select(.key | test("helm.sh/|app.kubernetes.io/") | not)) )
' "$OUTPUT" > "$TMP_OUTPUT" && mv "$TMP_OUTPUT" "$OUTPUT"


echo "🧹 Step 2: Standardizing all resources to the 'mastodon' namespace..."
yq ea '
  select(.kind | test("Namespace|ClusterRole|ClusterRoleBinding|ClusterIssuer|ClusterSecretStore") | not) |=
  (.metadata.namespace = "mastodon")
' "$OUTPUT" > "$TMP_OUTPUT" && mv "$TMP_OUTPUT" "$OUTPUT"


echo "🧹 Step 3: Removing invalid 'spec.selector' fields from non-workload resources..."
yq ea '
  select(.kind | test("ServiceAccount|ConfigMap|Secret|Role|RoleBinding|PersistentVolumeClaim|ExternalSecret|SecretStore|Certificate|HTTPRoute|Ingress|Namespace")) |=
  del(.spec.selector)
' "$OUTPUT" > "$TMP_OUTPUT" && mv "$TMP_OUTPUT" "$OUTPUT"


echo "🧹 Step 4: Replacing 'masthelm' with 'mastodon' in names and references..."
# sed does not have an eval-all equivalent, but its in-place can also be quirky. This is safer.
sed 's/masthelm/mastodon/g' "$OUTPUT" > "$TMP_OUTPUT" && mv "$TMP_OUTPUT" "$OUTPUT"


echo "🧹 Step 5: Updating deprecated API versions..."
sed 's|apiVersion: extensions/v1beta1|apiVersion: apps/v1|g' "$OUTPUT" > "$TMP_OUTPUT" && mv "$TMP_OUTPUT" "$OUTPUT"
sed 's|apiVersion: networking.k8s.io/v1beta1|apiVersion: networking.k8s.io/v1|g' "$OUTPUT" > "$TMP_OUTPUT" && mv "$TMP_OUTPUT" "$OUTPUT"


echo "🧹 Step 6: Synchronizing workload selectors with their pod template labels..."
yq ea '
  select(.kind | test("Deployment|StatefulSet|DaemonSet|Job")) |=
  (.spec.selector.matchLabels = .spec.template.metadata.labels)
' "$OUTPUT" > "$TMP_OUTPUT" && mv "$TMP_OUTPUT" "$OUTPUT"


echo "🧹 Step 7: Final cleanup of empty objects, arrays, or null values..."
yq ea 'del(.. | select(. == null or . == {} or . == []))' "$OUTPUT" > "$TMP_OUTPUT" && mv "$TMP_OUTPUT" "$OUTPUT"


# ==============================================================================
# FINAL VALIDATION
# ==============================================================================
echo "🔎 Validating final output file..."
# Only parse to ensure well-formed YAML; no in-place mutation
if yq eval '.' "$OUTPUT" >/dev/null 2>&1; then
    echo "✅ Cleaned manifest saved to $OUTPUT"
else
    echo "❌ Output YAML file ($OUTPUT) is malformed. Review transformations and the original file for syntax errors."
    exit 1
fi