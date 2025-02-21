#!/bin/bash

display_help(){
  echo "./$(basename "$0") [ -d | --directory DIRECTORY ] [ -h | --help ]
Script to fix and update Kustomize configurations
Where:
  -d  | --directory DIRECTORY  Base directory containing Kustomize overlays
  -h  | --help                 Display this help text"
}

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

fix_kustomization(){
  echo "Fixing Kustomize configurations..."

  for DIR in $(find "${KUSTOMIZE_DIRS}" -name "kustomization.yaml" -exec dirname {} \;)
  do
    echo "Processing ${DIR}"
    pushd "${DIR}" || continue
    kustomize edit fix
    popd || continue
  done

  echo "Kustomize fix completed successfully!"
}

init "${@}"
fix_kustomization
