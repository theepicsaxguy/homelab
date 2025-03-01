#!/bin/bash
set -euo pipefail

# Usage:
#   ./helm-to-kustomize.sh <kustomize_directory>
#
# Converts Helm charts in kustomization.yaml into static manifests for Kustomize.
# Instead of baking values into the manifests, this version copies the values file
# as a patch in the overlay, so values can be updated dynamically.

KUSTOMIZE_DIR="${1:-.}"

BASE_DIR="${KUSTOMIZE_DIR}/base"
OVERLAY_DIR="${KUSTOMIZE_DIR}/overlay"
ARCHIVED_DIR="${KUSTOMIZE_DIR}/archived"

# Ensure required dependencies exist
for cmd in kustomize yq helm jq kubectl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "[ERROR] Missing required dependency: $cmd" >&2
    exit 1
  fi
done

# Verify kustomization.yaml exists
KUSTOMIZATION_FILE="${KUSTOMIZE_DIR}/kustomization.yaml"
if [[ ! -f "${KUSTOMIZATION_FILE}" ]]; then
  echo "[ERROR] No 'kustomization.yaml' found in '${KUSTOMIZE_DIR}'." >&2
  exit 1
fi

# Check .helmCharts
HELM_CHARTS_YAML="$(yq eval '.helmCharts' "${KUSTOMIZATION_FILE}")"
if [[ "${HELM_CHARTS_YAML}" == "null" ]]; then
  echo "[INFO] No .helmCharts found in ${KUSTOMIZATION_FILE}. Nothing to expand."
  exit 0
fi

echo "[INFO] Expanding Helm templates into '${BASE_DIR}'..."
mkdir -p "${BASE_DIR}" "${OVERLAY_DIR}" "${ARCHIVED_DIR}"

# Create minimal overlay kustomization.yaml if missing
if [[ ! -f "${OVERLAY_DIR}/kustomization.yaml" ]]; then
  echo "[INFO] Creating empty overlay kustomization.yaml..."
  cat <<EOF > "${OVERLAY_DIR}/kustomization.yaml"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: []
EOF
fi

# Backup original kustomization.yaml
cp "${KUSTOMIZATION_FILE}" "${KUSTOMIZATION_FILE}.bak"

# Initialize an array to collect patch files
patch_files=()

