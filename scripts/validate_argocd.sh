#!/bin/bash
set -eo pipefail

# Ensure Kubernetes version is set once and exported
get_kubernetes_version() {
    local version
    version=$(kubectl version --client -o=json 2>/dev/null | jq -r .clientVersion.gitVersion || echo "")
    if [[ -z "$version" ]]; then
        echo '{"timestamp": "'$(date --iso-8601=seconds)'", "category": "env", "message": "Failed to retrieve Kubernetes version. Ensure kubectl is installed and configured."}'
        exit 1
    fi
    echo "$version" | sed 's/^v//'
}
export KUBERNETES_VERSION="${KUBERNETES_VERSION:-$(get_kubernetes_version)}"

# List of required tools
REQUIRED_TOOLS=("kustomize" "kubectl" "kubeconform" "yq" "argocd" "helm" "jq" "parallel" "curl")
check_tools() {
    local missing=()
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done
    if [ ${#missing[@]} -ne 0 ]; then
        echo '{"timestamp": "'$(date --iso-8601=seconds)'", "category": "env", "message": "Missing required tools: '"${missing[*]}"'. Install them before running."}'
        exit 2
    fi
}
check_tools

# Create temporary directory for builds
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Error log file
ERROR_LOG="validation_errors.json"
: > "$ERROR_LOG"

# Counters for summary
KUSTOMIZE_FAIL=0
YAML_FAIL=0
ARGO_FAIL=0
URL_FAIL=0

# JSON logging function
log_error() {
    local msg="$1"
    local category="$2"
    local timestamp
    timestamp=$(date --iso-8601=seconds)
    local entry
    entry=$(jq -n --arg ts "$timestamp" --arg cat "$category" --arg msg "$msg" '{timestamp: $ts, category: $cat, message: $msg}')
    echo "$entry"
    echo "$entry" >> "$ERROR_LOG"
    case "$category" in
        kustomize) ((KUSTOMIZE_FAIL++)) ;;
        yaml) ((YAML_FAIL++)) ;;
        argocd) ((ARGO_FAIL++)) ;;
        url) ((URL_FAIL++)) ;;
    esac
}
export -f log_error

# Set PARALLEL_JOBS: if not a number, set to 1
if ! [[ "$PARALLEL_JOBS" =~ ^[0-9]+$ ]]; then
    PARALLEL_JOBS=1
fi
echo '{"timestamp": "'$(date --iso-8601=seconds)'", "category": "info", "message": "Using parallel jobs: '"$PARALLEL_JOBS"'."}'

# Find all directories with a kustomization file
ALL_DIRS=$(find k8s -type f -name "kustomization.*" | xargs -n1 dirname | sort -u)
mapfile -t DIRS <<< "$ALL_DIRS"

