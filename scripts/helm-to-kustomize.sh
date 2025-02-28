#!/bin/bash
set -euo pipefail

# Usage:
#   ./helm-to-kustomize.sh <kustomize_directory>
#
# Example:
#   ./helm-to-kustomize.sh k8s/infrastructure/base/network/cilium
#
# This script converts Helm charts defined in kustomization.yaml (under .helmCharts)
# into a fully static manifest set that mimics a manual helm template workflow.
#   - It uses helm template with --output-dir to render the chart files.
#   - It flattens the nested output directories so that the rendered YAML files reside directly
#     in the chart’s output directory.
#   - It creates a kustomization.yaml in each chart’s output directory (autodetecting resources).
#   - It removes .helmCharts from the main kustomization.yaml and adds the helm-expanded
#     directory as a resource.
#
# Prerequisites: kustomize, yq, helm, jq

# Get the directory containing kustomization.yaml (defaults to current directory)
KUSTOMIZE_DIR="${1:-.}"
OUTPUT_DIR="${KUSTOMIZE_DIR}/helm-expanded"

# Ensure required dependencies exist
for cmd in kustomize yq helm jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "[ERROR] Missing required dependency: $cmd" >&2
    exit 1
  fi
done

# Validate that kustomization.yaml exists in the specified directory
KUSTOMIZATION_FILE="${KUSTOMIZE_DIR}/kustomization.yaml"
if [[ ! -f "${KUSTOMIZATION_FILE}" ]]; then
  echo "[ERROR] '${KUSTOMIZE_DIR}' must contain a kustomization.yaml" >&2
  exit 1
fi

# Check if .helmCharts exists and is not null in kustomization.yaml
HELM_CHARTS_YAML=$(yq eval '.helmCharts' "${KUSTOMIZATION_FILE}")
if [[ "${HELM_CHARTS_YAML}" == "null" ]]; then
  echo "[INFO] No .helmCharts found. Nothing to expand."
  exit 0
fi

echo "[INFO] Expanding Helm templates to '${OUTPUT_DIR}'..."
mkdir -p "${OUTPUT_DIR}"

# Backup the original kustomization.yaml
cp "${KUSTOMIZATION_FILE}" "${KUSTOMIZATION_FILE}.bak"

