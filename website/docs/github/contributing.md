---
title: How to contribute
---

This page explains the basics of proposing changes and filing issues for the homelab project.

## Workflow overview

1. Fork the repository and create a branch for your work.
2. Make your changes and follow the [commit style](../../.github/commit-convention.md).
3. Run any required checks:
   - `npm install` && `npm run typecheck` if you edited docs or TypeScript.
   - `kustomize build --enable-helm <dir>` when changing Kubernetes manifests.
   - `tofu fmt` and `tofu validate` for OpenTofu configs.
4. Push your branch and open a pull request.

## Example: updating a container image

Updating an app image is an easy first PR:

1. Edit `k8s/applications/tools/it-tools/deployment.yaml` and update the tag on the `image:` line.
2. Commit with `chore(deps): update it-tools docker tag to v2024.10.23`.
3. Open a PR against `main`.

That's it! We review quickly and appreciate all contributions.
