# Security Policy

## Automated Security Scanning

This repository uses automated security scanning to detect vulnerabilities in dependencies:

- **Continuous Scanning**: All pull requests are automatically scanned for known vulnerabilities in dependency lockfiles
- **Critical Protection**: PRs containing critical-severity vulnerabilities are blocked from merging
- **Weekly Audits**: Scheduled security scans run every Monday to catch newly disclosed vulnerabilities
- **Dependency Updates**: Renovate and Dependabot automatically create PRs for security patches

### Vulnerability Management

When a vulnerability is detected:

1. **Critical vulnerabilities** must be resolved before code can be merged
2. **High/medium vulnerabilities** generate warnings and should be addressed promptly
3. **Accepted risks** can be documented in `.shai-hulud-allowlist.json` with justification
4. **False positives** should be reported to improve scanning accuracy

## Reporting a Vulnerability

If you discover a security vulnerability not caught by automated scanning, please follow these steps:

1. **Open a GitHub Issue**: Report the vulnerability by creating an issue in the repository.
2. **Provide Details**: Include a clear description, steps to reproduce, and any potential impact.
3. **Responsible Disclosure**: Do not publicly disclose the issue until I have had a chance to investigate and release a fix.
4. **Response Time**: I aim to acknowledge receipt of reports within 48 hours and will provide updates during the investigation.
5. **Fix Timeline**: If the vulnerability is confirmed, I will work on a fix and coordinate a disclosure timeline with you.

## Security Best Practices

This project follows security best practices:

- **GitOps**: All changes are version-controlled and auditable
- **Non-root containers**: All container images run as non-root users
- **Network policies**: Workloads use Kubernetes network policies to restrict traffic
- **Secret management**: Secrets are externalized using External Secrets Operator
- **Minimal permissions**: GitHub Actions workflows use least-privilege permissions
- **Regular updates**: Automated dependency updates keep software current

Thank you for helping keep this project secure!

