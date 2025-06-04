---
title: Documentation templates
---

In technical documentation, different types of content often follow established structures or "document types." This
project provides templates for common document types to simplify the contribution process and ensure consistency.

The most common types of documentation you might write for this project are:

- [**Combination (Combo) Topics**](./combo.tmpl.md): For many topics, especially when explaining a specific component or
  configuration set, it's useful to combine conceptual information (the "what" and "why") with procedural or structural
  information (the "how"). A guideline is: if the actionable steps or structural details are extensive and get buried
  under too much conceptual text, consider splitting into separate Conceptual and Procedural documents.

- [**Procedural Topics**](./procedural.tmpl.md): These are "how-to" guides. They provide step-by-step instructions for
  accomplishing a specific task, such as running a script, configuring a service, or performing a maintenance operation.

- [**Conceptual Topics**](./conceptual.tmpl.md): These documents explain the "why" and "what" behind a feature,
  component, design decision, or technology. They provide background, use cases, benefits, and important considerations.

- [**Reference Topics**](./reference.tmpl.md): This type of documentation typically consists of tables, lists, or
  detailed descriptions of specific items like configuration parameters, script arguments, API endpoints (if
  applicable), or resource definitions.

## Using a template

To use a template, you can download it directly into your local clone of the `homelab` repository using `wget` or a
similar tool. Navigate to the directory where you want to create your new documentation page (e.g.,
`website/docs/your-chosen-subdirectory/`) and run the appropriate command:

- **For the Combo Template:**

  ```bash
  wget https://raw.githubusercontent.com/theepicsaxguy/homelab/main/website/docs/writing-documentation/templates/combo.tmpl.md -O my-new-combo-topic.md
  ```

- **For the Conceptual Template:**

  ```bash
  wget https://raw.githubusercontent.com/theepicsaxguy/homelab/main/website/docs/writing-documentation/templates/conceptual.tmpl.md -O my-new-conceptual-topic.md
  ```

- **For the Procedural Template:**

  ```bash
  wget https://raw.githubusercontent.com/theepicsaxguy/homelab/main/website/docs/writing-documentation/templates/procedural.tmpl.md -O my-new-procedural-topic.md
  ```

- **For the Reference Template:**
  ```bash
  wget https://raw.githubusercontent.com/theepicsaxguy/homelab/main/website/docs/writing-documentation/templates/reference.tmpl.md -O my-new-reference-topic.md
  ```

Remember to replace `my-new-...-topic.md` with your desired filename. After downloading, open the file and fill in the
content according to the template's structure and the guidance provided in its corresponding `.md` guide file (e.g.,
[./combo.tmpl.md](./combo.tmpl.md) for the combo template).
