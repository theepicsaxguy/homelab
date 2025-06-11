---
title: Contributing Guide
---

Welcome! This guide contains everything you need to know to contribute to the homelab project, from setting up your local environment to our standards for pull requests.

## Local Development Setup

To ensure your changes are valid, you'll need a few tools.

- **OpenTofu:** For validating any changes in the `/tofu` directory.
- **Kustomize:** For building and validating Kubernetes manifests.
- **Node.js/npm:** For type-checking and running the documentation website.

### Checking Your Work

Before opening a pull request, please run these checks on any files you've modified:

- **Kubernetes Manifests:**
  ```bash
  # Run from the root of the repo for each directory you changed
  kustomize build --enable-helm k8s/applications/media/jellyfin
  ```

- **OpenTofu Files:**
  ```bash
  cd tofu
  tofu fmt
  tofu validate
  ```

- **Website/Documentation:**
  ```bash
  cd website
  npm install
  npm run typecheck
  ```

## The Pull Request Process

1. **Open an Issue (For Big Changes):** If you're planning to add a new application or make a significant architectural change, please [open an issue](https://github.com/theepicsaxguy/homelab/issues/new?template=feature_request.md) first. For small changes like version bumps or typo fixes, you can go straight to a PR.
2. **Create a Branch:** Start your work from an up-to-date `main` branch in your fork.
3. **Commit Your Changes:** We use **Conventional Commits** to automate releases and generate changelogs. Please follow this format strictly. Your PR title must also follow this format.
   - **Format:** `type(scope): description`
   - **Examples:**
       - `feat(k8s): add new monitoring stack`
       - `fix(network): correct cilium network policy`
       - `docs(contributing): clarify PR process`
       - `chore(deps): update helm chart for argocd`
   - For full details, see the [commit convention guide](../../.github/commit-convention.md).
4. **Open the Pull Request:** Push your branch and open a PR against the `main` branch. In the description, briefly explain the "what" and "why" of your change. If it resolves an issue, include `Fixes #123`.

## What Makes a Good Contribution?

- **Small, Focused PRs:** It's much easier to review a PR that updates one Helm chart than a PR that updates ten.
- **Follow the Pattern:** When adding a new application, look at an existing one (like `it-tools` or `jellyfin`) and copy its structure.
- **Update Documentation:** If your change affects how something works, please update the relevant documentation in `/website/docs`.
