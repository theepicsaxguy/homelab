# Shai-Hulud Security Scanning Setup

This document describes the security scanning implementation added to this repository.

## Overview

The Shai-Hulud Detector GitHub Action has been integrated to provide automated vulnerability scanning for all dependencies across the repository. This proactive security measure helps prevent vulnerable dependencies from being introduced into the codebase.

## What Was Added

### 1. Security Scan Workflow (`.github/workflows/security-scan.yaml`)

A new GitHub Actions workflow that:
- Scans all dependency lockfiles for known vulnerabilities
- Runs automatically on pull requests and pushes to main when dependency files change
- Executes weekly security audits every Monday at 9:00 UTC
- Can be triggered manually via workflow_dispatch
- Blocks PRs with critical vulnerabilities from merging
- Warns about high/medium severity issues without blocking

**Configuration highlights:**
```yaml
fail-on-critical: true   # Block PRs with critical vulnerabilities
fail-on-high: false      # Warn but don't block high-severity issues
scan-lockfiles: true     # Scan lockfiles for accurate version detection
warn-on-allowlist: true  # Warn when allowlisted vulnerabilities are detected
```

### 2. Allowlist File (`.shai-hulud-allowlist.json`)

A configuration file for managing accepted security risks:
- Used to document false positives
- Can temporarily accept vulnerabilities while waiting for upstream fixes
- Should be used sparingly with proper justification
- Supports expiration dates for temporary exceptions

### 3. Documentation Updates

**Updated files:**
- `README.md` - Added security scan badge
- `SECURITY.md` - Added automated scanning section and security best practices
- `website/docs/github/github-configuration.md` - Documented the security workflow
- `website/docs/contributing/overview.md` - Added security check guidance for contributors
- `.github/workflows/README.md` - Created comprehensive workflow documentation

## How It Works

### For Contributors

When you open a pull request that modifies dependency files:

1. The security scan runs automatically
2. If critical vulnerabilities are found, the build fails and you must:
   - Update to a patched version, or
   - Discuss with maintainers about adding to the allowlist
3. High/medium vulnerabilities generate warnings but won't block your PR

### For Maintainers

**Weekly scans** run every Monday to catch newly disclosed vulnerabilities in existing dependencies.

**Managing vulnerabilities:**

1. **Update dependencies**: Use Renovate/Dependabot PRs for patches
2. **Allowlist exceptions**: Only when absolutely necessary, add to `.shai-hulud-allowlist.json`:

```json
{
  "allowlist": [
    {
      "id": "CVE-2024-12345",
      "package": "example-package",
      "version": "1.2.3",
      "reason": "No fix available; code path not executed in our use case",
      "added": "2024-12-18",
      "expires": "2025-03-01",
      "reviewer": "@username"
    }
  ]
}
```

3. **Review regularly**: Audit the allowlist quarterly and remove resolved items

## Monitored File Types

The workflow scans changes to:
- `**/package.json` and `**/package-lock.json` (npm/Node.js)
- `**/requirements.txt`, `**/Pipfile`, `**/Pipfile.lock` (Python)
- `**/go.mod` and `**/go.sum` (Go)
- `**/Cargo.toml` and `**/Cargo.lock` (Rust)

## Integration with Existing Tools

This security scanner complements existing dependency update automation:

- **Renovate**: Continues to create PRs for dependency updates
- **Dependabot**: Continues to monitor security advisories
- **Shai-Hulud**: Provides an additional security gate during PR review

All three tools work together to maintain a secure dependency posture.

## Permissions

The workflow uses minimal required permissions:
- `contents: read` - Read repository files
- `issues: write` - Create security issue reports
- `pull-requests: write` - Comment on PRs with findings

## Testing the Workflow

To test the security scan locally or trigger it manually:

```bash
# Trigger manual workflow run
gh workflow run security-scan.yaml

# View workflow status
gh run list --workflow=security-scan.yaml

# View logs from latest run
gh run view --workflow=security-scan.yaml --log
```

## Troubleshooting

### Build failing on false positive?

1. Verify it's actually a false positive by researching the CVE
2. Document why it's a false positive
3. Add to allowlist with proper justification
4. Re-run the workflow

### Vulnerability has no fix available?

1. Check if the vulnerable code path is actually used in your application
2. Consider alternative packages if risk is significant
3. If risk is accepted, document in allowlist with expiration date
4. Monitor for patches and update ASAP when available

### Weekly scan found new vulnerabilities?

1. Check Renovate/Dependabot for available updates
2. If updates exist, merge the update PRs
3. If no update exists, evaluate risk and potentially allowlist temporarily
4. Create an issue to track the vulnerability until resolved

## Resources

- [Shai-Hulud Detector on GitHub Marketplace](https://github.com/marketplace/actions/shai-hulud-2-0-detector)
- [Repository Security Policy](../../SECURITY.md)
- [Contributing Guide](../CONTRIBUTING.md)
- [Workflow Documentation](./workflows/README.md)

## Maintenance

This security scanning setup should be reviewed:
- **Quarterly**: Audit allowlist and remove resolved items
- **When upgrading**: Test with new action versions
- **When issues arise**: Adjust configuration based on false positive patterns

---

**Last Updated**: December 18, 2024
**Action Version**: gensecaihq/Shai-Hulud-2.0-Detector@v2
