#!/bin/bash
set -euo pipefail

##########################
# Function Declarations  #
##########################

usage() {
    echo "Usage: $0 [-D] [-r] [-o] [-i ignore_dir]... <directory>"
    echo "  -D               Dry run mode (commands will be echoed, not executed)"
    echo "  -r               Process directories recursively (default: non-recursive)"
    echo "  -o               Override existing kustomization.yaml files (force regeneration)"
    echo "  -i ignore_dir    Ignore directory with name 'ignore_dir'. Can be specified multiple times."
    exit 1
}

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "DRY RUN: $*"
    else
        "$@"
    fi
}

check_dependencies() {
    for cmd in kustomize yq helm jq kubectl; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "[ERROR] Missing required dependency: $cmd" >&2
            exit 1
        fi
    done
}

check_create_script() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ ! -x "${SCRIPT_DIR}/create_kustomization.sh" ]]; then
        echo "[ERROR] Missing or non-executable create_kustomization.sh script in ${SCRIPT_DIR}." >&2
        exit 1
    fi
}

check_root_kustomization() {
    KUSTOMIZATION_FILE="${KUSTOMIZE_DIR}/kustomization.yaml"
    if [[ ! -f "${KUSTOMIZATION_FILE}" ]]; then
        echo "[ERROR] No 'kustomization.yaml' found in '${KUSTOMIZE_DIR}'." >&2
        exit 1
    fi
}

wait_for_file() {
    local file="$1"
    local timeout=30  # seconds
    local waited=0
    while [ ! -s "$file" ] && [ $waited -lt $timeout ]; do
         sleep 1
         waited=$((waited+1))
    done
    if [ ! -s "$file" ]; then
         echo "[ERROR] Timeout waiting for file $file to be generated."
         exit 1
    fi
}

