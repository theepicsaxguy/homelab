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

# Create temporary directory for build outputs
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

# Convert newline-separated string to array
mapfile -t DIRS <<< "$CHANGED_DIRS"

# Validate array is not empty
if [ ${#DIRS[@]} -eq 0 ]; then
    echo "❌ No valid kustomization files found. Aborting validation."
    exit 4
fi

echo "Found ${#DIRS[@]} directories to validate"

# Function to check available system resources
check_resources() {
    local cpu_count=$(nproc --all)
    local mem_free=$(free -m | grep "Mem" | awk '{print $4}')

    # Dynamically adjust parallelism
    if [ "$cpu_count" -lt 4 ] || [ "$mem_free" -lt 500 ]; then
        echo "⚠️ Low system resources detected. Adjusting parallelism."
        echo 2
    else
        echo 4
    fi
}

PARALLEL_JOBS=$(check_resources)
echo "Using parallelism level: $PARALLEL_JOBS"

# Pre-build kustomizations and store in temp files
echo "🔨 Building kustomizations..."
for dir in "${DIRS[@]}"; do
    output_file="$TEMP_DIR/$(echo "$dir" | tr '/' '_').yaml"
    echo "Building $dir -> $output_file"
    if ! kustomize build "$dir" --enable-helm > "$output_file" 2>/dev/null; then
        echo "❌ Failed to build kustomization in $dir"
        continue
    fi
done

# Get list of ArgoCD applications for diff checks
ARGO_APPS=$(argocd app list -o json | jq -r '.[].metadata.name' 2>/dev/null || echo "")

# Validate built files in parallel
echo "🔍 Validating YAML files..."
export TEMP_DIR
export KUBERNETES_VERSION=1.32.0

find "$TEMP_DIR" -type f -name "*.yaml" | parallel --jobs "$PARALLEL_JOBS" --halt soon,fail=1 '
    file="{}";
    dir=$(basename "$file" .yaml | tr "_" "/");
    echo "[$dir] 🔍 Validating YAML...";
    if ! kubeconform -strict -ignore-missing-schemas -summary -kubernetes-version "$KUBERNETES_VERSION" "$file"; then
        echo "❌ Validation failed for $dir";
        exit 1;
    fi;
'

# Only run ArgoCD diff checks if we have access to ArgoCD
if [ -n "$ARGO_APPS" ]; then
    echo "📊 Running ArgoCD diff checks..."
    for dir in "${DIRS[@]}"; do
        manifest="$TEMP_DIR/$(echo "$dir" | tr '/' '_').yaml"
        if [ -f "$manifest" ]; then
            app_name=$(yq e ".metadata.name" "$manifest" 2>/dev/null)

            # Debugging: Print the extracted app name
            echo "App name extracted: $app_name"

            if [[ " $ARGO_APPS " =~ " $app_name " ]]; then
                echo "Checking diff for $app_name..."
                if ! argocd app diff "$app_name" --local "$manifest" > /dev/null 2>&1; then
                    echo "⚠️ Diff detected for $app_name"
                else
                    echo "✅ No diff for $app_name"
                fi
            else
                echo "❌ $app_name not found in ArgoCD apps."
            fi
        fi
    done
fi


echo "✅ Validation completed successfully!"
exit 0