# Process Helm charts
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

  # Render Helm chart into BASE_DIR
  CHART_OUTPUT_DIR="${BASE_DIR}"
  echo "[INFO] Rendering Helm chart '${CHART_NAME}' into '${CHART_OUTPUT_DIR}'..."

  # Ensure Helm repository is added
  if ! helm repo list | grep -q "${CHART_REPO}"; then
    echo "[INFO] Adding Helm repository: ${CHART_REPO}..."
    helm repo add "${CHART_NAME}" "${CHART_REPO}"
    helm repo update
  fi

  # Build the helm template command.
  # Note: We no longer pass --values here so that the values file can be used as a patch.
  HELM_CMD=( helm template "${CHART_RELEASE_NAME}" "${CHART_NAME}/${CHART_NAME}"
             --namespace "${CHART_NAMESPACE}"
             --output-dir "${CHART_OUTPUT_DIR}" )
  [[ -n "${CHART_VERSION}" ]] && HELM_CMD+=(--version "${CHART_VERSION}")

  if ! "${HELM_CMD[@]}"; then
    echo "[ERROR] Helm template command failed for chart '${CHART_NAME}'." >&2
    exit 1
  fi

  # Flatten nested Helm folders
  NESTED_CHART_DIR="${BASE_DIR}/${CHART_NAME}"
  if [[ -d "${NESTED_CHART_DIR}" ]]; then
    echo "[INFO] Removing extra nested '${CHART_NAME}' folder..."
    shopt -s dotglob
    mv "${NESTED_CHART_DIR}"/* "${BASE_DIR}/"
    shopt -u dotglob
    rm -rf "${NESTED_CHART_DIR}"
  fi

  # Flatten 'templates/' layer if it exists
  if [[ -d "${BASE_DIR}/templates" ]]; then
    echo "[INFO] Flattening 'templates/' layer in '${BASE_DIR}'..."
    shopt -s dotglob
    mv "${BASE_DIR}/templates"/* "${BASE_DIR}/"
    shopt -u dotglob
    rm -rf "${BASE_DIR}/templates"
  fi

  # Instead of applying the values file during rendering, generate a patch.
  if [[ -n "${CHART_VALUES}" && -f "${KUSTOMIZE_DIR}/${CHART_VALUES}" ]]; then
    patch_file="${OVERLAY_DIR}/${CHART_RELEASE_NAME}-values-patch.yaml"
    echo "[INFO] Creating patch file for chart '${CHART_NAME}' from values file '${CHART_VALUES}'..."
    cp "${KUSTOMIZE_DIR}/${CHART_VALUES}" "${patch_file}"
    patch_files+=("${patch_file}")
  fi

done

# After processing charts, update the overlay/kustomization.yaml with patches if any were created.
if [ ${#patch_files[@]} -gt 0 ]; then
  echo "[INFO] Updating overlay/kustomization.yaml with patchesStrategicMerge..."
  {
    echo "patchesStrategicMerge:"
    for patch in "${patch_files[@]}"; do
      echo "  - $(basename "$patch")"
    done
  } >> "${OVERLAY_DIR}/kustomization.yaml"
fi

# Archive old files
mv "${KUSTOMIZE_DIR}/kustomization.yaml" "${ARCHIVED_DIR}/kustomization.yaml" 2>/dev/null || true
mv "${KUSTOMIZE_DIR}/values.yaml" "${ARCHIVED_DIR}/values.yaml" 2>/dev/null || true
mv "${KUSTOMIZE_DIR}/kustomization.yaml.bak" "${ARCHIVED_DIR}/kustomization.yaml.bak" 2>/dev/null || true

# Generate new kustomization.yaml in BASE_DIR
echo "[INFO] Generating ${BASE_DIR}/kustomization.yaml..."
temp_file=$(mktemp)
{
  echo "apiVersion: kustomize.config.k8s.io/v1beta1"
  echo "kind: Kustomization"
  echo "resources:"

  # Reference YAML files in BASE_DIR
  shopt -s nullglob
  for f in "${BASE_DIR}"/*.yaml; do
    [[ "$(basename "$f")" == "kustomization.yaml" ]] && continue
    echo "  - $(basename "$f")"
  done
  shopt -u nullglob

  # Reference subdirectories with manifests
  for d in "${BASE_DIR}"/*/; do
    subdir="$(basename "$d")"
    [[ "$subdir" == "overlay" || "$subdir" == "archived" ]] && continue
    if [[ -n $(compgen -G "$d"/*.yaml) ]]; then
      echo "  - ${subdir}"
    fi
  done
} > "$temp_file" && mv "$temp_file" "${BASE_DIR}/kustomization.yaml"

# Create top-level kustomization.yaml
echo "[INFO] Generating top-level kustomization.yaml in '${KUSTOMIZE_DIR}'..."
cat <<EOF > "${KUSTOMIZE_DIR}/kustomization.yaml"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - base
  - overlay
EOF

# Validate final Kustomize build
echo "[INFO] Validating final Kustomize build..."
if ! build_output=$(kustomize build "${KUSTOMIZE_DIR}" 2>&1); then
  echo "[ERROR] Final Kustomize build failed:"
  echo "$build_output"
  exit 1
fi
echo "[INFO] Final Kustomize build succeeded."

# Dry-run with kubectl
echo "[INFO] Running 'kubectl apply -k --dry-run=server'..."
if ! kubectl_output=$(kubectl apply -k "${KUSTOMIZE_DIR}" --dry-run=server 2>&1); then
  echo "[ERROR] 'kubectl apply -k --dry-run=server' failed:"
  echo "$kubectl_output"
  exit 1
fi
echo "[INFO] 'kubectl apply -k --dry-run=server' succeeded."
echo "$kubectl_output"

echo "[INFO] Helm successfully removed. Flattened structure is in '${BASE_DIR}'."
echo "[INFO] Old files have been archived in '${ARCHIVED_DIR}'."
echo "[INFO] You can apply the manifests with 'kubectl apply -k ${KUSTOMIZE_DIR}'."
