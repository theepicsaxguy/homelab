#!/bin/bash
set -euo pipefail

##########################
# Function Declarations  #
##########################

# Display usage help.
usage() {
    echo "Usage: $0 [-D] [-r] [-o] [-i ignore_dir]... <directory>"
    echo "  -D               Dry run mode (commands will be echoed, not executed)"
    echo "  -r               Process directories recursively (default: non-recursive)"
    echo "  -o               Override existing kustomization.yaml files (force regeneration)"
    echo "  -i ignore_dir    Ignore directory with name 'ignore_dir'. Can be specified multiple times."
    exit 1
}

# Run a command. If DRY_RUN is enabled, only print the command.
run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "DRY RUN: $*"
    else
        "$@"
    fi
}

# Check for required dependencies.
check_dependencies() {
    for cmd in kustomize yq helm jq kubectl; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "[ERROR] Missing required dependency: $cmd" >&2
            exit 1
        fi
    done
}

# Check that the create_kustomization.sh helper exists and is executable.
check_create_script() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ ! -x "${SCRIPT_DIR}/create_kustomization.sh" ]]; then
        echo "[ERROR] Missing or non-executable create_kustomization.sh script in ${SCRIPT_DIR}." >&2
        exit 1
    fi
}

# Check that the root kustomization.yaml exists.
check_root_kustomization() {
    KUSTOMIZATION_FILE="${KUSTOMIZE_DIR}/kustomization.yaml"
    if [[ ! -f "${KUSTOMIZATION_FILE}" ]]; then
        echo "[ERROR] No 'kustomization.yaml' found in '${KUSTOMIZE_DIR}'." >&2
        exit 1
    fi
}

