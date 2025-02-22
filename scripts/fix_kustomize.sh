#!/bin/sh

# Find all directories containing kustomization.yaml
kustomize_dirs=$(find . -type f -name "kustomization.yaml" -exec dirname {} \;)

if [ -z "$kustomize_dirs" ]; then
    echo "Error: No kustomization.yaml files found."
    exit 1
fi

# Loop through each kustomization directory and apply fix
for i in $kustomize_dirs; do
    echo
    echo "Fixing kustomization in $i"
    echo

    # Change to directory and run kustomize fix
    (cd "$i" && kustomize edit fix)

    fix_response=$?

    if [ $fix_response -ne 0 ]; then
        echo "Error fixing kustomization in $i"
        exit 1
    fi
done

echo
echo "Kustomization files successfully fixed!"
