# How to Contribute

Contributions are welcome and appreciated. I'm currently the only person maintaining this repository, and I'd be happy to have help. Whether it's fixing a typo, updating a Helm chart, or adding a new application, your contributions are welcome. To keep things organized, I've adopted some standard open-source practices like conventional commits. Please follow these guidelines so everything stays tidy.

## Philosophy

- **GitOps is Law:** All changes to the cluster must be made through Git. No manual `kubectl apply` for permanent changes.
- **Automate Everything:** If it can be scripted or managed by a controller, it should be.
- **Security is Not an Afterthought:** I use non-root containers, network policies, and externalized secrets by default.

## Getting Started

The best way to contribute is to find an area you can improve.

1. **Read the Full Guide:** For detailed information on the commit conventions, PR process, and local setup, see the [full contributing guide on the website](https://homelab.orkestack.com/docs/contributing/overview).
2. **Find an Issue:** Check out the issues labeled [`good first issue`](https://github.com/theepicsaxguy/homelab/labels/good%20first%20issue) for easy entry points.
3. **Report a Bug:** If you found a problem, please open a [bug report](https://github.com/theepicsaxguy/homelab/issues/new?template=bug_report.md).
4. **Suggest a Feature:** Have an idea for a new app or improvement? Let's discuss it in a [feature request](https://github.com/theepicsaxguy/homelab/issues/new?template=feature_request.md).

Your help in improving this project is greatly valued.

## Required Checks

Before opening a pull request, make sure your changes pass the basic checks. A detailed rundown lives in the [full contributing guide](https://homelab.orkestack.com/docs/contributing/overview), but here's the quick version:

- **Kubernetes manifests:** `kustomize build --enable-helm <dir>` for each modified directory.
- **OpenTofu:** Run `tofu fmt` and `tofu validate` in the `tofu/` folder.
- **Website and docs:** From `website/`, run `npm install`, `npm run typecheck`, and `npm run lint`.
- **Docker images:** Only Dockerfiles that changed are built. Pushing a tag like `image-<version>` rebuilds that image even if no files changed.
