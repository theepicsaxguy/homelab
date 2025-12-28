# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

GitOps-managed homelab built on Kubernetes (Talos Linux) with Argo CD for continuous deployment. Infrastructure is provisioned with OpenTofu, and all Kubernetes manifests use Kustomize.

## Quick-Start Commands

### Kubernetes Manifests
```bash
# Build and validate any kustomization
kustomize build --enable-helm k8s/applications/<category>/<app>
kustomize build --enable-helm k8s/infrastructure/<component>

# Build top-level applications or infrastructure
kustomize build --enable-helm k8s/applications
kustomize build --enable-helm k8s/infrastructure
```

### OpenTofu/Terraform
```bash
cd tofu
tofu fmt          # Format code
tofu validate      # Validate configuration
tofu plan          # Plan changes
tofu apply         # Apply only when explicitly authorized
```

### Documentation Website
```bash
cd website
npm install        # Install dependencies
npm start          # Dev server (hot reload)
npm run typecheck  # TypeScript type checking
npm run lint:all   # Lint markdown with Vale, remark, markdownlint
npm run build      # Production build
```

### Linting & Pre-commit
```bash
pre-commit run --all-files              # Run all hooks
pre-commit run --files <file-path>      # Run on specific files
```

### Testing
No automated test suite exists for this repository. Validate changes by:
- Running `kustomize build` to ensure manifests compile
- Running `npm run typecheck` and `npm run lint:all` for website changes
- Running `tofu fmt` and `tofu validate` for infrastructure changes

## Code Style Guidelines

### Naming Conventions
- Directories: kebab-case (e.g., `getting-started/`, `k8s/applications/`)
- Files: kebab-case for markdown/yaml (e.g., `deployment.yaml`, `api-guide.md`)
- TypeScript/JavaScript: camelCase for variables, PascalCase for classes/types
- YAML/HCL resources: snake_case for resource names and variables

### YAML Formatting
- Indentation: 2 spaces
- Max line length: 120 characters
- Use `.yamllint.yml` for validation (ignores `k8s/infrastructure/auth/authentik/extra/blueprints/`)

### JavaScript/TypeScript Formatting
- Quotes: Single quotes
- Trailing commas: es5 style
- Print width: 120 characters
- Use `.prettierrc` for consistency

### Commit Messages
Follow Conventional Commits format enforced by commitlint:
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`
Scopes: `k8s`, `infra`, `apps`, `docs`, `tofu`, `monitoring`, `network`, `storage`

Examples:
```
feat(k8s): add new monitoring stack
fix(infra): correct network policy for cilium
docs(monitoring): update architecture diagrams
chore(deps): update helm chart versions
```

Breaking changes require footer: `BREAKING CHANGE: <description>`

### Documentation Style (website/docs/)
- Use imperative voice: "Configure the setting", "Run the command"
- Use present tense: "The system uses X", "Kopia uploads data to S3"
- NO first-person plural: "We use", "We investigated", "We discovered"
- NO temporal language: "Now uses", "Has been updated", "Recently changed"
- Use frontmatter for page metadata (title, description, sidebar position)
- Use relative links for internal navigation: `[text](../other-page.md)`
- Include code blocks with language tags for syntax highlighting
- Use Docusaurus components (Admonitions, Tabs) for rich content

### Configuration File Comments
- State what the setting does, not why you chose it
- Bad: `# We use Kopia because snapshots didn't work`
- Good: `# Kopia filesystem backup to S3`
- When comparison is relevant: Good: `# instead of CSI snapshots`

### Imports and Dependencies
- For external libraries/packages/SDKs, MUST use MCP Context7 and DeepWiki tools to fetch authoritative documentation before making changes
- Record provenance: Include resolved library ID and referenced docs pages in PR descriptions
- Use the MCP resolver to get Context7-compatible library ID, then fetch docs in `code` mode (API refs) or `info` mode (narrative guides)

### Error Handling
- Treat deprecation warnings as critical errors
- Never hallucinate YAML fields — use `kubectl explain` or fetch official CRD documentation
- `kubectl apply` ≠ success — actively check resource status after applying changes
- Verify resource names and secrets by querying the cluster, never guess

## Repository Structure

```
.
├── k8s/                    # Kubernetes manifests (see k8s/AGENTS.md)
│   ├── applications/       # User-facing apps (media, ai, web, automation, etc.)
│   └── infrastructure/     # Core infrastructure (controllers, network, storage, auth, database)
├── tofu/                   # OpenTofu/Terraform infra (VMs, networking, Talos config)
├── images/                 # Custom container images (Dockerfiles, CI builds)
└── website/                # Docusaurus documentation site
```

## AGENTS.md Discovery and Coverage

### How to Find Context

1. Look for AGENTS.md in current directory (most specific)
2. Walk up to parent directory if not found
3. Continue to root AGENTS.md (global)

### Self-Healing Rule

**If you need to look up information not in the closest AGENTS.md, that file is incomplete.**

Action: Create or update the appropriate AGENTS.md file with missing context.

### Currently Available

Domain-level:
- k8s/AGENTS.md - Kubernetes patterns
- tofu/AGENTS.md - Infrastructure provisioning
- website/AGENTS.md - Documentation site
- images/AGENTS.md - Container images

Component-level:
- k8s/applications/ai/AGENTS.md - AI applications
- k8s/infrastructure/auth/authentik/AGENTS.md - Authentik SSO
- [Create more as needed when components have unique complexity]

## Critical Boundaries

- Never commit secrets or credential material
- Never commit generated artifacts: `website/build/`, `terraform.tfstate*`, `.tofu/`
- Never modify CRD definitions without understanding operator compatibility
- Never apply changes directly to cluster — use GitOps
- Never run `tofu apply` without explicit human authorization and review

## Operational Rules

### Verify, Don't Guess
Before writing references to resources, query the cluster:
```bash
kubectl get secret <name> -n <namespace>
kubectl get service <name> -n <namespace>
```

### Config Is Source of Truth
When debugging, reason from manifests and operator CRDs, not runtime state. Fixes must be declarative config changes, not imperative commands.

### Storage Classes
- New workloads: `proxmox-csi` (dynamic provisioning from Proxmox Nvme1 ZFS)
- Legacy workloads: `longhorn` (replicated storage, being phased out)
- Specify `storageClassName: proxmox-csi` in all new PVCs

### Backups
- `proxmox-csi` PVCs: Automatically backed up via Velero (no configuration needed)
- `longhorn` PVCs: Require backup labels (`recurring-job.longhorn.io/source` + tier label)
- GFS tier for critical data, Daily for standard apps, None for ephemeral

### ExternalSecrets Pattern
- Bitwarden Secrets Manager: Use `key` only (no `property` field), create separate entries for each secret
- Must use `engineVersion: v2` under `spec.target.template`
- Template indentation must be under `spec.target.template:`, not `spec:`

### CNPG Databases
- Prefer auto-generated credentials (omit `bootstrap.initdb.secret`)
- Auto-generated secret: `<cluster-name>-app` (contains username, password, dbname, host, port, uri)
- Never use ExternalSecrets for CNPG app credentials — creates circular dependencies
- Dual backup: MinIO (local) + Backblaze B2 (offsite disaster recovery)

### Velero
- Uses Kopia data mover (Restic deprecated)
- Hourly/daily/weekly schedules back up all namespaces automatically
- Pod-level annotations to exclude volumes if needed

## Philosophy

- GitOps is Law: All changes must go through Git
- Automate Everything: If it can be scripted or managed by a controller, it should be
- Security is Not an Afterthought: Non-root containers, network policies, externalized secrets by default
