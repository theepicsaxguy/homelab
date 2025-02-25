#!/bin/bash

set -eo pipefail

# Detect execution environment (Local vs CI/CD)
IS_CI=${CI:-false}

# Ensure Kubernetes version is set **once** and exported
get_kubernetes_version() {
    local version
    version=$(kubectl version --client -o=json 2>/dev/null | jq -r .clientVersion.gitVersion || echo "")

    if [[ -z "$version" ]]; then
        echo "ERROR: Failed to retrieve Kubernetes version. Ensure kubectl is installed and configured." >&2
        exit 1
    fi

    echo "$version" | sed 's/^v//'
}

export KUBERNETES_VERSION="${KUBERNETES_VERSION:-$(get_kubernetes_version)}"

# Required tools
REQUIRED_TOOLS=("kustomize" "kubectl" "kubeconform" "yq" "argocd" "helm" "jq" "parallel" "curl")

# Check for required tools
check_tools() {
    local missing=()
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        echo "ERROR: Missing required tools: ${missing[*]}. Install them before running." >&2
        exit 2
    fi
}

check_tools

# Create temp directory for builds
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Define log file for errors (Thread-safe with flock)
ERROR_LOG="validation_errors.log"
> "$ERROR_LOG"

# Counters for summary
KUSTOMIZE_FAIL=0
YAML_FAIL=0
ARGO_FAIL=0
URL_FAIL=0

# Thread-safe error logging function
log_error() {
    local msg="$1"
    local category="$2"

    (
        flock -w 5 200
        echo "$msg" >> "$ERROR_LOG"
    ) 200>"$ERROR_LOG.lock"

    case "$category" in
        kustomize) ((KUSTOMIZE_FAIL++)) ;;
        yaml) ((YAML_FAIL++)) ;;
        argocd) ((ARGO_FAIL++)) ;;
        url) ((URL_FAIL++)) ;;
    esac
}

export -f log_error

# Detect PR mode vs full validation
if [ "$IS_CI" == "true" ] && [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
    echo "Running partial validation (PR mode)"
    CHANGED_DIRS=$(git diff --name-only origin/main | grep "kustomization.*" | xargs -n1 dirname | sort -u)
else
    echo "Running full validation"
    CHANGED_DIRS=$(find k8s -type f -name "kustomization.*" | xargs -n1 dirname | sort -u)
fi

mapfile -t DIRS <<< "$CHANGED_DIRS"

if [ ${#DIRS[@]} -eq 0 ]; then
    echo "No kustomization files found. Exiting validation."
    exit 0
fi

echo "Found ${#DIRS[@]} directories to validate"

# Set parallelism with a safe default
PARALLEL_JOBS="${PARALLEL_JOBS:-$(nproc --all)}"
if ! [[ "$PARALLEL_JOBS" =~ ^[0-9]+$ ]] || [ "$PARALLEL_JOBS" -le 0 ]; then
    echo "WARNING: Invalid parallel job count '$PARALLEL_JOBS'. Defaulting to 1."
    PARALLEL_JOBS=1
fi

echo "Using parallel jobs: $PARALLEL_JOBS"

# Validate URLs in kustomizations
check_kustomization_urls() {
    local dir=$1
    echo "Checking URLs in kustomization for $dir..."
    local urls
    urls=$(grep -o 'http[s]*://[^"]*' "$dir/kustomization.yaml" || true)

    if [ -n "$urls" ]; then
        for url in $urls; do
            if ! curl --silent --head --fail "$url" > /dev/null; then
                log_error "Unreachable URL: $url in $dir" "url"
            fi
        done
    fi
}

export -f check_kustomization_urls

# Build kustomizations
echo "Building kustomizations..."
parallel --jobs "$PARALLEL_JOBS" '
    dir={};
    check_kustomization_urls "$dir";
    output_file="$TEMP_DIR/$(echo "$dir" | tr "/" "_").yaml";
    echo "Building $dir -> $output_file";
    if ! kustomize build "$dir" --enable-helm > "$output_file"; then
        log_error "Failed to build kustomization in $dir" "kustomize"
    fi
' ::: "${DIRS[@]}"

# Validate YAMLs using kubeconform
echo "Validating YAML files..."
find "$TEMP_DIR" -type f -name "*.yaml" | parallel --jobs "$PARALLEL_JOBS" '
    file={};
    dir=$(basename "$file" .yaml | tr "_" "/");
    echo "Validating YAML in $dir...";
    if ! kubeconform -strict -ignore-missing-schemas -summary -kubernetes-version "$KUBERNETES_VERSION" "$file" 2>&1; then
        log_error "YAML validation failed in $dir" "yaml"
    fi;
'

# Retrieve ArgoCD applications list
ARGO_APPS=$(argocd app list -o json | jq -r '.[].metadata.name' | xargs)

# Perform ArgoCD diff checks only on valid apps
if [ -n "$ARGO_APPS" ]; then
    echo "Running ArgoCD diff checks..."
    for dir in "${DIRS[@]}"; do
        manifest="$TEMP_DIR/$(echo "$dir" | tr '/' '_').yaml"
        if [ -f "$manifest" ]; then
            app_name=$(yq e ".metadata.name" "$manifest" 2>/dev/null | xargs)

            if [[ -z "$app_name" || ! " $ARGO_APPS " =~ " $app_name " ]]; then
                log_error "ArgoCD app not found for $dir ($app_name)" "argocd"
            else
                echo "Checking diff for $app_name..."
                DIFF_OUTPUT=$(argocd app diff "$app_name" --local "$manifest" --ignore-extraneous 2>&1 || echo "FAILED")
                if [[ "$DIFF_OUTPUT" == "FAILED" ]]; then
                    log_error "ArgoCD diff failed for $app_name" "argocd"
                elif [[ -n "$DIFF_OUTPUT" ]]; then
                    echo "Diff detected for $app_name:"
                    echo "$DIFF_OUTPUT"
                else
                    echo "No diff for $app_name"
                fi
            fi
        fi
    done
fi

# Print final summary
echo "======== VALIDATION SUMMARY ========"
echo "Kustomize build failures: $KUSTOMIZE_FAIL"
echo "YAML validation failures: $YAML_FAIL"
echo "ArgoCD diff failures: $ARGO_FAIL"
echo "Broken URLs: $URL_FAIL"

if [ -s "$ERROR_LOG" ]; then
    echo "Validation completed with errors. Review the log:"
    cat "$ERROR_LOG"
    exit 1
else
    echo "Validation completed successfully."
    exit 0
fi