# Process Helm charts from the root kustomization.yaml and render manifests.
process_helm_charts() {
    # Check for .helmCharts in the root kustomization.yaml
    HELM_CHARTS_YAML="$(yq eval '.helmCharts' "${KUSTOMIZATION_FILE}")"
    if [[ "${HELM_CHARTS_YAML}" == "null" ]]; then
        echo "[INFO] No .helmCharts found in ${KUSTOMIZATION_FILE}. Nothing to expand."
        exit 0
    fi

    echo "[INFO] Expanding Helm templates into '${BASE_DIR}'..."
    run_cmd mkdir -p "${BASE_DIR}" "${OVERLAY_DIR}" "${ARCHIVED_DIR}"

    # Create minimal overlay kustomization.yaml if missing.
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

    # Initialize an array to collect patch files.
    patch_files=()

    # Process each Helm chart.
    yq eval -o=json '.helmCharts' "${KUSTOMIZATION_FILE}" | jq -c '.[]' | while read -r chart; do
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

        # Render Helm chart into BASE_DIR.
        CHART_OUTPUT_DIR="${BASE_DIR}"
        echo "[INFO] Rendering Helm chart '${CHART_NAME}' into '${CHART_OUTPUT_DIR}'..."

        # Ensure Helm repository is added.
        if ! helm repo list | grep -q "${CHART_REPO}"; then
            echo "[INFO] Adding Helm repository: ${CHART_REPO}..."
            run_cmd helm repo add "${CHART_NAME}" "${CHART_REPO}"
            run_cmd helm repo update
        fi

        # Build the helm template command. Do not pass --values so that the values file can be used as a patch.
        HELM_CMD=( helm template "${CHART_RELEASE_NAME}" "${CHART_NAME}/${CHART_NAME}"
                   --namespace "${CHART_NAMESPACE}"
                   --output-dir "${CHART_OUTPUT_DIR}" )
        [[ -n "${CHART_VERSION}" ]] && HELM_CMD+=(--version "${CHART_VERSION}")

        if ! run_cmd "${HELM_CMD[@]}"; then
            echo "[ERROR] Helm template command failed for chart '${CHART_NAME}'." >&2
            exit 1
        fi

        # Flatten nested Helm folders if present.
        NESTED_CHART_DIR="${BASE_DIR}/${CHART_NAME}"
        if [[ -d "${NESTED_CHART_DIR}" ]]; then
            echo "[INFO] Removing extra nested '${CHART_NAME}' folder..."
            run_cmd shopt -s dotglob
            run_cmd mv "${NESTED_CHART_DIR}"/* "${BASE_DIR}/"
            run_cmd shopt -u dotglob
            run_cmd rm -rf "${NESTED_CHART_DIR}"
        fi

        # Flatten 'templates/' layer if it exists.
        if [[ -d "${BASE_DIR}/templates" ]]; then
            echo "[INFO] Flattening 'templates/' layer in '${BASE_DIR}'..."
            run_cmd shopt -s dotglob
            run_cmd mv "${BASE_DIR}/templates"/* "${BASE_DIR}/"
            run_cmd shopt -u dotglob
            run_cmd rm -rf "${BASE_DIR}/templates"
        fi

        # Instead of applying the values file during rendering, generate a patch.
        if [[ -n "${CHART_VALUES}" && -f "${KUSTOMIZE_DIR}/${CHART_VALUES}" ]]; then
            patch_file="${OVERLAY_DIR}/${CHART_RELEASE_NAME}-values-patch.yaml"
            echo "[INFO] Creating patch file for chart '${CHART_NAME}' from values file '${CHART_VALUES}'..."
            run_cmd cp "${KUSTOMIZE_DIR}/${CHART_VALUES}" "${patch_file}"
            patch_files+=("${patch_file}")
        fi

    done

    # Update overlay kustomization.yaml with patches if any were created.
    if [ ${#patch_files[@]} -gt 0 ]; then
        echo "[INFO] Updating overlay/kustomization.yaml with patchesStrategicMerge..."
        {
            echo "patchesStrategicMerge:"
            for patch in "${patch_files[@]}"; do
                echo "  - $(basename "$patch")"
            done
        } | run_cmd tee -a "${OVERLAY_DIR}/kustomization.yaml" >/dev/null
    fi

    # Archive old files from the root.
    run_cmd mv "${KUSTOMIZE_DIR}/kustomization.yaml" "${ARCHIVED_DIR}/kustomization.yaml" 2>/dev/null || true
    run_cmd mv "${KUSTOMIZE_DIR}/values.yaml" "${ARCHIVED_DIR}/values.yaml" 2>/dev/null || true
    run_cmd mv "${KUSTOMIZE_DIR}/kustomization.yaml.bak" "${ARCHIVED_DIR}/kustomization.yaml.bak" 2>/dev/null || true
}

# Generate recursive kustomization.yaml files using create_kustomization.sh.
generate_kustomizations() {
    echo "[INFO] Generating kustomization.yaml files in '${BASE_DIR}' using create_kustomization.sh..."
    run_cmd "${SCRIPT_DIR}/create_kustomization.sh" -r -o -i overlay -i archived "${BASE_DIR}"
    echo "[INFO] Generating kustomization.yaml in '${OVERLAY_DIR}' using create_kustomization.sh..."
    run_cmd "${SCRIPT_DIR}/create_kustomization.sh" -r -o "${OVERLAY_DIR}"

    echo "[INFO] Generating top-level kustomization.yaml in '${KUSTOMIZE_DIR}'..."
    cat <<EOF | run_cmd tee "${KUSTOMIZE_DIR}/kustomization.yaml" >/dev/null
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - base
  - overlay
EOF
}

# Validate the final Kustomize build.
validate_final_build() {
    echo "[INFO] Validating final Kustomize build..."
    if ! build_output=$( (run_cmd kustomize build "${KUSTOMIZE_DIR}") 2>&1 ); then
        echo "[ERROR] Final Kustomize build failed:"
        echo "$build_output"
        exit 1
    fi
    echo "[INFO] Final Kustomize build succeeded."
}

# Perform a dry-run with kubectl.
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

# Main function: parse arguments and run all steps.
main() {
    # Global variables set from arguments.
    KUSTOMIZE_DIR="${TARGET_DIR}"
    BASE_DIR="${KUSTOMIZE_DIR}/base"
    OVERLAY_DIR="${KUSTOMIZE_DIR}/overlay"
    ARCHIVED_DIR="${KUSTOMIZE_DIR}/archived"

    check_dependencies
    check_create_script
    check_root_kustomization
    process_helm_charts
    generate_kustomizations
    validate_final_build
    apply_dry_run

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

# Ensure a directory argument is provided.
if [ -z "$1" ]; then
    usage
fi

TARGET_DIR="$1"

# Verify that the provided path exists and is a directory.
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

##########################
#       Run Main         #
##########################
main
