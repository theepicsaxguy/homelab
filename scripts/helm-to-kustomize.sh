#!/bin/bash
set -euo pipefail

# --- Constants for colored output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Helper: error reporting and exit ---
die() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
  exit 1
}

# --- Trap unexpected errors ---
trap 'die "An unexpected error occurred on line ${LINENO}"' ERR

# --- Log message with timestamp ---
log() {
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${GREEN}[INFO]${NC} $*"
}

# --- Usage function ---
usage() {
  echo "Usage: $0 <directory>"
  echo "Example: $0 k8s/infra/network/mychart"
  exit 1
}

# --- Validate input arguments ---
if [ "$#" -ne 1 ]; then
  usage
fi

TARGET_DIR="$1"
if [ ! -d "$TARGET_DIR" ]; then
  die "Directory '$TARGET_DIR' does not exist."
fi

# --- Check for required commands ---
required_cmds=(helm yq curl csplit)
missing=()
for cmd in "${required_cmds[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    missing+=("$cmd")
  fi
done
if [ "${#missing[@]}" -gt 0 ]; then
  die "The following commands are required but missing: ${missing[*]}"
fi

# --- Archive old helm-related files ---
ARCHIVE_DIR="${TARGET_DIR}/archive"
mkdir -p "$ARCHIVE_DIR"
for file in kustomization.yaml values.yaml; do
  if [ -f "${TARGET_DIR}/${file}" ]; then
    log "Archiving ${TARGET_DIR}/${file} to ${ARCHIVE_DIR}/"
    mv "${TARGET_DIR}/${file}" "${ARCHIVE_DIR}/"
  fi
done

# --- Read dynamic values from the archived kustomization file ---
ARCHIVED_KUSTOMIZATION="${ARCHIVE_DIR}/kustomization.yaml"
if [ ! -f "$ARCHIVED_KUSTOMIZATION" ]; then
  die "Archived kustomization file not found in ${ARCHIVE_DIR}"
fi

# Extract helm chart parameters (assuming first helmCharts entry)
CHART_NAME=$(yq e '.helmCharts[0].name' "$ARCHIVED_KUSTOMIZATION")
CHART_REPO=$(yq e '.helmCharts[0].repo' "$ARCHIVED_KUSTOMIZATION")
CHART_VERSION=$(yq e '.helmCharts[0].version' "$ARCHIVED_KUSTOMIZATION")
RELEASE_NAME=$(yq e '.helmCharts[0].releaseName' "$ARCHIVED_KUSTOMIZATION")
CHART_NAMESPACE=$(yq e '.helmCharts[0].namespace' "$ARCHIVED_KUSTOMIZATION")
VALUES_FILE=$(yq e '.helmCharts[0].valuesFile' "$ARCHIVED_KUSTOMIZATION")

if [ -z "$CHART_NAME" ] || [ -z "$CHART_REPO" ] || [ -z "$CHART_VERSION" ] || \
   [ -z "$RELEASE_NAME" ] || [ -z "$CHART_NAMESPACE" ] || [ -z "$VALUES_FILE" ]; then
  die "One or more helm chart parameters are missing in the archived kustomization file."
fi

VALUES_FILE_PATH="${ARCHIVE_DIR}/${VALUES_FILE}"
if [ ! -f "$VALUES_FILE_PATH" ]; then
  die "Values file '$VALUES_FILE_PATH' not found in archive."
fi

# Extract includeCRDS flag (default to false if not specified)
INCLUDE_CRDS=$(yq e '.helmCharts[0].includeCRDs // false' "$ARCHIVED_KUSTOMIZATION")

log "Using helm chart parameters from archived file:"
echo "  Chart Name:      $CHART_NAME"
echo "  Chart Repo:      $CHART_REPO"
echo "  Chart Version:   $CHART_VERSION"
echo "  Release Name:    $RELEASE_NAME"
echo "  Namespace:       $CHART_NAMESPACE"
echo "  Values File:     $VALUES_FILE_PATH"
log "includeCRDS flag is set to: ${INCLUDE_CRDS}"

# --- Define directories for generated manifests ---
BASE_DIR="${TARGET_DIR}/base"
CRDS_DIR="${TARGET_DIR}/crds"
OVERLAYS_DIR="${TARGET_DIR}/overlays"
PROD_OVERLAY="${OVERLAYS_DIR}/production"
DEV_OVERLAY="${OVERLAYS_DIR}/development"

mkdir -p "$BASE_DIR" "$CRDS_DIR" "$PROD_OVERLAY" "$DEV_OVERLAY"

# --- Function: Render Helm chart to a single YAML file ---
render_helm_chart() {
  local output_file="$1"
  log "Rendering helm chart..."

  helm_args=()
  if [ "$INCLUDE_CRDS" = "true" ]; then
    helm_args+=(--include-crds)
  fi

  helm template "$RELEASE_NAME" "$CHART_NAME" \
    --repo "$CHART_REPO" \
    --namespace "$CHART_NAMESPACE" \
    --version "$CHART_VERSION" \
    "${helm_args[@]}" \
    -f "$VALUES_FILE_PATH" > "$output_file"
}