if [ ${#DIRS[@]} -eq 0 ]; then
    echo '{"timestamp": "'$(date --iso-8601=seconds)'", "category": "info", "message": "No kustomization files found. Exiting validation."}'
    exit 0
fi
echo '{"timestamp": "'$(date --iso-8601=seconds)'", "category": "info", "message": "Found '"${#DIRS[@]}"' directories to validate."}'

# Partition directories into base and overlay
base_dirs=()
overlay_dirs=()
for dir in "${DIRS[@]}"; do
    if [[ "$dir" == *"/base/"* ]]; then
        base_dirs+=("$dir")
    else
        overlay_dirs+=("$dir")
    fi
done

# Validate URLs in a kustomization file
check_kustomization_urls() {
    local dir=$1
    local urls
    urls=$(grep -o 'http[s]*://[^"]*' "$dir/kustomization.yaml" || true)
    if [ -n "$urls" ]; then
        for url in $urls; do
            if ! curl --silent --head --fail "$url" > /dev/null; then
                log_error "Unreachable URL: $url in directory $dir" "url"
            fi
        done
    fi
}
export -f check_kustomization_urls

# Build and validate a directory
build_and_validate() {
    local dir=$1
    check_kustomization_urls "$dir"
    local output_file="$TEMP_DIR/$(echo "$dir" | tr "/" "_").yaml"
    echo "Building $dir -> $output_file"
    if ! build_output=$(kustomize build "$dir" --enable-helm 2>&1); then
        log_error "Failed to build kustomization in directory $dir: $build_output" "kustomize"
        exit 1
    else
        if echo "$build_output" | grep -q "environment:"; then
            log_error "Build output for $dir contains environment errors: $build_output" "kustomize"
            exit 1
        fi
        echo "$build_output" > "$output_file"
    fi
    echo "Validating YAML in $dir"
    if ! kubeconform -strict -ignore-missing-schemas -summary -kubernetes-version "$KUBERNETES_VERSION" "$output_file" -schema-location default -schema-location "https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds"; then
        log_error "YAML validation failed in directory $dir" "yaml"
        exit 1
    fi
}
export -f build_and_validate

# Validate base layers first
if [ ${#base_dirs[@]} -gt 0 ]; then
    echo '{"timestamp": "'$(date --iso-8601=seconds)'", "category": "info", "message": "Validating base directories."}'
    parallel --halt now,fail=1 --jobs "$PARALLEL_JOBS" build_and_validate ::: "${base_dirs[@]}"
fi

# Validate overlay/production directories
if [ ${#overlay_dirs[@]} -gt 0 ]; then
    echo '{"timestamp": "'$(date --iso-8601=seconds)'", "category": "info", "message": "Validating overlay/production directories."}'
    parallel --halt now,fail=1 --jobs "$PARALLEL_JOBS" build_and_validate ::: "${overlay_dirs[@]}"
fi

# Validate ApplicationSet structure
APPLICATIONSET_FILE="k8s/infra/applicationset.yaml"
if [ ! -f "$APPLICATIONSET_FILE" ]; then
    log_error "ApplicationSet file '$APPLICATIONSET_FILE' not found. This is required for production integrity." "argocd"
    exit 1
else
    echo "Validating ApplicationSet structure..."
    if ! kubeconform -strict -summary -kubernetes-version "$KUBERNETES_VERSION" "$APPLICATIONSET_FILE"; then
        log_error "Invalid ApplicationSet structure detected in '$APPLICATIONSET_FILE'. Fix before pushing." "argocd"
        exit 1
    fi
fi

# Check ArgoCD health before diff
echo "Checking ArgoCD status..."
ARGOCD_STATUS=$(argocd app list -o json || true)
if [[ -z "$ARGOCD_STATUS" ]]; then
    log_error "ArgoCD API is unreachable. Fix connectivity before running diffs." "argocd"
    exit 1
fi
if echo "$ARGOCD_STATUS" | jq -e '.[].status' | grep -E "ComparisonError|Degraded|Unknown|OutOfSync" >/dev/null; then
    log_error "ArgoCD reports unhealthy applications. Fix before pushing." "argocd"
    exit 1
fi

# Run ArgoCD diffs for all applications (production diff—do not skip)
echo '{"timestamp": "'$(date --iso-8601=seconds)'", "category": "info", "message": "Running ArgoCD diff for all applications."}'
for app in $(argocd app list -o name); do
    manifest=$(argocd app get "$app" -o json | jq -r '.spec.source.path')
    manifest_dir="k8s/$manifest"
    if [ ! -d "$manifest_dir" ]; then
        log_error "Manifest path missing for app '$app' ($manifest_dir). Production diff cannot be skipped." "argocd"
        exit 1
    fi
    DIFF_OUTPUT=$(argocd app diff "$app" --local "$manifest_dir" --refresh 2>&1)
    diff_exit_code=$?
    if [ $diff_exit_code -ne 0 ]; then
        log_error "ArgoCD diff failed for app '$app'. Error: $DIFF_OUTPUT" "argocd"
        exit 1
    elif [[ -n "$DIFF_OUTPUT" ]]; then
        echo '{"timestamp": "'$(date --iso-8601=seconds)'", "category": "info", "message": "ArgoCD diff for app '"$app"' detected changes.", "diff": '"$(echo "$DIFF_OUTPUT" | jq -R -s .)"'}'
    else
        echo '{"timestamp": "'$(date --iso-8601=seconds)'", "category": "info", "message": "No diff detected for app '"$app"'."}'
    fi
done

echo "======== VALIDATION SUMMARY ========"
echo "Kustomize build failures: $KUSTOMIZE_FAIL"
echo "YAML validation failures: $YAML_FAIL"
echo "ArgoCD diff failures: $ARGO_FAIL"
echo "Broken URLs: $URL_FAIL"

if [ -s "$ERROR_LOG" ]; then
    echo '{"timestamp": "'$(date --iso-8601=seconds)'", "category": "error", "message": "Validation completed with errors. Review the log below."}'
    cat "$ERROR_LOG"
    exit 1
else
    echo '{"timestamp": "'$(date --iso-8601=seconds)'", "category": "info", "message": "Validation completed successfully."}'
    exit 0
fi