# Process each Helm chart defined in .helmCharts
yq eval -o=json '.helmCharts' "${KUSTOMIZATION_FILE}" | jq -c '.[]' | while read -r chart; do
  CHART_NAME=$(echo "${chart}" | jq -r '.name')
  CHART_REPO=$(echo "${chart}" | jq -r '.repo')
  CHART_VERSION=$(echo "${chart}" | jq -r '.version // empty')
  CHART_RELEASE_NAME=$(echo "${chart}" | jq -r '.releaseName // "default-release"')
  CHART_VALUES=$(echo "${chart}" | jq -r '.valuesFile // empty')
  CHART_NAMESPACE=$(echo "${chart}" | jq -r '.namespace // "default"')

  if [[ -z "${CHART_NAME}" || -z "${CHART_REPO}" ]]; then
    echo "[ERROR] Invalid Helm chart definition in kustomization.yaml. Both 'name' and 'repo' must be provided." >&2
    exit 1
  fi

  # Set up output directory for this chart
  CHART_OUTPUT_DIR="${OUTPUT_DIR}/${CHART_RELEASE_NAME}"
  echo "[INFO] Rendering Helm chart '${CHART_NAME}' into '${CHART_OUTPUT_DIR}'..."
  mkdir -p "${CHART_OUTPUT_DIR}"

  # Ensure the Helm repository is added
  if ! helm repo list | grep -q "${CHART_REPO}"; then
    echo "[INFO] Adding Helm repository: ${CHART_REPO}..."
    helm repo add "${CHART_NAME}" "${CHART_REPO}"
    helm repo update
  fi

  # Run helm template with --output-dir so that rendered files are written into CHART_OUTPUT_DIR/<chart>/
  HELM_CMD=(helm template "${CHART_RELEASE_NAME}" "${CHART_NAME}/${CHART_NAME}" --namespace "${CHART_NAMESPACE}" --output-dir "${CHART_OUTPUT_DIR}")
  [[ -n "${CHART_VERSION}" ]] && HELM_CMD+=(--version "${CHART_VERSION}")
  if [[ -n "${CHART_VALUES}" ]]; then
    if [[ -f "${KUSTOMIZE_DIR}/${CHART_VALUES}" ]]; then
      HELM_CMD+=(--values "${KUSTOMIZE_DIR}/${CHART_VALUES}")
    else
      echo "[WARN] Values file '${CHART_VALUES}' not found in '${KUSTOMIZE_DIR}'. Skipping --values for chart '${CHART_NAME}'."
    fi
  fi

  if ! "${HELM_CMD[@]}"; then
    echo "[ERROR] Helm template command failed for chart '${CHART_NAME}'." >&2
    exit 1
  fi

  # The helm output is expected under CHART_OUTPUT_DIR/<chart name>
  NESTED_DIR="${CHART_OUTPUT_DIR}/${CHART_NAME}"
  if [[ -d "${NESTED_DIR}" ]]; then
    # Step 1: If a 'templates' directory exists inside NESTED_DIR, move its contents up
    if [[ -d "${NESTED_DIR}/templates" ]]; then
      echo "[INFO] Flattening 'templates' directory for chart '${CHART_NAME}'..."
      mv "${NESTED_DIR}/templates/"* "${NESTED_DIR}/" 2>/dev/null || true
      rm -rf "${NESTED_DIR}/templates"
    fi

    # Step 2: Move all files from NESTED_DIR up one level into CHART_OUTPUT_DIR and remove NESTED_DIR
    echo "[INFO] Moving rendered files for chart '${CHART_NAME}' to '${CHART_OUTPUT_DIR}'..."
    mv "${NESTED_DIR}/"* "${CHART_OUTPUT_DIR}/" 2>/dev/null || true
    rm -rf "${NESTED_DIR}"
  else
    echo "[WARN] Expected nested directory '${NESTED_DIR}' not found. Skipping flattening for chart '${CHART_NAME}'."
  fi

  # Generate a kustomization.yaml in the chart output directory (CHART_OUTPUT_DIR)
  echo "[INFO] Generating kustomization.yaml in '${CHART_OUTPUT_DIR}'..."
  KUSTOMIZATION_TMP="${CHART_OUTPUT_DIR}/kustomization.yaml"
  {
    echo "apiVersion: kustomize.config.k8s.io/v1beta1"
    echo "kind: Kustomization"
    echo "resources:"
    for file in "${CHART_OUTPUT_DIR}"/*.yaml; do
      # Exclude any existing kustomization.yaml in the list
      if [[ "$(basename "$file")" != "kustomization.yaml" ]]; then
        echo "  - $(basename "$file")"
      fi
    done
  } > "${KUSTOMIZATION_TMP}"

done

# Create a top-level kustomization.yaml inside helm-expanded that references each chart directory.
echo "[INFO] Generating top-level kustomization.yaml in '${OUTPUT_DIR}'..."
{
  echo "apiVersion: kustomize.config.k8s.io/v1beta1"
  echo "kind: Kustomization"
  echo "resources:"
  for d in "${OUTPUT_DIR}"/*/ ; do
    # Use the directory name relative to helm-expanded.
    dir_name=$(basename "$d")
    echo "  - ${dir_name}"
  done
} > "${OUTPUT_DIR}/kustomization.yaml"

# Remove the helmCharts section from the main kustomization.yaml
echo "[INFO] Removing .helmCharts from '${KUSTOMIZATION_FILE}'..."
yq eval 'del(.helmCharts)' -i "${KUSTOMIZATION_FILE}"

# Add the expanded Helm manifests (the helm-expanded directory) as a resource to the main kustomization.yaml
echo "[INFO] Adding expanded Helm manifests as a resource to '${KUSTOMIZATION_FILE}'..."
yq eval -i '.resources += ["helm-expanded"]' "${KUSTOMIZATION_FILE}"

# Validate the final Kustomize build (without Helm directives)
echo "[INFO] Validating final Kustomize build (without Helm directives)..."
if ! kustomize build "${KUSTOMIZE_DIR}" &>/dev/null; then
  echo "[ERROR] Final Kustomize build failed. Restoring original kustomization.yaml." >&2
  mv "${KUSTOMIZATION_FILE}.bak" "${KUSTOMIZATION_FILE}"
  exit 1
fi

echo "[INFO] Helm successfully removed. Kustomize now works without Helm."
echo "[INFO] You can now apply the manifests with: kubectl apply -k ${KUSTOMIZE_DIR}"
