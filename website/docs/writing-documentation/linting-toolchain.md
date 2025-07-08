---
title: Documentation linting toolchain
---

This project uses automated linting to keep the docs readable and consistent. The stack relies on open-source tools that run locally and in CI.

## Local setup

1. Install the **Vale** and **markdownlint** extensions in VS Code.
2. From the repository root, bootstrap the config files:
   ```bash
   vale config init
   npx markdownlint-cli2 --init
   ```
3. Pre-commit hooks run `vale` and `markdownlint` before every commit.

## CI checks

GitHub Actions validates all Markdown files on every pull request. The pipeline fails if either linter reports errors.

## Files and directories

- `.vale.ini` and `styles/` define prose rules.
- `.markdownlint.yaml` controls Markdown style.
- `.pre-commit-config.yaml` enables the hooks.
- `.github/workflows/docs.yml` runs the checks in CI.

Follow the existing [style guide](./style-guide.mdx) along with these tools. Fix warnings as you go so the CI stays green.
