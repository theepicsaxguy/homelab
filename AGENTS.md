# Codex Agent Guidelines for the homelab Repository

This guide details the standards and workflows for Codex agents contributing to this repository.

## Repository Structure

- **k8s/**: Kubernetes manifests, organized into `infrastructure/` and `applications/`.
- **tofu/**: OpenTofu/Terraform configs for provisioning infrastructure.
- **website/**: Docusaurus documentation site (`package.json`, TypeScript source in `src/`, documentation in `docs/`).
- **scripts/**: Utility scripts (e.g. `fix_kustomize.sh`).
- **.github/**: GitHub Actions workflows, commit message policy, and automation.

## Style Requirements

- **Commit Messages**: Follow [Conventional Commits](.github/commit-convention.md):
  - Format: `type(scope): message` (imperative mood, ≤72 characters, no trailing periods).
  - Common scopes: `k8s`, `infra`, `apps`, `docs`, `tofu`, `monitoring`, `network`, `storage`.
  - For breaking changes, add `!` or a `BREAKING CHANGE:` footer.
- **Pull Request Titles**: Use the same format as commits.

## Contribution Process

- **Website**: After editing TypeScript/docs under `website/`, run `npm install` and `npm run typecheck`.
- **OpenTofu**: Run `tofu fmt` and `tofu validate` inside the `tofu/` directory before pushing changes.
- **Documentation**: Document notable infrastructure changes in `website/docs/`.
- **Generated Files**: Do not alter rendered Helm charts or generated files; edit the source kustomization instead.

## Pull Request Expectations

- Keep changes focused and minimal.
- Always update relevant docs if you change infrastructure or applications.
- Ensure all commit messages and PR titles meet conventions.
- Summarize testing in your PR body (commands and outcomes).

## Project-Wide Rules

1. **Documentation**:
   For any changes (beyond simple bug fixes), update documentation using the provided templates.
2. **Kubernetes Manifests**:
   Run `kustomize build --enable-helm (dir)` in each directory you modify; ensure all builds succeed before submitting a PR.
3. **Comments**:
   Do not add inline code comments—explanations belong in documentation files.
4. **Code Quality**:
   Improve any code you touch; always leave things better than you found them.
5. **Best Practices**:
   Apply DRY principles. Code should be maintainable and adhere to single-responsibility guidelines.
6. **Files**:
   Whenever possible, modify existing files. Only create new files if necessary, maintaining the established structure.
7. **Documentation Style**:
   Write documentation plainly, without jargon or marketing language. Be honest about limitations or known issues, using a conversational tone.

**Note:**
You can use the internet for Helm charts and `kustomize build`. All builds must pass before submitting your pull request.
