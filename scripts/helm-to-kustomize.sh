#!/bin/bash
set -euo pipefail

##########################
# Function Declarations  #
##########################

usage() {
    echo "Usage: $0 [-D] [-r] [-o] [-i ignore_dir]... <directory>"
    echo "  -D               Dry run mode (commands will be echoed, not executed)"
    echo "  -r               Process directories recursively (default: enabled)"
    echo "  -o               Override existing kustomization.yaml files (default: enabled)"
    echo "  -i ignore_dir    Ignore directory with name 'ignore_dir'"
    exit 1
}

# Dry-run wrapper
run_or_echo() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] $*"
    else
        "$@"
    fi
}

check_dependencies() {
    local missing=()
    for cmd in kustomize yq helm jq kubectl; do
        if ! command -v "$cmd" >/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ "${#missing[@]}" -gt 0 ]]; then
        echo "[ERROR] Missing dependencies: ${missing[*]}"
        exit 1
    fi
}

check_create_script() {
    local script_path
    script_path="$(dirname "${BASH_SOURCE[0]}")/create_kustomization.sh"
    if [[ ! -x "$script_path" ]]; then
        echo "[ERROR] create_kustomization.sh is missing or not executable."
        exit 1
    fi
}

# Verify that the original kustomization.yaml exists before processing
check_root_kustomization() {
    if [[ ! -f "${KUSTOMIZE_DIR}/kustomization.yaml" ]]; then
        echo "[ERROR] No kustomization.yaml found in '${KUSTOMIZE_DIR}'."
        exit 1
    fi
}

