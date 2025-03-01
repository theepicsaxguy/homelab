#!/bin/bash

# Usage function to display help
usage() {
    echo "Usage: $0 [-r] [-o] [-i ignore_dir]... <directory>"
    echo "  -r               Process directories recursively (default: non-recursive)"
    echo "  -o               Override existing kustomization.yaml files (force regeneration)"
    echo "  -i ignore_dir    Ignore directory with name 'ignore_dir'. Can be specified multiple times."
    exit 1
}

# Initialize default values
RECURSIVE=false
OVERRIDE=false
IGNORE_PATTERNS=()

# Parse options
while getopts ":roi:" opt; do
    case ${opt} in
        r )
            RECURSIVE=true
            ;;
        o )
            OVERRIDE=true
            ;;
        i )
            IGNORE_PATTERNS+=("$OPTARG")
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        : )
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

shift $((OPTIND -1))

# Ensure a directory argument is provided
if [ -z "$1" ]; then
    usage
fi

TARGET_DIR="$1"

# Verify that the provided path exists and is a directory
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

# Function to decide if a directory should be ignored
should_ignore() {
    local dir_basename
    dir_basename=$(basename "$1")
    for pattern in "${IGNORE_PATTERNS[@]}"; do
        if [ "$dir_basename" == "$pattern" ]; then
            return 0
        fi
    done
    return 1
}

# Process a given directory: check for kustomization.yaml and YAML files.
process_directory() {
    local dir="$1"

    # Skip if directory is to be ignored
    if should_ignore "$dir"; then
        echo "⚠️ Ignoring: $dir (matches ignore pattern)"
        return
    fi

    # Remove existing kustomization.yaml if OVERRIDE is set
    if [ "$OVERRIDE" = true ] && [ -f "$dir/kustomization.yaml" ]; then
        echo "⚠️ Overriding: $dir (removing existing kustomization.yaml)"
        rm -f "$dir/kustomization.yaml"
    fi

    # Skip if kustomization.yaml already exists (and OVERRIDE not set)
    if [ -f "$dir/kustomization.yaml" ]; then
        echo "⚠️ Skipping: $dir (kustomization.yaml already exists)"
        return
    fi

    # Check if the directory contains YAML files
    if find "$dir" -maxdepth 1 -type f \( -name "*.yaml" -o -name "*.yml" \) | grep -q .; then
        echo "🔄 Processing: $dir"
        (cd "$dir" && kustomize create --autodetect && echo "✅ Created kustomization.yaml in $dir") || echo "❌ Failed in $dir"
    else
        echo "⚠️ Skipping: $dir (no YAML files found)"
    fi
}

if [ "$RECURSIVE" = true ]; then
    # Build ignore arguments for find: for each ignore pattern, add '-not -name <pattern>'
    IGNORE_ARGS=()
    for pattern in "${IGNORE_PATTERNS[@]}"; do
        IGNORE_ARGS+=("-not" "-name" "$pattern")
    done
    # Find only directories (with -type d) applying ignore patterns
    find "$TARGET_DIR" -type d "${IGNORE_ARGS[@]}" | while read -r dir; do
        process_directory "$dir"
    done
else
    # Non-recursive: only process the TARGET_DIR
    process_directory "$TARGET_DIR"
fi

echo "🚀 Kustomization creation complete!"
