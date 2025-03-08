#!/bin/bash
set -euo pipefail

validate_policy() {
    local file="$1"
    # Check for required fields
    if ! yq e '.spec.description' "$file" > /dev/null 2>&1; then
        echo "Error: Missing description in $file"
        return 1
    fi

    # Validate CIDR notation
    if grep -q "cidr:" "$file"; then
        if ! grep -E "cidr: \"([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}\"" "$file" > /dev/null; then
            echo "Error: Invalid CIDR notation in $file"
            return 1
        fi
    fi

    # Validate port specifications
    if grep -q "port:" "$file"; then
        if ! grep -E "port: '[0-9]+'|port: \"[0-9]+\"" "$file" > /dev/null; then
            echo "Error: Port must be quoted in $file"
            return 1
        fi
    fi

    # Validate TLS version specifications
    if grep -q "TLS" "$file"; then
        if ! grep -E "TLSv[0-9]+\.[0-9]+" "$file" > /dev/null; then
            echo "Error: Invalid TLS version specification in $file"
            return 1
        fi
    fi

    return 0
}

# Find all policy files
find k8s/infrastructure/network/policies -type f -name "*.yaml" | while read -r file; do
    echo "Validating $file..."
    if ! validate_policy "$file"; then
        exit 1
    fi
done
