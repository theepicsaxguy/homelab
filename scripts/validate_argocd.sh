#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 Validating ArgoCD resources..."

# Function to validate a specific app or appset
validate_resource() {
    local path=$1
    local type=$2
    echo -e "${YELLOW}Validating $type in $path${NC}"
    
    # Use argocd app diff with local files
    if ! argocd app diff --local "$path" 2>/dev/null; then
        echo -e "${RED}❌ Validation failed for $type in $path${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Validation passed for $type in $path${NC}"
    return 0
}

# Validate all ApplicationSets
find_and_validate() {
    local base_path=$1
    local failures=0
    
    # Find and validate all application-set.yaml files
    while IFS= read -r -d '' file; do
        dir=$(dirname "$file")
        if ! validate_resource "$dir" "ApplicationSet"; then
            ((failures++))
        fi
    done < <(find "$base_path" -type f -name "application-set.yaml" -print0)
    
    # Find and validate all applications.yaml files
    while IFS= read -r -d '' file; do
        dir=$(dirname "$file")
        if ! validate_resource "$dir" "Application"; then
            ((failures++))
        fi
    done < <(find "$base_path" -type f -name "applications.yaml" -print0)
    
    # Find and validate all rollout files
    while IFS= read -r -d '' file; do
        dir=$(dirname "$file")
        if ! validate_resource "$dir" "Rollout"; then
            ((failures++))
        fi
    done < <(find "$base_path" -type f -name "*rollout*.yaml" -print0)
    
    return "$failures"
}

# Main validation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Validating ArgoCD resources in k8s directory..."
failures=0

# Validate infrastructure components
if ! find_and_validate "$PROJECT_ROOT/k8s/infra"; then
    ((failures++))
fi

# Validate applications
if ! find_and_validate "$PROJECT_ROOT/k8s/apps"; then
    ((failures++))
fi

# Validate sets directory
if ! find_and_validate "$PROJECT_ROOT/k8s/sets"; then
    ((failures++))
fi

if [ "$failures" -gt 0 ]; then
    echo -e "${RED}❌ Validation failed with $failures errors${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All ArgoCD resources validated successfully${NC}"
fi