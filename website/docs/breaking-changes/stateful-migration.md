---
title: 'Migrating Stateful Applications to StatefulSets'
---

This document guides users through the process of migrating stateful applications from an old Deployment model to a new StatefulSet model, ensuring no data is lost during the transition.

:::info
BREAKING CHANGE: This architectural change is considered a breaking change. If you have forked this repository and are pulling the latest updates, you must follow this guide to ensure your applications reconnect to their existing data.
:::

## Prerequisites

- **Backup Your Data:** Before you begin, it is strongly recommended to take a snapshot of your persistent volumes using your storage provider's tools (e.g., Longhorn's snapshot feature, Velero, etc.).
- **`kubectl` CLI:** You need `kubectl` installed and configured to connect to your Kubernetes cluster.
- **`jq` CLI:** The recovery script requires the command-line JSON processor `jq`. You can install it using your system's package manager.

  ```bash
  # Example for Debian/Ubuntu
  sudo apt-get update && sudo apt-get install jq
  ```

- **Argo CD Auto-Sync Disabled:** To prevent interference during the manual steps, ensure auto-sync is disabled in Argo CD for the applications you are migrating.

## Overview of steps/workflow

The migration involves a one-time data recovery procedure after you have pulled the latest Git commits.

1. **Pull Git Changes:** Update your local repository with the latest changes, which include the new StatefulSet manifests. Let Argo CD sync these changes. The new pods will likely start with empty volumes.
2. **Prepare the recovery script:** Create a shell script that automates detaching new empty volumes and re-attaching original data volumes.
3. **Execute the recovery:** Run the prepared script.
4. **Verify and Cleanup:** Confirm applications are running correctly with their original data, then re-enable auto-sync and remove any orphaned, empty volumes.

## Prepare the recovery script

This script performs the core recovery task. It finds your original, now-Released data volumes and makes them available for your new StatefulSet pods to claim and use.

