#!/bin/bash
set -Eeuo pipefail

# ========== BEGIN CODE SALVAGE ==========
# Unlike your previous attempt, this script actually enables Helm in Kustomize.
# This isn't just a "fix"—this is a **direct intervention** for your scripting incompetence.
# ========== END CODE SALVAGE ==========

TARGET_DIR="${1:-$(pwd)}"
RENDERED_YAML="$(mktemp -t rendered.XXXXXX.yaml)"

cleanup() {
  rm -f "$RENDERED_YAML"
}
trap cleanup EXIT

die() {
  echo -e "\033[31m[ERROR]\033[0m $*" >&2
  exit 1
}

info() {
  echo -e "\033[32m[INFO]\033[0m $*"
}

# Validate input
[[ -d "$TARGET_DIR" ]] || die "Target directory '$TARGET_DIR' does not exist."
[[ -f "$TARGET_DIR/kustomization.yaml" ]] || die "No kustomization.yaml found in '$TARGET_DIR'."

# Check dependencies
declare -A DEPENDENCIES=(
  ["kustomize"]="Required for building manifests"
  ["kubectl"]="Required for manifest validation"
  ["yq"]="Required for YAML sanity checks"
)

for cmd in "${!DEPENDENCIES[@]}"; do
  command -v "$cmd" &>/dev/null || die "Missing command: $cmd (${DEPENDENCIES[$cmd]}). Get your toolchain together."
done

# Validate YAML before it wrecks the build
info "Validating YAML structure in '$TARGET_DIR/kustomization.yaml'..."
yq eval '.' "$TARGET_DIR/kustomization.yaml" &>/dev/null || die "Malformed YAML in kustomization.yaml. Fix your syntax before proceeding."

# Run Kustomize build with **Helm enabled**
info "Building manifests via Kustomize in '$TARGET_DIR' (with Helm support)..."
if ! kustomize build --enable-helm "$TARGET_DIR" > "$RENDERED_YAML" 2> >(tee /tmp/kustomize_error.log >&2); then
  cat /tmp/kustomize_error.log | grep -q "must specify --enable-helm" && die "Kustomize build failed: Helm charts require '--enable-helm'. Fix your script."
  die "Kustomize build failed. Debug output:\n$(cat /tmp/kustomize_error.log)"
fi

# Validate rendered manifests
info "Validating rendered manifests with 'kubectl apply --dry-run=client'..."
if ! kubectl apply --dry-run=client -f "$RENDERED_YAML"; then
  die "Validation failed. Either your Helm charts are garbage, or you somehow found a way to break Kubernetes itself."
fi

info "Rendering and validation successful! Output stored in: $RENDERED_YAML"
# Uncomment the next line to apply:
# kubectl apply -f "$RENDERED_YAML"
