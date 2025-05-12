---
title: Procedural topic template guide
---

:::info **How to use this template guide**: This page explains the sections of the "Procedural" topic template. To
create a new document using this template, start with the markdown version by copying the
[`procedural.tmpl.md`](https://github.com/theepicsaxguy/homelab/blob/main/docs/docs/templates/procedural.tmpl.md) file
from the GitHub repository or by downloading it:

```bash
wget https://raw.githubusercontent.com/theepicsaxguy/homelab/main/docs/docs/templates/procedural.tmpl.md -O your-procedural-guide-name.md
```

Edit your new markdown file, referring to this page for descriptions of each section. You can build out a "stub file"
with just headers, then gradually add content. Use screenshots sparingly. Refer to our
[Documentation style guide](../style-guide.mdx) for writing tips and project-specific rules. :::

For a procedural topic, use a title that focuses on the task you are writing about. The title should generally start
with an imperative verb and clearly state the objective. For example, "Configure a new ArgoCD application" or "Run the
validation script."

In the first section, right after the title (with no H2 heading), write one or two sentences briefly describing the task
that will be accomplished by following the steps in this guide. Keep it concise; if extensive conceptual background is
needed, consider a separate conceptual topic or a "Combination" topic. The goal is to let readers quickly understand if
this guide is relevant to their needs and then get to Step 1.

## Prerequisites (Optional Section)

In this section, inform the reader of anything they need to do, have configured, or have installed _before_ they begin
following the procedural instructions below. Examples:

- Required tools (e.g., "`kubectl` version 1.25 or higher," "`helm` CLI installed").
- Necessary access or permissions (e.g., "Cluster administrator privileges," "Write access to the Git repository").
- Previously completed configurations (e.g., "ArgoCD must be bootstrapped," "A `kubeconfig` file pointing to the target
  cluster").
- Specific files or information needed (e.g., "The IP address of the NFS server," "Your GitHub Personal Access Token").

## Overview of steps/workflow (Optional Section)

If the task is particularly long, involves multiple distinct stages, or has a complex workflow, it can be very helpful
to provide a high-level overview here. This might be a bulleted list of the main steps or phases. This allows the reader
to understand the overall process before diving into the detailed, step-by-step instructions.

## [First group of steps: e.g., Prepare the environment]

If the procedure involves a significant number of steps, try to group them into logical sections with descriptive H2 or
H3 titles.

In this section, orient the reader. Clarify where they need to be (e.g., "in the root directory of the repository,"
"logged into the Kubernetes control plane node via SSH") or what tools they will be using for this group of steps.

Provide each step as a numbered item or a clearly distinct paragraph. Start instructions with the desired goal or
action.

**Example step format:**

1. **Navigate to the configuration directory:** Open your terminal and change to the `/k8s/applications/my-app`
   directory.

   ```bash
   cd /k8s/applications/my-app
   ```

2. **Modify the `replicas` count:** Open the `deployment.yaml` file and update the `spec.replicas` field to the desired
   number. **Example**:

   ```yaml
   # deployment.yaml
   apiVersion: apps/v1
   kind: Deployment
   # ...
   spec:
     replicas: 3 # Change this value
   # ...
   ```

## [Next group of steps: e.g., Apply the configuration] (If needed)

Continue with subsequent groups of steps as necessary.

Use screenshots very sparingly, primarily for Web UIs where describing the interaction verbally is difficult or
significantly less clear than a visual. For a configuration-as-code project, YAML/code snippets are usually more
effective.

Provide as many code snippets, command examples, or configuration samples as needed to make the instructions clear and
unambiguous.

## Verify the steps

Use a heading such as "Verify the deployment" or "Confirm successful configuration." Whenever practical, conclude a
procedural topic with steps the user can take to confirm that the task was completed successfully and the system is in
the expected state.

**Example verification steps:**

- "To confirm that the application pods are running, execute:

  ```bash
  kubectl get pods -n my-app-namespace -l app=my-app
  ```

  You should see the specified number of pods in the `Running` state."

- "Check the application logs for any startup errors:

  ````bash
  kubectl logs -n my-app-namespace -l app=my-app --tail=50
  ```"
  ````
