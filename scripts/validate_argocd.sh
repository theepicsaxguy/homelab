#!/bin/bash

set -eo pipefail

# Function to get the Kubernetes version dynamically
get_kubernetes_version() {
    # Get the client version dynamically using kubectl
    kubectl version --client -o=json | jq -r .clientVersion.gitVersion
}

# Configurable variables
KUBERNETES_VERSION="${KUBERNETES_VERSION:-$(get_kubernetes_version)}"

# Function to check for required tools
check_tools() {
    local missing=()
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        echo "❌ Missing required tools: ${missing[*]}. Install them before running."
        exit 2
    fi
}

# Required tools
REQUIRED_TOOLS=("kustomize" "kubectl" "kubeconform" "yq" "argocd" "helm" "jq" "parallel")
check_tools

# Create temp dir for build outputs
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Detect CI/CD Mode (Partial validation for PRs, full validation on merge)
if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
    echo "🔍 Running partial validation (PR mode)"
    CHANGED_DIRS=$(git diff --name-only origin/main | grep "kustomization.*" | xargs -n1 dirname | sort -u)
else
    echo "🚀 Running full validation"
    CHANGED_DIRS=$(find k8s -type f -name "kustomization.*" | xargs -n1 dirname | sort -u)
fi

mapfile -t DIRS <<< "$CHANGED_DIRS"

if [ ${#DIRS[@]} -eq 0 ]; then
    echo "❌ No valid kustomization files found. Aborting validation."
    exit 4
fi

echo "Found ${#DIRS[@]} directories to validate"

# Dynamic parallelism tuning
PARALLEL_JOBS="${PARALLEL_JOBS:-$(nproc --all)}"
echo "Using parallelism level: $PARALLEL_JOBS"

# Logs for collected errors
ERROR_LOG="validation_errors.log"
> "$ERROR_LOG"

# Function to log errors
log_error() {
    echo "$1" >> "$ERROR_LOG"
}

# Validate and check for missing resources in URLs in kustomizations
check_kustomization_urls() {
    local dir=$1
    echo "🔍 Checking URLs in kustomization for $dir..."

    # Get the list of URLs in the kustomization file(s)
    local urls=$(grep -o 'http[s]*://[^"]*' "$dir/kustomization.yaml")

    if [ -n "$urls" ]; then
        for url in $urls; do
            # Check if the URL is reachable
            if ! curl --silent --head --fail "$url" > /dev/null; then
                log_error "❌ ERROR: URL not reachable: $url in $dir"
            fi
        done
    fi
}

# Pre-build kustomizations **strictly fail on errors**
echo "🔨 Building kustomizations..."
for dir in "${DIRS[@]}"; do
    check_kustomization_urls "$dir"
    output_file="$TEMP_DIR/$(echo "$dir" | tr '/' '_').yaml"
    echo "Building $dir -> $output_file"
    if ! kustomize build "$dir" --enable-helm > "$output_file"; then
        log_error "❌ ERROR: Failed to build kustomization in $dir"
    fi
done

# Get list of ArgoCD applications
ARGO_APPS=$(argocd app list -o json | jq -r '.[].metadata.name' 2>/dev/null || echo "")

# Validate built YAMLs in parallel with **detailed errors**
echo "🔍 Validating YAML files..."
export TEMP_DIR
export KUBERNETES_VERSION

find "$TEMP_DIR" -type f -name "*.yaml" | parallel --jobs "$PARALLEL_JOBS" --halt soon,fail=1 '
    file="{}";
    dir=$(basename "$file" .yaml | tr "_" "/");
    echo "[$dir] 🔍 Validating YAML...";
    if ! kubeconform -strict -ignore-missing-schemas -summary -kubernetes-version "$KUBERNETES_VERSION" "$file" 2>&1; then
        log_error "❌ YAML validation failed in $dir"
    fi;
'

# ArgoCD diff check with **full output** and **validated app names**
if [ -n "$ARGO_APPS" ]; then
    echo "📊 Running ArgoCD diff checks..."
    for dir in "${DIRS[@]}"; do
        manifest="$TEMP_DIR/$(echo "$dir" | tr '/' '_').yaml"
        if [ -f "$manifest" ]; then
            app_name=$(yq e ".metadata.name" "$manifest" 2>/dev/null || echo "")

            # **New Fix: Explicit Validation**
            if [[ -z "$app_name" || ! " $ARGO_APPS " =~ " $app_name " ]]; then
                log_error "❌ ERROR: Unable to find a matching ArgoCD app for $dir ($app_name)"
            else
                echo "🔍 Checking diff for $app_name..."
                if ! DIFF_OUTPUT=$(argocd app diff "$app_name" --local "$manifest" --ignore-extraneous 2>&1); then
                    log_error "⚠️ Diff detected for $app_name: $DIFF_OUTPUT"
                else
                    echo "✅ No diff for $app_name"
                fi
            fi
        fi
    done
fi

# Final log output of all errors encountered
if [ -s "$ERROR_LOG" ]; then
    echo "❌ Validation completed with errors. Please review the log:"
    cat "$ERROR_LOG"
    exit 1
else
    echo "✅ Validation completed successfully!"
    exit 0
fi
