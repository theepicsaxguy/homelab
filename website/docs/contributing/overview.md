---
title: Contributing Guide
---

Welcome. This guide contains everything you need to know to contribute to the homelab project, from setting up your local environment to my standards for pull requests.

I'm currently the only person maintaining this repository, and I'd be happy to have help. Whether it's fixing a typo, updating a Helm chart, or adding a new application, your contributions are welcome. To keep things organized, I've adopted some standard open-source practices like conventional commits.

For community expectations, please read my [Code of Conduct](https://github.com/theepicsaxguy/homelab/blob/main/.github/CODE_OF_CONDUCT.md). If you just need a quick reference on the workflow, see the [short contributing guide](https://github.com/theepicsaxguy/homelab/blob/main/.github/CONTRIBUTING.md).

## Local Development Setup

To ensure your changes are valid, you'll need a few tools.

- **OpenTofu:** For validating any changes in the `/tofu` directory.
- **Kustomize:** For building and validating Kubernetes manifests.
- **Node.js/npm:** For type checking and running the documentation website. **Requires Node.js >=20.18.1 and npm >=10.0.0**.

### Node.js Version Management

This project requires Node.js >=20.18.1. If you're using a different version, you can:

1. **Use nvm (Node Version Manager):**
   ```shell
   # Install the required version (reads from .nvmrc)
   nvm install
   nvm use
   ```

2. **Check your current version:**
   ```shell
   node --version  # Should show v20.18.1 or higher
   npm --version   # Should show v10.0.0 or higher
   ```

3. **Install all dependencies:**
   ```shell
   # From the root of the repository
   npm run install:all
   ```

### Common Build Issues

If you encounter "File is not defined" errors with the search plugin or other module loading issues, this usually indicates you're using an incompatible Node.js version. Ensure you're using Node.js >=20.18.1.

### Checking Your Work

Before opening a pull request, please run these checks on any files you've modified:

- **Kubernetes Manifests:**
  ```shell
  # Run from the root of the repo for each directory you changed
  kustomize build --enable-helm k8s/applications/media/jellyfin
  ```

- **OpenTofu Files:**
  ```shell
  cd tofu
  tofu fmt
  tofu validate
  ```

- **Website/Documentation:**
  ```shell
  cd website
  npm install
  npm run build      # Test the full build process
  npm run typecheck  # Check TypeScript types
  ```

## The Pull Request Process

1. **Open an Issue (For Big Changes):** If you're planning to add a new application or make a significant architectural change, please [open an issue](https://github.com/theepicsaxguy/homelab/issues/new?template=feature_request.md) first. For small changes like version bumps or typo fixes, you can go straight to a PR.
2. **Create a Branch:** Start your work from an up-to-date `main` branch in your fork.
3. **Commit Your Changes:** I use **Conventional Commits** to automate releases and generate changelogs. Please follow this format strictly. Your PR title must also follow this format.
   - **Format:** `type(scope): description`
   - **Examples:**
       - `feat(k8s): add new monitoring stack`
       - `fix(network): correct cilium network policy`
       - `docs(contributing): clarify PR process`
       - `chore(deps): update helm chart for argocd`
   - For full details, see the [commit convention guide](https://github.com/theepicsaxguy/homelab/blob/main/.github/commit-convention.md).
4. **Open the Pull Request:** Push your branch and open a PR against the `main` branch. In the description, briefly explain the "what" and "why" of your change. If it resolves an issue, include `Fixes #123`.

## What Makes a Good Contribution?

- **Small, Focused PRs:** It's much easier to review a PR that updates one Helm chart than a PR that updates ten.
- **Follow the Pattern:** When adding a new application, look at an existing one (like `it-tools` or `jellyfin`) and copy its structure.
- **Update Documentation:** If your change affects how something works, please update the relevant documentation in `/website/docs`.
