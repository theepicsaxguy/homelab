#!/bin/bash
set -euo pipefail

# --- Usage function ---
usage() {
  echo "Usage: $0 <directory>"
  echo "Example: $0 k8s/infra/network/cilium"
  exit 1
}

# --- Check for required commands ---
for cmd in helm yq curl csplit; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is not installed." >&2
    exit 1
  fi
done

# --- Validate input directory ---
if [ "$#" -ne 1 ]; then
  usage
fi

TARGET_DIR="$1"
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Directory '$TARGET_DIR' does not exist." >&2
  exit 1
fi

# --- Read dynamic values from the directory's kustomization.yaml ---
KUSTOMIZATION_FILE="${TARGET_DIR}/kustomization.yaml"
if [ ! -f "$KUSTOMIZATION_FILE" ]; then
  echo "Error: $KUSTOMIZATION_FILE not found." >&2
  exit 1
fi

# Use yq to extract the helm chart parameters (assuming first helmCharts entry)
CHART_NAME=$(yq e '.helmCharts[0].name' "$KUSTOMIZATION_FILE")
CHART_REPO=$(yq e '.helmCharts[0].repo' "$KUSTOMIZATION_FILE")
CHART_VERSION=$(yq e '.helmCharts[0].version' "$KUSTOMIZATION_FILE")
RELEASE_NAME=$(yq e '.helmCharts[0].releaseName' "$KUSTOMIZATION_FILE")
CHART_NAMESPACE=$(yq e '.helmCharts[0].namespace' "$KUSTOMIZATION_FILE")
VALUES_FILE=$(yq e '.helmCharts[0].valuesFile' "$KUSTOMIZATION_FILE")

if [ -z "$CHART_NAME" ] || [ -z "$CHART_REPO" ] || [ -z "$CHART_VERSION" ] || [ -z "$RELEASE_NAME" ] || [ -z "$CHART_NAMESPACE" ] || [ -z "$VALUES_FILE" ]; then
  echo "Error: One or more helm chart parameters are missing in $KUSTOMIZATION_FILE" >&2
  exit 1
fi

# Make sure values file exists (relative to TARGET_DIR)
VALUES_FILE_PATH="${TARGET_DIR}/${VALUES_FILE}"
if [ ! -f "$VALUES_FILE_PATH" ]; then
  echo "Error: Values file '$VALUES_FILE_PATH' not found." >&2
  exit 1
fi

echo "Using the following helm chart parameters:"
echo "  Chart Name:      $CHART_NAME"
echo "  Chart Repo:      $CHART_REPO"
echo "  Chart Version:   $CHART_VERSION"
echo "  Release Name:    $RELEASE_NAME"
echo "  Namespace:       $CHART_NAMESPACE"
echo "  Values File:     $VALUES_FILE_PATH"

# --- Define directories for generated manifests ---
BASE_DIR="${TARGET_DIR}/base"
OVERLAYS_DIR="${TARGET_DIR}/overlays"
PROD_OVERLAY="${OVERLAYS_DIR}/production"
DEV_OVERLAY="${OVERLAYS_DIR}/development"

mkdir -p "$BASE_DIR" "$PROD_OVERLAY" "$DEV_OVERLAY"

# --- Function: Render Helm chart to a single YAML file ---
render_helm_chart() {
  local output_file="$1"
  echo "Rendering helm chart..."
  helm template "$RELEASE_NAME" "$CHART_NAME" \
    --repo "$CHART_REPO" \
    --namespace "$CHART_NAMESPACE" \
    --version "$CHART_VERSION" \
    -f "$VALUES_FILE_PATH" > "$output_file"
}

# --- Function: Split rendered YAML into separate resource files ---
split_manifests() {
  local input_file="$1"
  local out_dir="$2"

  echo "Splitting rendered manifests from $input_file..."
  # Split on YAML document separator
  csplit -z -f "${out_dir}/split_" "$input_file" '/^---$/' '{*}'
  rm "$input_file"

  # Rename each file based on its kind and metadata.name (if available)
  for file in "${out_dir}/split_"*; do
    # Extract "kind" and "metadata.name" using yq if possible
    local kind
    kind=$(yq e '.kind // ""' "$file" | tr '[:upper:]' '[:lower:]')
    local name
    name=$(yq e '.metadata.name // ""' "$file")
    if [ -n "$kind" ] && [ -n "$name" ]; then
      local new_name="${kind}-${name}.yaml"
      mv "$file" "${out_dir}/${new_name}"
    else
      # Remove file if it doesn't contain valid resource info
      rm "$file"
    fi
  done
}

# --- Function: Create base kustomization.yaml ---
create_base_kustomization() {
  local out_dir="$1"
  local kustomization_file="${out_dir}/kustomization.yaml"
  echo "Creating base kustomization.yaml at $kustomization_file..."

  # List all YAML files in the base directory except kustomization.yaml
  local resources=""
  for f in "$out_dir"/*.yaml; do
    [[ $(basename "$f") == "kustomization.yaml" ]] && continue
    # Use relative path (file name only)
    resources+="  - $(basename "$f")"$'\n'
  done

  # Append external resources (announce.yaml and ip-pool.yaml from TARGET_DIR)
  resources+="  - ../announce.yaml"$'\n'
  resources+="  - ../ip-pool.yaml"$'\n'

  cat <<EOF > "$kustomization_file"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
$resources
EOF
}

# --- Function: Fetch CRDs dynamically ---
fetch_crds() {
  local out_file="$1"
  local url="https://raw.githubusercontent.com/cilium/cilium/v${CHART_VERSION}/install/kubernetes/cilium-crds.yaml"
  echo "Fetching CRDs from $url..."
  curl -sSL "$url" -o "$out_file"
}

# --- Function: Create overlay kustomization and sample patch ---
create_overlay() {
  local overlay_dir="$1"
  echo "Creating overlay in $overlay_dir..."
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
  name: cilium-config
  namespace: kube-system
data:
  kubeProxyReplacement: "true"
EOF
}

# --- Main workflow ---
main() {
  local rendered_yaml="${BASE_DIR}/rendered.yaml"

  # Step 1: Render Helm chart to YAML
  render_helm_chart "$rendered_yaml"

  # Step 2: Split the rendered YAML into individual manifests
  split_manifests "$rendered_yaml" "$BASE_DIR"

  # Step 3: Fetch CRDs into the base directory
  fetch_crds "${BASE_DIR}/crds.yaml"

  # Step 4: Create a base kustomization.yaml that references all files
  create_base_kustomization "$BASE_DIR"

  # Step 5: Create overlay directories (production and development)
  create_overlay "$PROD_OVERLAY"
  create_overlay "$DEV_OVERLAY"

  echo "Conversion completed successfully."
  echo "To deploy the base manifests: kubectl apply -k ${BASE_DIR}"
  echo "To deploy production overlay: kubectl apply -k ${PROD_OVERLAY}"
  echo "To deploy development overlay: kubectl apply -k ${DEV_OVERLAY}"
}

main
