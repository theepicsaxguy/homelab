# GitHub Configuration: CI/CD and Repository Maintenance

This page explains how GitHub Actions, Renovate, and Dependabot keep this homelab repository secure, up to date, and straightforward to maintain.

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
  - Uses a basic versioning scheme (`release-type: simple`). Suitable for single package projects.

### Docker Image Build (`image-build.yaml`)

- **File:** `.github/workflows/image-build.yaml`
- **Purpose:** Detects Dockerfiles and pushes updated images to GHCR.
- **Permissions:**
  - `contents: read` (clone the repository)
  - `packages: write` (upload images)
- **Build context:** Uses `.dockerignore` files within each image directory to keep uploads minimal.

### Documentation Lint (`vale.yaml`)

- **File:** `.github/workflows/vale.yaml`
- **Purpose:** Lints Markdown files in `website/docs` using [Vale](https://vale.sh/).
- **When triggered:** Only when `.md` files change under `website/docs/`.
- **How it works:** The workflow lints only the changed Markdown files and posts the results as a single pull request check.

### Validation & CI (Implied Workflows)

- **What:** While specific workflow YAMLs for all validation steps aren't detailed here, CI jobs automatically lint and validate configurations.
- **Purpose:** Automatically lint and validate configurations (Kubernetes, Helm charts, scripts) on every push or PR.
- **When triggered:**
  - Every push to `main`
  - Every pull request to `main`
- **Jobs can include:**
  - YAML and script linting
  - Kustomize and ArgoCD validation (typically using `kustomize build` and ArgoCD CLI tools)
  - Helm chart checks (typically using `helm lint` or `helm template`)
- **Why:**
  - **Automation:** Prevents errors and broken configs from reaching production.
  - **Quality gate:** Fails builds if code doesn’t meet standards.

---

## Renovate (`renovate.json`)

- **File:** `renovate.json`
- **Purpose:** Keep dependencies current across Dockerfiles, Helm charts, Terraform, and other configs.
- **Why use Renovate?**
  - **Broad coverage:** Handles many ecosystem updates in one tool.
  - **Automatic PRs:** Creates update pull requests with minimal manual work.

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


## Summary

By combining GitHub Actions (automated CI), Renovate (dependency updates), and Dependabot (security checks), this repo stays:

- High quality
- Secure
- Automated
- Straightforward to maintain

For more details, see the relevant configuration files under `.github/`.
