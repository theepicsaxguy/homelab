#!/bin/bash
# shellcheck disable=SC2034,SC2044

# Environment variables
export HELM_KUBEVERSION=v1.32.0
export KUBE_VERSION=1.32.0

display_help(){
  echo "./$(basename "$0") [ -d | --directory DIRECTORY ] [ -e | --enforce-all-schemas ] [ -h | --help ] [ -sl | --schema-location ]
Script to validate the manifests generated by Kustomize
Where:
  -d  | --directory DIRECTORY  Base directory containing Kustomize overlays
  -e  | --enforce-all-schemas  Enable enforcement of all schemas
  -h  | --help                 Display this help text
  -sl | --schema-location      Location containing schemas"
}

# Check required tools
which kustomize >/dev/null 2>&1 && KUSTOMIZE_CMD="kustomize build" || { echo "Error: kustomize not found"; exit 1; }
which helm >/dev/null 2>&1 && GOT_HELM="--enable-helm" || { echo "Error: helm not found"; exit 1; }
which kubeconform >/dev/null 2>&1 || { echo "Error: kubeconform not found"; exit 1; }

IGNORE_MISSING_SCHEMAS="--ignore-missing-schemas"
SCHEMA_LOCATION="./k8s-json-schema/${KUBE_VERSION}"
KUSTOMIZE_DIRS="."

init(){
  for i in "${@}"
  do
    case $i in
      -d | --directory )
        shift
        KUSTOMIZE_DIRS="${1}"
        shift
        ;;
      -e | --enforce-all-schemas )
        IGNORE_MISSING_SCHEMAS=""
        shift
        ;;
      -sl | --schema-location )
        shift
        SCHEMA_LOCATION="${1}"
        shift
        ;;
      -h | --help )
        display_help
        exit 0
        ;;
      -*) echo >&2 "Invalid option: " "${@}"
        exit 1
        ;;
    esac
  done
}

validate_manifest() {
  local manifest=$1
  echo "Validating manifest against Kubernetes ${KUBE_VERSION}..."
  if ! echo "$manifest" | kubeconform -kubernetes-version "${KUBE_VERSION}" ${IGNORE_MISSING_SCHEMAS} -schema-location "${SCHEMA_LOCATION}" -; then
    echo "[ERROR] Kubernetes schema validation failed"
    return 1
  fi
  return 0
}

kustomization_build(){
  BUILD=${1}
  local KUSTOMIZE_BUILD_OUTPUT
  
  echo "Building ${BUILD}..."
  if [ -n "${GOT_HELM}" ]; then
    KUSTOMIZE_BUILD_OUTPUT=$(${KUSTOMIZE_CMD} "${BUILD}" "${GOT_HELM}")
  else
    if grep -qe '^helmCharts:$' "${BUILD}/kustomization.yaml" ; then
      echo "[ERROR] Helm charts found but helm support is not available"
      exit 1
    fi
    KUSTOMIZE_BUILD_OUTPUT=$(${KUSTOMIZE_CMD} "${BUILD}")
  fi
  
  if [ $? -ne 0 ]; then
    if grep -qe '^kind: Component$' "${BUILD}/kustomization.yaml"; then
      echo "[SKIP] Component detected"
      return 0
    fi
    echo "[ERROR] Kustomize build failed for ${BUILD}"
    exit 1
  fi

  if ! validate_manifest "$KUSTOMIZE_BUILD_OUTPUT"; then
    echo "[ERROR] Validation failed for ${BUILD}"
    exit 1
  fi

  echo "[OK] ${BUILD} passed validation"
}

kustomization_process(){
  echo "Validating all Kustomizations..."
  for LINT in $(find "${KUSTOMIZE_DIRS}" -name "kustomization.yaml" -exec dirname {} \;)
  do
    echo "Validating: ${LINT}"
    kustomization_build "${LINT}"
  done
  echo "Kustomize validation check passed!"
}

init "${@}"
kustomization_process
