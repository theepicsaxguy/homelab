#!/bin/sh

for i in `find "${HELM_DIRS}" -name "Chart.yaml" -exec dirname {} \;`;
do

    echo
    echo "Validating $i"
    echo

    helm lint $i

    build_response=$?

    if [ $build_response -ne 0 ]; then
        echo "Error linting $i"
        exit 1
    fi

done

echo
echo "Charts successfully validated!"