# Process Helm charts, create base files and overlay patch files.
# (We build the patch_files array in the main shell using process substitution.)
process_helm_charts() {
    HELM_CHARTS_YAML="$(yq eval '.helmCharts' "${KUSTOMIZATION_FILE}")"
    if [[ "${HELM_CHARTS_YAML}" == "null" ]]; then
        echo "[INFO] No .helmCharts found in ${KUSTOMIZATION_FILE}. Nothing to expand."
        exit 0
    fi

    echo "[INFO] Expanding Helm templates into '${BASE_DIR}'..."
    run_cmd mkdir -p "${BASE_DIR}" "${OVERLAY_DIR}" "${ARCHIVED_DIR}"

    # Create a minimal overlay kustomization.yaml if missing.
    if [[ ! -f "${OVERLAY_DIR}/kustomization.yaml" ]]; then
        echo "[INFO] Creating empty overlay kustomization.yaml..."
        cat <<EOF | run_cmd tee "${OVERLAY_DIR}/kustomization.yaml" >/dev/null
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: []
EOF
    fi

    # Backup original root kustomization.yaml.
    run_cmd cp "${KUSTOMIZATION_FILE}" "${KUSTOMIZATION_FILE}.bak"

    # Global array for patch files.
    patch_files=()

    while read -r chart; do
        CHART_NAME=$(echo "${chart}" | jq -r '.name')
        CHART_REPO=$(echo "${chart}" | jq -r '.repo')
        CHART_VERSION=$(echo "${chart}" | jq -r '.version // empty')
        CHART_RELEASE_NAME=$(echo "${chart}" | jq -r '.releaseName // "default-release"')
        CHART_VALUES=$(echo "${chart}" | jq -r '.valuesFile // empty')
        CHART_NAMESPACE=$(echo "${chart}" | jq -r '.namespace // "default"')

        if [[ -z "${CHART_NAME}" || -z "${CHART_REPO}" ]]; then
            echo "[ERROR] Invalid Helm chart definition: must have 'name' and 'repo'." >&2
            exit 1
        fi

        CHART_OUTPUT_DIR="${BASE_DIR}"
        echo "[INFO] Rendering Helm chart '${CHART_NAME}' into '${CHART_OUTPUT_DIR}'..."

        if ! helm repo list | grep -q "${CHART_REPO}"; then
            echo "[INFO] Adding Helm repository: ${CHART_REPO}..."
            run_cmd helm repo add "${CHART_NAME}" "${CHART_REPO}"
            run_cmd helm repo update
        fi

        HELM_CMD=( helm template "${CHART_RELEASE_NAME}" "${CHART_NAME}/${CHART_NAME}"
                   --namespace "${CHART_NAMESPACE}"
                   --output-dir "${CHART_OUTPUT_DIR}" )
        [[ -n "${CHART_VERSION}" ]] && HELM_CMD+=(--version "${CHART_VERSION}")

        if ! run_cmd "${HELM_CMD[@]}"; then
            echo "[ERROR] Helm template command failed for chart '${CHART_NAME}'." >&2
            exit 1
        fi

        # Flatten any extra nested directories.
        NESTED_CHART_DIR="${BASE_DIR}/${CHART_NAME}"
        if [[ -d "${NESTED_CHART_DIR}" ]]; then
            echo "[INFO] Removing extra nested '${CHART_NAME}' folder..."
            run_cmd shopt -s dotglob
            run_cmd mv "${NESTED_CHART_DIR}"/* "${BASE_DIR}/"
            run_cmd shopt -u dotglob
            run_cmd rm -rf "${NESTED_CHART_DIR}"
        fi

        if [[ -d "${BASE_DIR}/templates" ]]; then
            echo "[INFO] Flattening 'templates/' layer in '${BASE_DIR}'..."
            run_cmd shopt -s dotglob
            run_cmd mv "${BASE_DIR}/templates"/* "${BASE_DIR}/"
            run_cmd shopt -u dotglob
            run_cmd rm -rf "${BASE_DIR}/templates"
        fi

        # Create patch file from values if specified.
        if [[ -n "${CHART_VALUES}" && -f "${KUSTOMIZE_DIR}/${CHART_VALUES}" ]]; then
            patch_file="${OVERLAY_DIR}/${CHART_RELEASE_NAME}-values-patch.yaml"
            echo "[INFO] Creating patch file for chart '${CHART_NAME}' from values file '${CHART_VALUES}'..."
            run_cmd cp "${KUSTOMIZE_DIR}/${CHART_VALUES}" "${patch_file}"
            patch_files+=("${patch_file}")
        fi

    done < <(yq eval -o=json '.helmCharts' "${KUSTOMIZATION_FILE}" | jq -c '.[]')

    # Append patch references to overlay/kustomization.yaml if patches exist.
    if [ ${#patch_files[@]} -gt 0 ]; then
        echo "[INFO] Appending patchesStrategicMerge to overlay/kustomization.yaml..."
        {
            echo "patchesStrategicMerge:"
            for patch in "${patch_files[@]}"; do
                echo "  - $(basename "$patch")"
            done
        } | run_cmd tee -a "${OVERLAY_DIR}/kustomization.yaml" >/dev/null
    fi

    # Archive old files.
    run_cmd mv "${KUSTOMIZE_DIR}/kustomization.yaml" "${ARCHIVED_DIR}/kustomization.yaml" 2>/dev/null || true
    run_cmd mv "${KUSTOMIZE_DIR}/values.yaml" "${ARCHIVED_DIR}/values.yaml" 2>/dev/null || true
    run_cmd mv "${KUSTOMIZE_DIR}/kustomization.yaml.bak" "${ARCHIVED_DIR}/kustomization.yaml.bak" 2>/dev/null || true
}

# Generate kustomization.yaml files in the base directory only.
generate_base_kustomizations() {
    echo "[INFO] Generating kustomization.yaml files in '${BASE_DIR}' using create_kustomization.sh..."
    run_cmd "${SCRIPT_DIR}/create_kustomization.sh" -r -o -i overlay -i archived "${BASE_DIR}"
}

# Finalize the overlay and top-level kustomization.
generate_final_kustomization() {
    echo "[INFO] Finalizing overlay kustomization..."
    run_cmd "${SCRIPT_DIR}/create_kustomization.sh" -r -o "${OVERLAY_DIR}"
    wait_for_file "${OVERLAY_DIR}/kustomization.yaml"

    echo "[INFO] Generating top-level kustomization.yaml in '${KUSTOMIZE_DIR}'..."
    cat <<EOF | run_cmd tee "${KUSTOMIZE_DIR}/kustomization.yaml" >/dev/null
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - base
  - overlay
EOF
}

validate_final_build() {
    echo "[INFO] Validating final Kustomize build..."
    if ! build_output=$( (run_cmd kustomize build "${KUSTOMIZE_DIR}") 2>&1 ); then
        echo "[ERROR] Final Kustomize build failed:"
        echo "$build_output"
        exit 1
    fi
    echo "[INFO] Final Kustomize build succeeded."
}

apply_dry_run() {
    echo "[INFO] Running 'kubectl apply -k --dry-run=server'..."
    if ! kubectl_output=$( (run_cmd kubectl apply -k "${KUSTOMIZE_DIR}" --dry-run=server) 2>&1 ); then
        echo "[ERROR] 'kubectl apply -k --dry-run=server' failed:"
        echo "$kubectl_output"
        exit 1
    fi
    echo "[INFO] 'kubectl apply -k --dry-run=server' succeeded."
    echo "$kubectl_output"
}

main() {
    KUSTOMIZE_DIR="${TARGET_DIR}"
    BASE_DIR="${KUSTOMIZE_DIR}/base"
    OVERLAY_DIR="${KUSTOMIZE_DIR}/overlay"
    ARCHIVED_DIR="${KUSTOMIZE_DIR}/archived"

    check_dependencies
    check_create_script
    check_root_kustomization
    process_helm_charts
    generate_base_kustomizations
    validate_final_build
    apply_dry_run

    # Now that everything else is done, finalize overlay and create top-level file.
    generate_final_kustomization

    echo "[INFO] Helm successfully removed. Flattened structure is in '${BASE_DIR}'."
    echo "[INFO] Old files have been archived in '${ARCHIVED_DIR}'."
    echo "[INFO] You can apply the manifests with 'kubectl apply -k ${KUSTOMIZE_DIR}'."
}

##########################
# Parse Command-Line Args#
##########################
DRY_RUN=false
RECURSIVE=false
OVERRIDE=false
IGNORE_PATTERNS=()

while getopts ":Droi:" opt; do
    case ${opt} in
        D )
            DRY_RUN=true
            ;;
        r )
            RECURSIVE=true
            ;;
        o )
            OVERRIDE=true
            ;;
        i )
            IGNORE_PATTERNS+=("$OPTARG")
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        : )
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

shift $((OPTIND -1))

if [ -z "$1" ]; then
    usage
fi

TARGET_DIR="$1"

if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

main
