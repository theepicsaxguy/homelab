#!/bin/sh

# Find all directories containing Chart.yaml
chart_dirs=$(find . -type f -name "Chart.yaml" -exec dirname {} \;)

if [ -z "$chart_dirs" ]; then
    echo "Error: No Helm charts found."
    exit 1
fi

# Loop through each chart directory and lint it
for i in $chart_dirs; do
    echo
    echo "Validating $i"
    echo

    helm lint "$i"
    build_response=$?

    if [ $build_response -ne 0 ]; then
        echo "Error linting $i"
        exit 1
    fi
done

echo
echo "Charts successfully validated!"
