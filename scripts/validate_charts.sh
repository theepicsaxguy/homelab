#!/bin/bash

# Set strict mode
set -euo pipefail

# Function to extract Helm chart locations from kustomization files
find_helm_charts() {
    local kustomization_dirs=$(find k8s -type f -name "kustomization.yaml" -exec dirname {} \;)
    local chart_dirs=()
    
    for dir in $kustomization_dirs; do
        if grep -q "helmCharts:" "$dir/kustomization.yaml"; then
            # If directory has charts subdirectory, validate those charts
            if [ -d "$dir/charts" ]; then
                chart_dirs+=("$dir/charts")
            fi
        fi
    done
    
    echo "${chart_dirs[@]:-}"
}

# Find all Helm chart directories
chart_dirs=$(find_helm_charts)

if [ -z "$chart_dirs" ]; then
    echo "Info: No Helm charts found in kustomization directories."
    exit 0
fi

# Track overall validation status
validation_status=0

# Set Kubernetes version for validation
export HELM_KUBEVERSION="${HELM_KUBEVERSION:-v1.32.0}"
echo "Using Kubernetes version: $HELM_KUBEVERSION"

# Loop through each chart directory and lint it
for base_dir in $chart_dirs; do
    for chart_dir in $(find "$base_dir" -type f -name "Chart.yaml" -exec dirname {} \;); do
        echo "==> Validating chart in $chart_dir"
        
        if ! helm lint "$chart_dir"; then
            echo "Error: Chart validation failed for $chart_dir"
            validation_status=1
        fi
        
        # Add a separator between charts
        echo "-----------------------------------"
    done
done

if [ $validation_status -eq 0 ]; then
    echo "✅ All charts successfully validated!"
    exit 0
else
    echo "❌ Chart validation failed!"
    exit 1
fi
