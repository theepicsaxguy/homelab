---
title: 'Markdown template: Procedural topic'
---

Provide a brief (1-2 sentence) description of the task this document will guide the user through.

:::info If needed, use this syntax to add an informational note related to the overall procedure or a key concept. :::

## Prerequisites (Optional)

- List any tools, access, or prior configurations required before starting these steps.
- **Example:** `kubectl` CLI installed and configured for your cluster.
- **Example:** Write access to the `/k8s/` directory in the Git repository.

## Overview of steps/workflow (Optional, for complex procedures)

Briefly outline the main stages or the overall flow of the task.

1.  Prepare configuration files.
2.  Apply changes to the cluster.
3.  Verify the outcome.

## [First group of steps: e.g., Prepare the configuration]

1.  **First action:** Clearly state the goal of this step. Provide specific instructions. If it's a command, show it in
    a code block.

    ```bash
    # Example command
    echo "Preparing step 1"
    ```

    If it involves editing a file, specify the file and what to change. **Example:** Modify the `foo.bar` key in
    `/path/to/your/config.yaml`:

    ```yaml
    # /path/to/your/config.yaml
    foo:
      bar: 'new_value' # Update this line
    ```

    :::info An optional note specific to this step, explaining rationale or important details. :::

2.  **Second action:** ...

## [Next group of steps: e.g., Apply and deploy] (If needed)

Continue with further logical groupings of steps.

3.  **Third action:** ...
    ```bash
    # Another example command
    kubectl apply -f /path/to/your/config.yaml
    ```

## Verify the steps

Provide commands or checks the user can perform to confirm the procedure was successful.

1.  **Check pod status:**

    ```bash
    kubectl get pods -n your-namespace
    ```

    Ensure all relevant pods are in a `Running` state.

2.  **Inspect logs (if applicable):**
    ```bash
    kubectl logs -n your-namespace deployment/your-deployment-name
    ```
    Look for confirmation messages or lack of errors.