# --- Function: Split rendered YAML into separate resource files ---
split_manifests() {
  local input_file="$1"
  local out_dir="$2"

  log "Splitting rendered manifests from ${input_file}..."
  csplit -z -f "${out_dir}/split_" "$input_file" '/^---$/' '{*}' >/dev/null 2>&1
  rm -f "$input_file"

  for file in "${out_dir}/split_"*; do
    # Skip empty files
    if [ ! -s "$file" ]; then
      rm -f "$file"
      continue
    fi
    local kind
    kind=$(yq e '.kind // ""' "$file" | tr '[:upper:]' '[:lower:]')
    local name
    name=$(yq e '.metadata.name // ""' "$file")
    if [ -n "$kind" ] && [ -n "$name" ]; then
      local new_name="${kind}-${name}.yaml"
      # If the resource is a CRD, move it to the CRDS directory
      if [ "$kind" = "customresourcedefinition" ]; then
        mv "$file" "${CRDS_DIR}/${new_name}"
      else
        mv "$file" "${out_dir}/${new_name}"
      fi
    else
      rm -f "$file"
    fi
  done
}

# --- Function: Create base kustomization.yaml ---
create_base_kustomization() {
  local out_dir="$1"
  local kustomization_file="${out_dir}/kustomization.yaml"
  log "Creating base kustomization.yaml at ${kustomization_file}..."

  local resources=""
  for f in "$out_dir"/*.yaml; do
    [[ $(basename "$f") == "kustomization.yaml" ]] && continue
    resources+="  - $(basename "$f")"$'\n'
  done

  # Reference external resources from the parent directories
  resources+="  - ../announce.yaml"$'\n'
  resources+="  - ../ip-pool.yaml"$'\n'
  if [ -f "${CRDS_DIR}/crds.yaml" ]; then
    resources+="  - ../../crds/crds.yaml"$'\n'
  fi

  cat <<EOF > "$kustomization_file"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
$resources
EOF
}

# --- Function: Create overlay kustomization and sample patch ---
create_overlay() {
  local overlay_dir="$1"
  log "Creating overlay in ${overlay_dir}..."
  cat <<EOF > "${overlay_dir}/kustomization.yaml"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base/

patchesStrategicMerge:
  - patch-configmap.yaml
EOF

  cat <<'EOF' > "${overlay_dir}/patch-configmap.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: chart-config
  namespace: kube-system
data:
  exampleKey: "exampleValue"
EOF
}

# --- Function: Create a root-level kustomization.yaml ---
create_root_kustomization() {
  local root_file="${TARGET_DIR}/kustomization.yaml"
  log "Creating root-level kustomization.yaml at ${root_file}..."
  cat <<EOF > "$root_file"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - base/
EOF

  # Include CRDs if available
  if [ -d "${CRDS_DIR}" ] && [ "$(ls -A "${CRDS_DIR}")" ]; then
    echo "  - crds/" >> "$root_file"
  fi
}

# --- Main workflow ---
main() {
  local rendered_yaml="${BASE_DIR}/rendered.yaml"

  # Step 1: Render Helm chart to YAML
  render_helm_chart "$rendered_yaml"

  # Step 2: Split the rendered YAML into individual manifests and separate CRDs
  split_manifests "$rendered_yaml" "$BASE_DIR"

  # Step 3: Create a base kustomization.yaml that references all files (including CRDs if present)
  create_base_kustomization "$BASE_DIR"

  # Step 4: Create overlay directories (production and development)
  create_overlay "$PROD_OVERLAY"
  create_overlay "$DEV_OVERLAY"

  # Step 5: Create a root-level kustomization.yaml for the whole app
  create_root_kustomization

  log "Conversion completed successfully."
  echo -e "${YELLOW}Archived helm files are in: ${ARCHIVE_DIR}${NC}"
  if [ -d "${CRDS_DIR}" ] && [ "$(ls -A "${CRDS_DIR}")" ]; then
    echo -e "${YELLOW}To deploy CRDs: kubectl apply -k ${CRDS_DIR}${NC}"
  fi
  echo -e "${YELLOW}To deploy the base manifests: kubectl apply -k ${BASE_DIR}${NC}"
  echo -e "${YELLOW}To deploy production overlay: kubectl apply -k ${PROD_OVERLAY}${NC}"
  echo -e "${YELLOW}To deploy development overlay: kubectl apply -k ${DEV_OVERLAY}${NC}"
  echo -e "${YELLOW}Or deploy the whole app using the root-level kustomization: kubectl apply -k ${TARGET_DIR}${NC}"
}

main
