# Contributing Guide

We welcome your pull requests! This short guide explains the workflow we use.

## Workflow

1. **Fork and branch.** Create a branch in your fork for each change.
2. **Make your edits.** Keep commits focused and follow the [commit message style](./commit-convention.md).
3. **Run checks.**
   - If you changed docs or TypeScript, run `npm install` and `npm run typecheck` in `website/`.
   - If you touched Kubernetes manifests, run `kustomize build --enable-helm <dir>` for each changed directory.
   - For OpenTofu configs, run `tofu fmt` and `tofu validate`.
4. **Push and open a PR.** Use the same Conventional Commit format in the PR title.

## Your First Contribution

A simple way to start is updating a container image.

1. Fork this repo and create a branch called `update-it-tools`.
2. Edit `k8s/applications/tools/it-tools/deployment.yaml` and update the image tag.
3. Commit with `chore(deps): update it-tools docker tag to v2024.10.23`.
4. Open a pull request against `main`.

Thanks for helping improve the project!
