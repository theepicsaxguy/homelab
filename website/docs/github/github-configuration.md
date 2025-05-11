# GitHub Configuration: CI/CD and Repository Maintenance

This section outlines how I use GitHub features like Actions and Dependabot to maintain this homelab repository, ensure
code quality, and automate releases.

## Workflows (`.github/workflows/`)

- **File:** `.github/workflows/release-please.yml`

  - **What it does:** This workflow uses the `googleapis/release-please-action`. It automates the process of versioning
    and releasing based on conventional commit messages in the `main` branch.
  - **How it works:**
    1.  When commits are pushed to `main`, `release-please` analyzes the commit messages.
    2.  If it detects commits that signify a new version (e.g., `feat:` for a minor, `fix:` for a patch,
        `BREAKING CHANGE:` for a major), it creates or updates a pull request. This PR includes an updated
        `CHANGELOG.md` and bumps the version number (e.g., in a `version.txt` file or by creating a Git tag).
    3.  When I merge this "release PR", the action then creates a GitHub Release with the corresponding tag and
        changelog.
  - **Why this approach?**
    - **Automated Versioning & Changelogs:** It takes the manual effort out of version bumping and writing changelogs.
    - **Conventional Commits:** Enforces a structured commit history, which is good practice.
    - **Release PRs:** Gives me a chance to review the upcoming release before it's finalized.
  - **Permissions:** It requires `contents: write` (to push tags, update changelog) and `pull-requests: write` (to
    create/update the release PR).
  - **`release-type: simple`:** I'm using a simple versioning scheme. Release Please also supports more complex
    strategies for monorepos or specific languages.

- **Other Potential Workflows (Implied by validation scripts):** While not explicitly defined in the provided file
  structure, the presence of scripts like `validate_argocd.sh`, `validate_charts.sh`, `validate_manifests.sh`, and
  `hooks/validate-external-secrets.sh` strongly implies that I have GitHub Actions workflows that run these scripts on
  events like `push` to `main` or `pull_request` to `main`.
  - **Purpose:** These CI workflows would be designed to automatically lint and validate my Kubernetes configurations,
    Helm charts, and other scripts to catch errors early and maintain code quality.
  - **Typical Triggers:**
    - On every push to the `main` branch.
    - On every push to a pull request targeting `main`.
  - **Jobs:** A typical workflow might have jobs for:
    - Linting YAML/scripts.
    - Running `validate_manifests.sh` or `validate_argocd.sh` (which includes Kustomize builds and `kubeconform`).
    - Running `validate_charts.sh`.
    - Running specific hook scripts like `validate-external-secrets.sh`.
  - **Why?** Automated checks in CI are critical for preventing broken configurations from being merged and deployed.

## Dependabot (`.github/dependabot.yml`)

- **File:** `.github/dependabot.yml`
- **What it does:** This file configures Dependabot to automatically check for updates to various dependencies used in
  this repository and create pull requests to apply those updates.
- **Why Dependabot?**
  - **Security:** Keeps dependencies up-to-date, which often include security fixes.
  - **Stability:** Uses the latest stable versions of tools and libraries.
  - **Reduced Manual Effort:** Automates the tedious process of checking for and applying updates.
- **Configuration Details:**
  - `version: 2`: Specifies the Dependabot configuration version.
  - `enable-beta-ecosystems: true`: I've enabled this, likely because I'm using it for Helm chart dependency updates,
    which might still be considered beta or require this flag.
  - **Package Ecosystems:**
    - `npm`: Checks for updates to Node.js packages (if there's a `package.json` at the root).
    - `terraform`: Scans the entire repository for Terraform provider and module dependencies.
    - `docker`: Scans the `/k8s/` directory for Docker image references in files (e.g., `Dockerfile`, Kubernetes
      manifests) and suggests updates.
    - `github-actions`: Checks for updates to GitHub Actions used in my workflows.
    - `helm`: Scans the root directory (and recursively) for Helm chart dependencies (e.g., in `Chart.yaml` files or
      potentially ArgoCD Application sources if configured to track chart versions).
  - **Schedule:** All ecosystems are configured for `daily` checks.
  - **Registries (Commented Out):** I've included commented-out examples for configuring private registries (GHCR, GCP
    Artifact Registry, AWS ECR). If I were using private Docker images or Helm charts from these sources, I would
    uncomment and configure these sections with appropriate secrets.
    - **Why?** To allow Dependabot to access and update dependencies from private sources.

## Pre-commit Hooks (`.github/hooks/`)

- **File:** `.github/hooks/validate-external-secrets.sh`
  - **What it does:** This script is designed to validate `ExternalSecret` manifests. It checks for required fields and
    sensible `refreshInterval` values.
  - **How it's likely used:** I would integrate this into a pre-commit hook framework (like `pre-commit.com`). When I
    try to commit changes, this hook would run automatically on the staged files. If it finds issues, the commit would
    be aborted, forcing me to fix the validation errors first.
  - **Why pre-commit hooks?** They provide immediate feedback and help catch errors _before_ they even get pushed to the
    repository or run in CI. This saves time and CI resources.

By combining GitHub Actions for CI, Dependabot for dependency management, and pre-commit hooks for local validation, I
aim to maintain a high-quality, secure, and up-to-date codebase for my homelab infrastructure.
