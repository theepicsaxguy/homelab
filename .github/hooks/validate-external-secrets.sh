#!/bin/bash

# Validate External Secrets manifests
validate_external_secrets() {
    local file="$1"
    local errors=0

    # Check if file is an ExternalSecret
    if grep -q "kind: ExternalSecret" "$file"; then
        # Verify required fields
        if ! grep -q "spec.secretStoreRef" "$file"; then
            echo "Error: $file missing required field 'spec.secretStoreRef'"
            errors=$((errors + 1))
        fi
        
        if ! grep -q "spec.target" "$file"; then
            echo "Error: $file missing required field 'spec.target'"
            errors=$((errors + 1))
        fi

        if ! grep -q "spec.data" "$file"; then
            echo "Error: $file missing required field 'spec.data'"
            errors=$((errors + 1))
        fi

        # Verify refresh interval is set and not too frequent
        if ! grep -q "refreshInterval:" "$file"; then
            echo "Warning: $file missing refreshInterval"
        else
            interval=$(grep "refreshInterval:" "$file" | awk '{print $2}')
            if [[ $interval == "1m" || $interval == "5m" ]]; then
                echo "Warning: $file has very short refresh interval: $interval"
            fi
        fi
    fi

    return $errors
}

# Find all yaml files
find . -type f -name "*.yaml" -o -name "*.yml" | while read -r file; do
    validate_external_secrets "$file"
done