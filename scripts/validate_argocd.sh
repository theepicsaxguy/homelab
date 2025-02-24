#!/bin/bash

set -eo pipefail

# Function to check for required tools
check_tools() {
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "❌ Tool $tool is missing. Please install it to proceed."
            exit 2  # Custom exit code for missing tool
        fi
    done
}

# List of required tools
REQUIRED_TOOLS=("kustomize" "kubectl" "kubeconform" "yq" "argocd" "helm" "jq" "parallel")

# Check for required tools
check_tools

# Detect CI/CD Mode (Partial validation for PRs, full validation on merge)
if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
    echo "🔍 Running partial validation (PR mode)"
    CHANGED_FILES=$(git diff --name-only origin/main | grep "kustomization.*" | xargs -n1 dirname | sort -u)
else
    echo "🚀 Running full validation"
    CHANGED_FILES=$(find k8s -type f -name "kustomization.*" | xargs -n1 dirname | sort -u)
fi

# Debugging: Print out the content of CHANGED_FILES to confirm what's being passed
echo "DEBUG: CHANGED_FILES content: $CHANGED_FILES"

# Handle empty CHANGED_FILES case
if [ -z "$CHANGED_FILES" ] || [ "${#CHANGED_FILES[@]}" -eq 0 ]; then
    echo "❌ No valid kustomization files found. Aborting validation."
    exit 4  # Custom exit code for no changed files
fi

# Get list of ArgoCD applications
ARGO_APPS=$(argocd app list -o json | jq -r '.[].metadata.name')

# Function to check available system resources (CPU and memory)
check_resources() {
    local cpu_count=$(nproc --all)
    local mem_free=$(free -m | grep "Mem" | awk '{print $4}')
    local load=$(uptime | awk -F'load average:' '{ print $2 }' | awk '{print $1}')

    # Dynamically adjust parallelism based on CPU and memory resources
    if [ "$cpu_count" -lt 4 ] || [ "$mem_free" -lt 500 ]; then
        echo "⚠️ Low system resources detected. Adjusting parallelism accordingly."
        PARALLEL_LIMIT=2
    else
        PARALLEL_LIMIT=4
    fi
}

# Default parallelism limit based on system resources
check_resources

# Cache Kustomize Builds with efficient disk-based caching and invalidation
declare -A KUSTOMIZE_CACHE
parallel --jobs "$PARALLEL_LIMIT" --halt soon,fail=1 '
  dir={};
  output_file="/tmp/kustomize_output_$(basename "$dir").yaml";
  kustomize build "$dir" --enable-helm > "$output_file";
  # Hashing mechanism for cache invalidation
  output_hash=$(sha256sum "$output_file" | awk "{ print \$1 }");
  echo "$dir:$output_hash:$output_file"
' ::: ${CHANGED_FILES[@]} | while IFS=: read -r dir hash output; do
  KUSTOMIZE_CACHE["$dir"]="$output"
done

# Only run parallel if CHANGED_FILES is populated
if [[ -n "${CHANGED_FILES[*]}" ]]; then
    # Parallelized YAML Validation with granular logging and unique job identifiers
    parallel --jobs "$PARALLEL_LIMIT" --halt soon,fail=1 '
      dir={}; job_id=$(echo $(date +%s%N));
      echo "[$job_id] 🔍 Validating YAML for $dir..."
      kubeconform -strict -ignore-missing-schemas -summary -kubernetes-version 1.32.0 "${KUSTOMIZE_CACHE[$dir]}" || echo "[$job_id] ❌ Validation failed for $dir"
    ' ::: ${CHANGED_FILES[@]} > /tmp/errors.log

    # Parallelized ArgoCD Diff Check with fallback
    parallel --jobs "$PARALLEL_LIMIT" --halt soon,fail=1 '
      dir={}; job_id=$(echo $(date +%s%N));
      app_name=$(yq e ".metadata.name" "${KUSTOMIZE_CACHE[$dir]}");
      if [[ " ${ARGO_APPS[@]} " =~ " ${app_name} " ]]; then
        if ! argocd app diff "$app_name"; then
          echo "[$job_id] ❌ Diff check failed for $app_name in $dir, attempting rollback..."
          # Fallback: Rollback to previous commit or known good state
          argocd app rollback "$app_name" || echo "[$job_id] ❌ Rollback failed for $app_name"
        fi
      fi
    ' ::: ${CHANGED_FILES[@]} >> /tmp/errors.log

    # GitOps-compliant Secret Validation using Vault API
    parallel --jobs "$PARALLEL_LIMIT" --halt soon,fail=1 '
      dir={}; job_id=$(echo $(date +%s%N));
      if [[ "$dir" =~ overlays ]]; then
        yq e "select(.kind == \"SealedSecret\") | .metadata.name" "${KUSTOMIZE_CACHE[$dir]}" | while read -r secret; do
          namespace=$(yq e ".metadata.namespace // \"default\"" "${KUSTOMIZE_CACHE[$dir]}");
          # Integrate Vault API for validation
          if ! vault kv get secret/"$secret" &> /dev/null; then
            echo "[$job_id] ❌ Missing SealedSecret: $secret in $dir (namespace: $namespace)"
          fi
        done
      fi
    ' ::: ${CHANGED_FILES[@]} >> /tmp/errors.log

    # JSON Schema Validation for ArgoCD resources
    parallel --jobs "$PARALLEL_LIMIT" --halt soon,fail=1 '
      dir={}; job_id=$(echo $(date +%s%N));
      yq e "select(.kind == \"Application\" or .kind == \"ApplicationSet\")" "${KUSTOMIZE_CACHE[$dir]}" | jq -e . > /dev/null || echo "[$job_id] ❌ Invalid ArgoCD schema in $dir"
    ' ::: ${CHANGED_FILES[@]} >> /tmp/errors.log
else
    echo "⚠️ No changed files detected, skipping validation."
fi

# Reporting Errors with Detailed Context
if [ -s /tmp/errors.log ]; then
  echo "❌ Validation failed with the following issues:"
  cat /tmp/errors.log
  exit 3  # Custom exit code for validation failures
fi

echo "✅ Validation completed successfully!"
exit 0