# Render Helm charts
process_helm_charts() {
    local helm_charts
    helm_charts=$(yq eval '.helmCharts' "${KUSTOMIZE_DIR}/kustomization.yaml")

    if [[ "$helm_charts" == "null" ]]; then
        echo "[INFO] No Helm charts to process."
        return
    fi

    mkdir -p "$BASE_DIR" "$OVERLAY_DIR" "$ARCHIVED_DIR"

    local patch_files=()

    yq eval -o=json '.helmCharts | .[]' "${KUSTOMIZE_DIR}/kustomization.yaml" | jq -c '.' | while read -r chart; do
        local name repo version release values namespace
        name=$(echo "$chart" | jq -r '.name')
        repo=$(echo "$chart" | jq -r '.repo')
        version=$(echo "$chart" | jq -r '.version // empty')
        release=$(echo "$chart" | jq -r '.releaseName // "default-release"')
        values=$(echo "$chart" | jq -r '.valuesFile // empty')
        namespace=$(echo "$chart" | jq -r '.namespace // "default"')

        if [[ -z "$name" || -z "$repo" ]]; then
            echo "[ERROR] Helm chart must define 'name' and 'repo'."
            exit 1
        fi

        echo "[INFO] Processing Helm chart '$name'..."

        # Add repo if missing
        if ! helm repo list -o json | jq -e ".[] | select(.name == \"$name\")" >/dev/null; then
            run_or_echo helm repo add "$name" "$repo"
            run_or_echo helm repo update
        fi

        # Render Helm chart
        local helm_cmd=(helm template "$release" "$name/$name" --namespace "$namespace" --output-dir "$BASE_DIR")
        [[ -n "$version" ]] && helm_cmd+=(--version "$version")
        run_or_echo "${helm_cmd[@]}"

        # Flatten directory structure
        for subdir in "$BASE_DIR/$name" "$BASE_DIR/templates"; do
            if [[ -d "$subdir" && -n "$(ls -A "$subdir" 2>/dev/null)" ]]; then
                run_or_echo mv "$subdir"/* "$BASE_DIR/"
                run_or_echo rm -rf "$subdir"
            fi
        done

        # Handle values file
        if [[ -n "$values" && -f "${KUSTOMIZE_DIR}/$values" ]]; then
            local patch_file="$OVERLAY_DIR/${release}-values-patch.yaml"
            run_or_echo cp "${KUSTOMIZE_DIR}/$values" "$patch_file"
            patch_files+=("$(basename "$patch_file")")
        fi
    done

    # Safely move files
    move_file() {
        local src="$1"
        local dst="$2"
        if [[ -e "$src" ]]; then
            mkdir -p "$(dirname "$dst")"
            run_or_echo mv "$src" "$dst"
        else
            echo "[WARN] File '$src' not found. Skipping."
        fi
    }

    # Archive original files
    move_file "${KUSTOMIZE_DIR}/kustomization.yaml" "${ARCHIVED_DIR}/kustomization.yaml"
    move_file "${KUSTOMIZE_DIR}/values.yaml" "${ARCHIVED_DIR}/values.yaml"
}

# Generate new kustomization.yaml files recursively.
# Also ensure that the root directory gets a kustomization.yaml.
generate_base_kustomizations() {
    local script_dir
    script_dir="$(dirname "${BASH_SOURCE[0]}")"

    # Use the provided flags or default to -r and -o.
    local rec_flag="${RECURSIVE:-"-r"}"
    local override_flag="${OVERRIDE:-"-o"}"

    # Recursively generate kustomizations for the root directory (ignoring overlay and archived)
    "$script_dir/create_kustomization.sh" $rec_flag $override_flag -i overlay -i archived "$KUSTOMIZE_DIR"

    # Ensure root kustomization exists; if not, generate it without recursion
    if [[ ! -f "$KUSTOMIZE_DIR/kustomization.yaml" ]]; then
        echo "[INFO] Generating root kustomization.yaml..."
        "$script_dir/create_kustomization.sh" $override_flag -i overlay -i archived "$KUSTOMIZE_DIR"
    fi

    # Generate kustomization for the overlay directory
    if [[ -d "$OVERLAY_DIR" ]]; then
        echo "[INFO] Generating overlay kustomization.yaml..."
        "$script_dir/create_kustomization.sh" $override_flag -i overlay -i archived "$OVERLAY_DIR"
    else
        echo "[WARN] Overlay directory '$OVERLAY_DIR' not found. Skipping overlay kustomization generation."
    fi
}

# New function: add_base_resource_to_overlay
add_base_resource_to_overlay() {
    local overlay_kustomization="$OVERLAY_DIR/kustomization.yaml"
    if [[ -f "$overlay_kustomization" ]]; then
        if ! grep -q '^\s*-\s\+../base' "$overlay_kustomization"; then
            echo "[INFO] Adding '../base' as a resource to overlay kustomization..."
            if grep -q "^resources:" "$overlay_kustomization"; then
                sed -i '/^resources:/a\  - ../base' "$overlay_kustomization"
            else
                # Create a resources section and add the base folder as a resource
                echo -e "resources:\n  - ../base" >> "$overlay_kustomization"
            fi
        fi
    else
        echo "[WARN] Overlay kustomization file not found at $overlay_kustomization"
    fi
}




validate_final_build() {
    echo "[INFO] Validating Kustomize build..."

    if ! build_output=$(kustomize build "$KUSTOMIZE_DIR" 2>&1); then
        echo "[ERROR] Kustomize build failed:"
        echo "$build_output"
        exit 1
    fi

    echo "[INFO] Kustomize build succeeded."
}

apply_dry_run() {
    if ! kubectl apply -k "$KUSTOMIZE_DIR" --dry-run=server >/dev/null 2>&1; then
        echo "[ERROR] kubectl dry-run failed."
        kubectl apply -k "$KUSTOMIZE_DIR" --dry-run=server 2>&1
        exit 1
    fi
    echo "[INFO] kubectl dry-run succeeded."
}

# Updated main function to use the overlay as the final configuration for ArgoCD
main() {
    KUSTOMIZE_DIR="$TARGET_DIR"
    BASE_DIR="${KUSTOMIZE_DIR}/base"
    OVERLAY_DIR="${KUSTOMIZE_DIR}/overlay"
    ARCHIVED_DIR="${KUSTOMIZE_DIR}/archived"

    check_dependencies
    check_create_script
    check_root_kustomization
    process_helm_charts
    generate_base_kustomizations

    # Ensure the overlay kustomization references the base
    add_base_resource_to_overlay

    # Validate the overlay kustomization (final output)
    echo "[INFO] Validating Kustomize build using overlay..."
    if ! build_output=$(kustomize build "$OVERLAY_DIR" 2>&1); then
        echo "[ERROR] Kustomize build failed:"
        echo "$build_output"
        exit 1
    fi
    echo "[INFO] Kustomize build succeeded for overlay."

    echo "[INFO] Performing kubectl dry-run using overlay..."
    if ! kubectl apply -k "$OVERLAY_DIR" --dry-run=server >/dev/null 2>&1; then
        echo "[ERROR] kubectl dry-run failed."
        kubectl apply -k "$OVERLAY_DIR" --dry-run=server 2>&1
        exit 1
    fi
    echo "[INFO] kubectl dry-run succeeded."

    echo "[INFO] Process complete. For ArgoCD, point your application to: ${OVERLAY_DIR}"
}



##########################
# Parse Command-Line Args#
##########################
DRY_RUN=false
# Default to recursive and override as in the original call
RECURSIVE="-r"
OVERRIDE="-o"
IGNORE_PATTERNS=()

while getopts ":Droi:" opt; do
    case ${opt} in
        D ) DRY_RUN=true ;;
        r ) RECURSIVE="-r" ;;  # explicitly set recursive flag (even though default is -r)
        o ) OVERRIDE="-o" ;;
        i ) IGNORE_PATTERNS+=("$OPTARG") ;;
        \? | : ) usage ;;
    esac
done
shift $((OPTIND -1))

TARGET_DIR="${1:-}"
if [[ -z "$TARGET_DIR" || ! -d "$TARGET_DIR" ]]; then
    echo "[ERROR] Invalid or missing directory."
    exit 1
fi

main
