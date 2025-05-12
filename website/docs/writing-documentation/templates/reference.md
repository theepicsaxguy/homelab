---
title: Reference topic template guide
---

:::info **How to use this template guide**: This page explains the sections of the "Reference" topic template. To create
a new document using this template, start with the markdown version by copying the
[`reference.tmpl.md`](https://github.com/theepicsaxguy/homelab/blob/main/docs/docs/templates/reference.tmpl.md) file
from the GitHub repository or by downloading it:

```bash
wget https://raw.githubusercontent.com/theepicsaxguy/homelab/main/website/docs/writing-documentation/templates/reference.tmpl.md -O your-reference-topic-name.md
```

Edit your new markdown file, referring to this page for descriptions of each section. You can build out a "stub file"
with just headers, then gradually add content. Use screenshots sparingly, if at all, for reference material. Refer to
our [Documentation style guide](../style-guide.mdx) for writing tips and project-specific rules. :::

Create a title that specifies the component, parameters, or data you are documenting. For example, "ArgoCD
ApplicationSet parameters," "Kustomization options," or "Script `validate_argocd.sh` arguments."

Provide a sentence or two introducing the subject of the reference material.

Reference documentation provides details, values, syntax, options, or other factual information about specific elements
of the system. This could include:

- Configuration parameters for a tool or manifest.
- Arguments and options for a command-line script.
- Data structures or API field descriptions (if applicable).
- Lists of supported values for a particular setting.

## [First Category of Reference Items]

Use a descriptive H2 title for each major category of reference information. For instance, "Generator parameters" for an
ApplicationSet, or "Environment variables" for a script.

After the heading, add a sentence or two to explain what this section covers or how the listed items are used.

Use tables, bullet lists, or definition lists (using H3s for terms and paragraphs for definitions) to clearly present
the reference information.

### [Sub-Category or Specific Item 1] (Optional H3)

If the H2 category is broad, use H3 headings to break it down further or to detail individual items. Provide a brief
explanation for this sub-grouping.

**Parameter/Attribute/Option Name:** `parameter_name`

- **Description:** A clear explanation of what this item represents or controls.
- **Type:** (e.g., string, boolean, integer, list)
- **Required:** (e.g., Yes, No, Conditional)
- **Default Value:** (If applicable)
- **Allowed Values/Format:** (If there's a specific set of allowed values or a format to follow)
- **Example:**

  ```yaml
  parameter_name: 'example_value'
  ```

### [Sub-Category or Specific Item 2] (Optional H3)

**Parameter/Attribute/Option Name:** `another_item`

- **Description:** ...
- ...

## [Second Category of Reference Items]

Continue with other major categories as needed, following the same structure.