1. **Create the `recover_data.sh` file:** Save the following content to a file named `recover_data.sh`.

    ```bash
    #!/bin/bash
    # A function to perform the data recovery for a single application
    # Usage: recover_app <statefulset_name> <namespace> <old_pvc_name> <new_pvc_template_name>
    recover_app() {
      local APP_NAME=$1
      local APP_NAMESPACE=$2
      local OLD_PVC_NAME=$3
      local NEW_PVC_NAME="${4}-${APP_NAME}-0"

      echo "------------------------------------------------------------------"
      echo "--- Processing App: ${APP_NAME} in Namespace: ${APP_NAMESPACE}"
      echo "------------------------------------------------------------------"

      # Step 1: Scale down the StatefulSet
      echo "Scaling down StatefulSet '${APP_NAME}'..."
      kubectl scale statefulset "${APP_NAME}" --replicas=0 -n "${APP_NAMESPACE}"
      if [ $? -ne 0 ]; then
        echo "WARNING: Could not scale down StatefulSet '${APP_NAME}'. It may not exist. Continuing..."
      fi
      sleep 5

      # Step 2: Delete the new, incorrect PVC
      echo "Deleting new (likely empty) PVC '${NEW_PVC_NAME}'..."
      kubectl delete pvc "${NEW_PVC_NAME}" -n "${APP_NAMESPACE}" --ignore-not-found=true

      # Step 3: Find the original 'Released' PV by looking for its old claim reference
      echo "Searching for original PV that was bound to '${OLD_PVC_NAME}'..."
      ORIGINAL_PV_NAME=$(kubectl get pv -o json | jq -r ".items[] | select(.spec.claimRef.name==\"${OLD_PVC_NAME}\" and .spec.claimRef.namespace==\"${APP_NAMESPACE}\" and .status.phase==\"Released\") | .metadata.name")

      if [ -z "$ORIGINAL_PV_NAME" ]; then
        echo "ERROR: Could not automatically find a 'Released' PV for old claim '${APP_NAMESPACE}/${OLD_PVC_NAME}'."
        echo "Please find it manually with 'kubectl get pv' and run the patch commands."
        echo "Skipping patches and scaling up '${APP_NAME}'."
        kubectl scale statefulset "${APP_NAME}" --replicas=1 -n "${APP_NAMESPACE}"
        return 1
      fi

      echo "Found original PV: ${ORIGINAL_PV_NAME}. Preparing it for adoption..."

      # Step 4: Patch the original PV to make it available
      echo "Patching PV '${ORIGINAL_PV_NAME}' reclaim policy to 'Retain'..."
      kubectl patch pv "${ORIGINAL_PV_NAME}" -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'

      echo "Patching PV '${ORIGINAL_PV_NAME}' to make it 'Available'..."
      kubectl patch pv "${ORIGINAL_PV_NAME}" --type json -p='[{"op": "remove", "path": "/spec/claimRef"}]'

      # Step 5: Scale the StatefulSet back up
      echo "Scaling up StatefulSet '${APP_NAME}'. It will now adopt the original PV."
      kubectl scale statefulset "${APP_NAME}" --replicas=1 -n "${APP_NAMESPACE}"

      # Step 6: Wait for the pod to be ready
      echo "Waiting for pod to become ready..."
      kubectl wait --for=condition=ready pod --selector=app=${APP_NAME} -n ${APP_NAMESPACE} --timeout=5m

      echo "✅  Successfully migrated ${APP_NAME}!"
      echo ""
    }

    # --- AI Applications ---
    recover_app "meilisearch" "karakeep" "meilisearch-pvc" "meilisearch-data"
    recover_app "web" "karakeep" "data-pvc" "data"
    recover_app "open-webui-deployment" "open-webui" "open-webui-pvc" "openwebui-data"

    # --- Media Applications ---
    # Note: For *arr apps, the old PVC was e.g. "bazarr-config" and the new template is just "config"
    recover_app "bazarr" "media" "bazarr-config" "config"
    recover_app "prowlarr" "media" "prowlarr-config" "config"
    recover_app "radarr" "media" "radarr-config" "config"
    recover_app "sonarr" "media" "sonarr-config" "config"
    recover_app "immich-server" "immich" "immich-library" "library"
    recover_app "sabnzbd" "media" "sabnzbd-config" "sabnzbd-config"

    # Jellyfin has two volumes to migrate
    recover_app "jellyfin" "media" "jellyfin-config" "config"
    recover_app "jellyfin" "media" "jellyfin-cache" "cache"

    # --- Network Applications ---
    # Omada has two volumes to migrate
    recover_app "omada-controller" "omada" "omada-data-pvc" "omada-data"
    recover_app "omada-controller" "omada" "omada-logs-pvc" "omada-logs"

    # --- Other Applications ---
    recover_app "unrar" "unrar" "unrar-data" "unrar-data"



    echo "------------------------------------------------------------------"
    echo "--- ALL MIGRATIONS COMPLETE ---"
    echo "------------------------------------------------------------------"
    echo "Please verify all applications are working correctly."
    echo "Once confirmed, you can re-enable auto-sync in Argo CD."

    ```

## Execute the recovery

1. **Make the script executable:**

    ```bash
    chmod +x recover_data.sh
    ```

2. **Run the script:**

    ```bash
    ./recover_data.sh
    ```

    The script will now iterate through each application and perform the recovery steps, providing progress in the terminal.

## Verify the steps

1. **Check PersistentVolumeClaims (PVCs):**
    Ensure the new PVCs (e.g., `config-sonarr-0`) have been created and are in the `Bound` state.

    ```bash
    kubectl get pvc -A
    ```

2. **Inspect Application Pods:**
    Check the logs for each newly created pod to ensure there are no startup errors.

    ```bash
    # Example for Sonarr
    kubectl logs -n media statefulset/sonarr
    ```

3. **Confirm Application Data:**
    Log in to the web UI for several key applications (e.g., Jellyfin, Radarr, Baby Buddy) and confirm that all your previous data, configurations, and history are present.

## Cleanup and Finalize

1. **Delete Orphaned Volumes:**
    The recovery process may leave behind the new, empty volumes that were created before the script was run. You can identify these in your storage provider's UI (e.g., Longhorn) and safely delete them to reclaim space. They will typically be in a `Released` state and small in size.
2. **Re-enable Argo CD Auto-Sync:**
    Once you are confident the migration was successful and all applications are stable, re-enable auto-sync in Argo CD for your applications.
