#!/bin/bash

# Set strict mode
set -euo pipefail

# Find all directories containing Chart.yaml, starting from k8s directory
chart_dirs=$(find k8s -type f -name "Chart.yaml" -exec dirname {} \;)

if [ -z "$chart_dirs" ]; then
    echo "Info: No Helm charts found in k8s directory."
    exit 0
fi

# Track overall validation status
validation_status=0

# Loop through each chart directory and lint it
for chart_dir in $chart_dirs; do
    echo "==> Validating chart in $chart_dir"

    if ! helm lint "$chart_dir"; then
        echo "Error: Chart validation failed for $chart_dir"
        validation_status=1
    fi

    # Add a separator between charts
    echo "-----------------------------------"
done

if [ $validation_status -eq 0 ]; then
    echo "✅ All charts successfully validated!"
    exit 0
else
    echo "❌ Chart validation failed!"
    exit 1
fi
