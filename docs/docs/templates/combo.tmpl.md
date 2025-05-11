---
title: 'Markdown template: Combination topic'
---

Provide a brief (1-2 sentence) description of the feature, component, or configuration this document covers.

## About [Feature/Component XYZ]

In this section, provide a more detailed explanation. Discuss typical use cases, its role in the system, and any core
concepts.

:::info If needed, use this syntax to add an informational note, provide rationale, or highlight key considerations. :::

### More details about [Feature/Component XYZ] (Optional Sub-section)

Use this H3 sub-section for distinct aspects or categories of information. Add as many as needed.

## Prerequisites (Optional)

- List any prerequisite tools, configurations, or knowledge.
- **Example:** Ensure `kubectl` is configured to access the cluster.

## Overview of [Steps/Workflow/Configuration Structure] (Optional, for complex topics)

Describe the high-level view before diving into details. This can be a bullet list of main stages or a brief explanation
of the overall structure.

## [First main section of steps or configuration details]

Orient the reader (e.g., "The following settings are configured in the `/k8s/example/kustomization.yaml` file:").

1. **First step or configuration item:** Explain the goal, then the action.

   - Provide details.
   - **Example:** To set the replica count, modify the `spec.replicas` field in your `Deployment` manifest.

     ```yaml
     # /k8s/apps/my-app/deployment.yaml
     apiVersion: apps/v1
     kind: Deployment
     metadata:
       name: my-app
     spec:
       replicas: 3 # Set desired replica count here
     # ...
     ```

2. **Second step or configuration item:** ...

## [Next main section of steps or configuration details] (If needed)

Continue with further steps or details, maintaining logical grouping.

## Verify the [Configuration/Setup/Process]

Provide steps for the user to verify that the configuration is correct or the process was successful.

- **Example:** After applying the manifests, verify that the pods are running:

  ```bash
  kubectl get pods -n your-namespace
  ```

- Check logs for any errors:

  ```bash
  kubectl logs -n your-namespace -l app=your-app-label
  ```
