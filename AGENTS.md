# Codex Agent Guidelines for the homelab Repository

This document provides repo-specific instructions for Codex agents contributing to this project.

## Repository Overview

- **k8s/** – Kubernetes manifests organised into `infrastructure/` and `applications/`.
- **tofu/** – OpenTofu/Terraform configuration for infrastructure provisioning.
- **website/** – Docusaurus documentation site (`package.json`, TypeScript sources in `src/` and docs under `docs/`).
- **scripts/** – Utility scripts such as `fix_kustomize.sh`.
- **.github/** – GitHub Actions workflows, commit conventions and other automation settings.

## Style Conventions

- **Prettier** (`.prettierrc`)
  - `printWidth: 120`
  - `singleQuote: true`
  - `trailingComma: es5`
  - `proseWrap: always`
- **YAML** (`.yamllint.yml`)
  - Indentation: 2 spaces
  - Max line length: 120
  - Ignore `k8s/infrastructure/auth/authentik/extra/blueprints/` when linting
- **Commit Messages** (`.github/commit-convention.md`)
  - Use Conventional Commits: `type(scope): description` in imperative mood, ≤72 characters, no trailing period.
  - Common scopes include `k8s`, `infra`, `apps`, `docs`, `tofu`, `monitoring`, `network`, `storage`.
  - Breaking changes: append `!` after the scope or add a `BREAKING CHANGE:` footer.
- **Pull Request Titles** follow the same `type(scope): description` format.

## Contribution Workflow

1. **Formatting** – Run `npx prettier -w <files>` on Markdown/TypeScript/YAML/JSON changes.
2. **YAML Validation** – Use `yamllint` with `.yamllint.yml`. For Kubernetes kustomizations, run
   `scripts/fix_kustomize.sh` after editing `kustomization.yaml` files.
3. **Website** – If editing TypeScript or docs in `website/`, run `npm install` once then `npm run typecheck`.
4. **OpenTofu** – Format with `tofu fmt` and validate with `tofu validate` in the `tofu/` directory.
5. **Documentation** – Significant infrastructure changes should be documented under `website/docs/`.
6. **Generated Files** – Do not edit rendered Helm charts or other generated output. Modify source templates instead.

## Pull Request Expectations

- Keep changes minimal and focused.
- Update relevant documentation when altering infrastructure or applications.
- Ensure commit messages and PR titles follow the conventions above.
- Provide a brief testing summary in the PR body (commands run and results).
