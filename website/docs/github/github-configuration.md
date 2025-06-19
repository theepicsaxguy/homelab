# GitHub Configuration: CI/CD and Repository Maintenance

This page explains how GitHub Actions, Dependabot, and pre-commit hooks keep this homelab repository secure, up to date, and easy to maintain.

---

## GitHub Actions Workflows (`.github/workflows/`)

### Release Automation (`release-please.yml`)

- **File:** `.github/workflows/release-please.yml`
- **Purpose:** Automate versioning and releases using [Release Please](https://github.com/googleapis/release-please-action) and conventional commit messages.
- **How it works:**
  1. Push commits to `main` using [Conventional Commits](https://www.conventionalcommits.org/).
  2. Release Please scans commit messages for changes:
     - `feat:` triggers a minor version bump.
     - `fix:` triggers a patch bump.
     - `BREAKING CHANGE:` triggers a major bump.
  3. A release pull request (PR) is created or updated, including:
     - Updated `CHANGELOG.md`
     - Proposed new version (Git tag or version file)
  4. Merge the release PR to `main`:
     - Release Please creates a GitHub Release with the new tag and changelog.
- **Why:**
  - **Automated releases and changelogs:** No more manual versioning or writing changelogs.
  - **Enforces commit conventions:** Keeps commit history clear and structured.
  - **Release PRs:** Adds a review step before a release is finalized.
- **Permissions:**
  - `contents: write` (for tags/changelog updates)
  - `pull-requests: write` (for PRs)
- **Note:**
  - Uses a simple versioning scheme (`release-type: simple`). Suitable for single-package projects.

### Docker Image Build (`image-build.yaml`)

- **File:** `.github/workflows/image-build.yaml`
- **Purpose:** Detects Dockerfiles and pushes updated images to GHCR.
- **Permissions:**
  - `contents: read` (clone the repository)
  - `packages: write` (upload images)
- **Build context:** Uses `.dockerignore` files within each image directory to keep uploads minimal.

### Validation & CI (Implied Workflows)

- **What:** While specific workflow YAMLs for all validation steps aren't detailed here, the presence of scripts like `hooks/validate-external-secrets.sh` suggests CI integration for validation. The repository aims to automatically lint and validate configurations.
- **Purpose:** Automatically lint and validate configurations (Kubernetes, Helm charts, scripts) on every push or PR.
- **When triggered:**
  - Every push to `main`
  - Every pull request to `main`
- **Jobs may include:**
  - YAML and script linting
  - Kustomize and ArgoCD validation (typically using `kustomize build` and ArgoCD CLI tools)
  - Helm chart checks (typically using `helm lint` or `helm template`)
  - Run `validate-external-secrets.sh` for secret validation
- **Why:**
  - **Automation:** Prevents errors and broken configs from reaching production.
  - **Quality gate:** Fails builds if code doesn’t meet standards.

---

## Dependabot (`.github/dependabot.yml`)

- **File:** `.github/dependabot.yml`
- **Purpose:** Automatically monitor and update dependencies across multiple ecosystems.
- **Why use Dependabot?**
  - **Security:** Get timely security fixes by staying up-to-date.
  - **Stability/Features:** Use latest, stable software.
  - **Convenience:** No more manual update checks.
- **Monitored package ecosystems:**
  - `npm` (Node.js packages)
  - `terraform` (Terraform modules/providers)
  - `docker` (Docker images and Kubernetes manifests in `/k8s/`)
  - `github-actions` (Actions used in workflows)
  - `helm` (Helm charts and dependencies)
- **Configuration highlights:**
  - `version: 2` (schema version)
  - `enable-beta-ecosystems: true` (required for some features like Helm updates)
  - **Daily update checks** for all ecosystems
  - **Private registries:** Example settings for registries like GHCR, GCP Artifact Registry, AWS ECR are included (commented out).
    - Uncomment and add secrets if using private images/charts.
    - **Why:** Lets Dependabot update private dependencies, not just public ones.

---

## Pre-commit Hooks (`.github/hooks/`)

- **File:** `.github/hooks/validate-external-secrets.sh`
- **Purpose:** Validate all `ExternalSecret` manifests before committing. Ensures required fields and sensible values (like `refreshInterval`).
- **How it's used:**
  - Integrated with a pre-commit framework (such as [pre-commit.com](https://pre-commit.com/)).
  - Runs automatically on staged files before a commit.
  - Aborts the commit if there are validation errors—fix errors, then try again.
- **Why:**
  - **Immediate feedback:** Catches errors before they ever reach the remote repo or CI.
  - **Less noise in CI:** Fewer broken commits and wasted CI runs.

---

## Summary

By combining GitHub Actions (automated CI), Dependabot (dependency management), and pre-commit hooks (local validation), this repo stays:

- High quality
- Secure
- Automated
- Easy to maintain

For more details, see the relevant configuration files under `.github/`.
