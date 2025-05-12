# CI/CD and Repository Maintenance

This guide explains how we use GitHub Actions and Dependabot to maintain code quality and automate releases.

## Release Management

We use Release Please to automate versioning and changelog creation.

### How It Works

1. Push commits using Conventional Commit format:
   - `feat:` for new features (minor version)
   - `fix:` for bug fixes (patch version)
   - `BREAKING CHANGE:` for major changes

2. Release Please automatically:
   - Creates/updates a release PR
   - Updates CHANGELOG.md
   - Sets version numbers
   - Creates GitHub Release when PR merges

### Configuration

```yaml
# .github/workflows/release-please.yml
permissions:
  contents: write
  pull-requests: write

release-type: simple
```

## Code Quality Checks

We run several validation scripts through GitHub Actions:

- `validate_argocd.sh` - Checks Kustomize builds and ArgoCD configs
- `validate_charts.sh` - Tests Helm charts
- `validate_manifests.sh` - Verifies Kubernetes manifests
- `validate-external-secrets.sh` - Validates secret configurations

These checks run:
- On every push to `main`
- On all pull requests
- Locally via pre-commit hooks

## Dependency Management

Dependabot automatically checks for updates daily across:

1. **Package Types**
   - npm packages
   - Terraform modules
   - Docker images
   - GitHub Actions
   - Helm charts

2. **Configuration** (`.github/dependabot.yml`):
```yaml
version: 2
enable-beta-ecosystems: true

updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "daily"
  # Similar configs for other ecosystems
```

3. **Private Registries**
   - Support for GHCR, Google Cloud, AWS ECR
   - Requires registry credentials in GitHub secrets

## Pre-commit Hooks

Local validation happens through pre-commit hooks in `.github/hooks/`:

- Checks ExternalSecret manifests
- Validates required fields
- Ensures proper refresh intervals
- Blocks commits if validation fails

## Best Practices

1. Use Conventional Commits for clear change tracking
2. Review Dependabot PRs promptly for security updates
3. Never bypass pre-commit hooks
4. Always review release PRs carefully
5. Keep validation scripts updated

Need help? Check the workflow files in `.github/workflows/` for examples.
