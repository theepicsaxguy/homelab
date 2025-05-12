---
title: Combination topic template guide
---

:::info **How to use this template guide**: This page explains the sections of the "Combination" (Combo) topic template.
To create a new document using this template, start with the markdown version by copying the
[`combo.tmpl.md`](https://github.com/theepicsaxguy/homelab/blob/main/docs/docs/templates/combo.tmpl.md) file from the
GitHub repository or by downloading it:

```bash
wget https://raw.githubusercontent.com/theepicsaxguy/homelab/main/website/docs/writing-documentation/templates/combo.tmpl.md -O your-topic-name.md
```

Edit your new markdown file, referring to this page for descriptions of each section. You can build out a "stub file"
with just headers, then gradually add content. Use screenshots sparingly, only for complex UIs or where visual context
is essential and difficult to describe with words. Refer to our [Documentation style guide](../style-guide.mdx) for
writing tips and project-specific rules. :::

For a combination topic, the title is typically the name of the feature, component, or configuration being described
(e.g., "ArgoCD ApplicationSet for infrastructure" or "Longhorn storage configuration").

In the first section, immediately after the title (with no H2 heading), write one or two sentences providing a brief
overview of the topic.

## About [Feature/Component XYZ]

In this section, provide a more detailed explanation of the feature, component, or configuration. Discuss its purpose,
typical use cases within the homelab context, and its general role in the system.

### More details about [Feature/Component XYZ] (Optional Sub-section)

Use this H3 sub-section if there are several distinct aspects or categories of information that the reader needs to
understand about the subject. Add as many of these H3 sections as needed to break down complex information logically.

## Prerequisites (Optional Section)

If applicable, inform the reader of anything they need to have configured, installed, or understood _before_ they
proceed with any steps or try to implement the described configuration. This could include:

- Required tools (e.g., `kubectl`, `terraform`).
- Previously configured components (e.g., "Ensure ArgoCD is bootstrapped").
- Access credentials or specific permissions.

## Overview of [Steps/Workflow/Configuration Structure] (Optional Section)

If the topic involves a complex procedure, a multi-step workflow, or an intricate configuration structure, it can be
beneficial to provide a high-level overview here. This might be a bulleted list of the main stages or even a simple
text-based diagram of the workflow, allowing the reader to grasp the overall picture before diving into details.

## [First Group of Steps or Configuration Details]

If the topic involves many steps or detailed configuration aspects, try to group them logically under descriptive H2 or
H3 titles.

In this section, orient the reader. For example, specify which file they should be editing, what CLI they might be
using, or what conceptual area is being addressed.

For procedural parts, present each step clearly. Start instructions with the desired goal, followed by the specific
actions.

**Example procedural instruction:** "To define a new environment variable for a Deployment, you modify the `env` section
of the container specification in the `deployment.yaml` file."

## [Next Group of Steps or Configuration Details] (If needed)

Continue with further steps or details, maintaining logical grouping.

Use screenshots very sparingly. For this project, which is primarily configuration-as-code, clear YAML/code snippets are
usually more effective than screenshots of UIs (unless a specific UI interaction is being documented, e.g., for ArgoCD
or Longhorn UI).

Provide as many relevant code snippets (YAML, Bash, Terraform, etc.) and examples as necessary to clarify the
configuration or procedure.

## Verify the [Configuration/Setup/Process]

Whenever possible, conclude procedural or detailed configuration topics with steps on how the reader can verify that
their setup is correct or that the process was successful.

**Example verification steps:**

- "To verify that the ArgoCD Application is synced, navigate to the ArgoCD UI or run `argocd app get <app-name>`."
- "Check the pod logs for any errors: `kubectl logs -n <namespace> <pod-name>`."
