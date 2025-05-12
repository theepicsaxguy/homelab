---
title: Documentation templates
---

In technical documentation, different types of content often follow established structures or "document types." This
project provides templates for common document types to simplify the contribution process and ensure consistency.

The most common types of documentation you might write for this project are:

- [**Combination (Combo) Topics**](./combo.md): For many topics, especially when explaining a specific component or
  configuration set, it's useful to combine conceptual information (the "what" and "why") with procedural or structural
  information (the "how"). A guideline is: if the actionable steps or structural details are extensive and get buried
  under too much conceptual text, consider splitting into separate Conceptual and Procedural documents.

- [**Procedural Topics**](./procedural.md): These are "how-to" guides. They provide step-by-step instructions for
  accomplishing a specific task, such as running a script, configuring a service, or performing a maintenance operation.

- [**Conceptual Topics**](./conceptual.md): These documents explain the "why" and "what" behind a feature, component,
  design decision, or technology. They provide background, use cases, benefits, and important considerations.

- [**Reference Topics**](./reference.md): This type of documentation typically consists of tables, lists, or detailed
  descriptions of specific items like configuration parameters, script arguments, API endpoints (if applicable), or
  resource definitions.

### Using a template

To use a template:

1. Identify the most appropriate template type for the content you plan to write.
2. Copy the content of the corresponding `.tmpl.md` file (e.g., `combo.tmpl.md`) into a new `.md` file in the
    appropriate `/docs` subdirectory.
3. Follow the guidance within the chosen template and our general [Documentation style guide](../style-guide.mdx) to
    fill in your content.

**Example `wget` commands to download templates:**

(Ensure you are in the directory where you want to save the template)

- **Combo Template:**

  ```bash
  wget https://raw.githubusercontent.com/theepicsaxguy/homelab/main/docs/docs/templates/combo.tmpl.md -O my-new-combo-topic.md
  ```

- **Procedural Template:**

  ```bash
  wget https://raw.githubusercontent.com/theepicsaxguy/homelab/main/docs/docs/templates/procedural.tmpl.md -O my-new-procedural-guide.md
  ```

- **Conceptual Template:**

  ```bash
  wget https://raw.githubusercontent.com/theepicsaxguy/homelab/main/docs/docs/templates/conceptual.tmpl.md -O my-new-conceptual-overview.md
  ```

- **Reference Template:**

  ```bash
  wget https://raw.githubusercontent.com/theepicsaxguy/homelab/main/docs/docs/templates/reference.tmpl.md -O my-new-reference-sheet.md
  ```

Replace `my-new-...` with your desired filename.
