---
title: Writing documentation for this project
---

Contributing documentation is a valuable way for users of all experience levels to improve and support this homelab
project. We appreciate all contributions, from fixing simple typos to adding substantial new content or creating
entirely new topics.

To ensure a smooth process for reviewing and merging your documentation contributions (Pull Requests - PRs), please
adhere to the following guidelines.

- Ideally, when making documentation contributions, you should fork and clone the
  [homelab repository](https://github.com/theepicsaxguy/homelab). While much writing and editing can be done directly
  within the GitHub UI, local editing allows for more robust spell-checking and formatting.
- Please refer to our [Documentation style guide](./style-guide.mdx). This guide contains important conventions
  regarding terminology, formatting of titles and headers, use of code blocks, and much more.
- Remember to use the [documentation templates](./templates/index.md) when appropriate. They are pre-structured to align
  with our style guidelines, simplify the writing process (helping to avoid the "blank page" challenge), and maintain
  consistency in document structure and headings.
- Before submitting a PR, ensure your Markdown is well-formatted. If you have local Markdown linting tools configured,
  please run them.
- For new documentation pages, ensure they are appropriately linked from relevant sections in the main documentation (e.g., `website/docs/intro.md` or other logical overview pages) so that users can discover them.
- Place your new file in the folder that best matches its topic (e.g., `infrastructure/` or `k8s/`). The sidebar indexes each folder automatically, so you do not need to edit `sidebars.ts`.

## Set up your local environment (Recommended)

While not strictly required for simple edits, having a local setup can be beneficial for larger contributions.

**Requirements:**

- A good Markdown editor (e.g., VS Code with Markdown extensions, Obsidian, Typora).
- Git, for cloning the repository and managing changes.

**Local Build/Preview (Optional, if using a static site generator):** This project's documentation is part of a Docusaurus website located in the `website/` directory. You can build and serve the documentation locally by following Docusaurus CLI commands (e.g., `npm install` or `yarn install` in the `website/` directory, then `npm run start` or `yarn start`). The `website/package.json` contains the necessary scripts (like `docusaurus build`).

The documentation source files are located in the `/docs` folder of the
[homelab repository](https://github.com/theepicsaxguy/homelab/).

## General guidance for documentation content

In addition to following the [Documentation style guide](./style-guide.mdx), please consider these points when writing:

- **Clarity and Conciseness:** Aim for clear, straightforward language. Avoid jargon where possible, or explain it if
  necessary.
- **Accuracy:** Ensure all technical details, commands, file paths, and configurations are accurate and up-to-date with
  the current state of the repository.
- **Audience:** Write for an IT administrator or a technically-minded user who has some familiarity with Kubernetes and
  related technologies but may not be an expert in every specific component.
- **Completeness:** For procedural topics, include all necessary steps. For conceptual topics, provide sufficient
  background and context.
- **Examples:** Use relevant examples (e.g., YAML snippets, shell commands, Terraform configurations) that are specific
  to this homelab setup where appropriate.
- **Order of Information:** For procedural documentation, structure steps in a logical sequence that reflects how a user
  would perform the task. For conceptual topics, build information progressively.
- **Placeholder Values:** When using placeholder values in examples (e.g., domain names, IP addresses, secret keys),
  clearly indicate them using conventions like `<placeholder_name>` or `your-value-here` and instruct the user to
  replace them.
  - **Example:** For placeholder domains, use generic forms like `your.domain.tld` or `service.your.domain.tld`.
