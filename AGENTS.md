# Codex Agent Guidelines for the Homelab Repository

## Repository Structure

- **k8s/**: Kubernetes manifests (subdirectories: `infrastructure/`, `applications/`)
- **tofu/**: OpenTofu/Terraform configs for infrastructure provisioning.
- **website/**: Docusaurus site (includes `package.json`, TypeScript in `src/`, docs in `docs/`)
- **.github/**: GitHub Actions, commit message policy, automation configs.

---

## Style Requirements

- **Commit Messages:** Follow [Conventional Commits](.github/commit-convention.md), e.g.:
  - Format: `type(scope): message`
  - Examples: `fix(k8s): fix replica count error`, `feat(apps)!: update API endpoint usage`
- **Pull Request Titles:** Must follow the same format as commits.

---

## Contribution Workflow

- **Website:**
  - Run `npm install` and `npm run typecheck` after modifying docs or TypeScript.
- **OpenTofu:**
  - Run `tofu fmt` and `tofu validate` before committing changes.
- **Documentation Updates:**
  - Update relevant docs in `website/docs/` for infrastructure changes.
- **Generated Files:**
  - Avoid editing rendered Helm charts; update their kustomization sources instead.

---

## Testing and Build Verification

- **Kubernetes Manifests:**
  - Run `kustomize build --enable-helm <dir>` for each modified directory.
- **Local Testing:**
  - Ensure all relevant linter and type-check commands pass:
    - Example: `npm run lint`, `tofu validate`, etc.
- **Expected Outcomes:**
  - Provide logs or summaries in your PR body.

---

## Pull Request Expectations

- Keep changes minimal and focused.
- PR titles and commit messages must follow the designated formats.
- Document testing steps and outcomes in the PR description.

---

## Project-Wide Rules

1. **Documentation Standards:**
   - Use plain language and document limitations transparently.
2. **Comments and Code Quality:**
   - Avoid inline comments; use separate documentation files.
   - Follow DRY principles and single-responsibility guidelines.
3. **File Changes:**
   - Prefer modifying existing files over creating new ones unless necessary.
