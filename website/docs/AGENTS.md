# Documentation Writing Guidelines

SCOPE: Writing documentation for the homelab
INHERITS FROM: /AGENTS.md, website/AGENTS.md

## DOMAIN CONTEXT

Purpose:
Write and maintain user-facing documentation in the homelab repository.

Boundaries:
- Handles: Documentation content in website/docs/
- Does NOT handle: Website build system (see website/AGENTS.md), code implementation (see k8s/, tofu/)
- Integrates with: All domain directories for source file references

## PATTERNS

### Documentation Pattern
Write technical documentation in imperative voice with present tense facts. No first-person plural ("we"), no temporal language ("now uses"), no narrative storytelling. State what exists and how it works.

### Code Block Pattern
Avoid code blocks in documentation. They become outdated quickly. Describe concepts in prose, or link to source files with absolute paths. If code examples are unavoidable, verify they work and flag them for review.

Example of linking to source:
```
The storage configuration is defined in `/k8s/infrastructure/storage/proxmox-csi/kustomization.yaml`.
```

### Linking Pattern
- Internal links: Use relative paths within website/docs/
- Source file links: Use absolute paths from repository root
- External links: Use full URLs

## DOCUMENTATION STYLE

### Voice and Tense
- Use imperative voice for instructions: "Configure the setting", "Run the command"
- Use present tense for facts: "The system uses X", "Kopia uploads data to S3"
- State what exists and how it works, not how it was created

### What to Avoid
- No first-person plural: "We use", "We investigated"
- No temporal language: "Now uses", "Has been updated"
- No narrative storytelling: "We explored X and found that..."
- No status updates: "The system now supports..."
- No code blocks (link to source files instead)

### Comments in Code Files
State what the setting does, not why you chose it:
- Bad: `# We use Kopia because snapshots didn't work`
- Good: `# Kopia filesystem backup to S3`
- When comparison is relevant: Good: `# instead of CSI snapshots`

## ANTI-PATTERNS

Never use first-person plural ("we", "our") in documentation.

Never use temporal language ("now", "recently", "has been updated") in documentation.

Never break existing links without updating all references.

Never include code blocks in documentation. Link to source files by absolute path or explain concepts in prose.

Never commit untested code examples without running them.

## CRITICAL BOUNDARIES

Never add secrets or credentials to documentation files.

Never include configuration values that may change. Link to source manifests instead.

After making changes, verify relevant documentation doesn't contain outdated information. Update or flag stale docs.

## DOCUMENTATION CATEGORIES

- `getting-started/` - Onboarding and setup guides
- `k8s/` - Kubernetes documentation (applications, infrastructure)
- `tofu/` - OpenTofu infrastructure documentation
- `backup/` - Backup and recovery procedures
- `infrastructure/` - Infrastructure component documentation
- `troubleshooting/` - Common issues and solutions
- `contributing/` - Contribution guidelines

## REFERENCES

For documentation writing examples, see existing files in website/docs/

For Docusaurus features, see https://docusaurus.io/docs

For prose style, see root AGENTS.md
