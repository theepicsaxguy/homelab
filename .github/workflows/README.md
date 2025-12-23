# GitHub Actions Workflows

This directory contains automated workflows for CI/CD, security, and quality checks.

## Active Workflows

### `security-scan.yaml` - Dependency Security Scanning

Scans all dependency lockfiles for known vulnerabilities using Shai-Hulud Detector.

**Triggers:**
- Pull requests modifying dependency files
- Pushes to `main` branch modifying dependency files
- Weekly schedule (Mondays at 9:00 UTC)
- Manual workflow dispatch

**Configuration:**
- Fails build on critical vulnerabilities
- Warns on high-severity issues (non-blocking)
- Respects allowlist in `.shai-hulud-allowlist.json`
- Scans lockfiles for accurate version detection

**Managing the Allowlist:**

The allowlist (`.shai-hulud-allowlist.json`) should be used sparingly and only for:
- False positives that cannot be resolved
- Vulnerabilities with no available fix where risk is accepted
- Temporary exceptions while waiting for upstream patches

Example allowlist entry:
```json
{
  "allowlist": [
    {
      "id": "CVE-2024-12345",
      "package": "example-package",
      "reason": "False positive - code path not used in our application",
      "expires": "2025-03-01"
    }
  ]
}
```

### `vale.yaml` - Documentation Linting

Lints Markdown documentation using Vale style checker.

**Triggers:**
- Changes to files under `website/docs/`

### `image-build.yaml` - Container Image Builds

Builds and pushes Docker images to GHCR when Dockerfiles change.

**Triggers:**
- Changes to `images/` directory
- Tags matching `*-*` pattern
- Manual workflow dispatch

### `website-build.yaml` - Documentation Website Build

Builds the Docusaurus documentation website and validates TypeScript.

**Triggers:**
- Changes to `website/` directory
- Changes to root `package.json` or `.nvmrc`

### `release-please.yml` - Release Automation

Automates version bumps and changelog generation using conventional commits.

**Triggers:**
- Pushes to `main` branch

## Local Testing

Before pushing, you can run these checks locally:

```bash
# Validate Kubernetes manifests
kustomize build --enable-helm k8s/applications/<app>

# Format and validate OpenTofu
cd tofu && tofu fmt && tofu validate

# Build website
cd website && npm install && npm run build && npm run typecheck

# Run pre-commit hooks (includes Vale)
pre-commit run --all-files
```

## Security Best Practices

1. **Review dependency updates carefully** - Renovate and Dependabot will create PRs for updates
2. **Don't disable security scans** - If you need an exception, use the allowlist
3. **Keep allowlist minimal** - Document why each exception exists
4. **Monitor weekly scan results** - Check scheduled security scan outcomes regularly

## Permissions

Workflows use minimal required permissions following the principle of least privilege:

- `contents: read` - Clone repository (all workflows)
- `contents: write` - Create tags/releases (release-please only)
- `packages: write` - Push container images (image-build only)
- `pull-requests: write` - Comment on PRs (security-scan, vale)
- `issues: write` - Create security issues (security-scan only)

## Contributing

When adding new workflows:
1. Follow the existing naming convention (`kebab-case.yaml`)
2. Use minimal permissions
3. Include clear comments and descriptions
4. Document the workflow in this README
5. Update `/website/docs/github/github-configuration.md`
