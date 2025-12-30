# Homelab - Repository Guidelines

SCOPE: GitOps-managed homelab built on Kubernetes (Talos Linux) with Argo CD for continuous deployment

## Repository Purpose

Infrastructure-as-Code repository managing a Kubernetes-based homelab cluster. Infrastructure is provisioned with OpenTofu, and all Kubernetes manifests use Kustomize with GitOps deployment via Argo CD.

## Architecture

### High-Level Structure

**Domain: k8s**
Purpose: Kubernetes manifests, operators, and GitOps patterns
Location: /k8s/
Details: See /k8s/AGENTS.md

**Domain: tofu**
Purpose: Infrastructure provisioning, VM management, and cluster bootstrapping
Location: /tofu/
Details: See /tofu/AGENTS.md

**Domain: website**
Purpose: Docusaurus documentation site and build system
Location: /website/
Details: See /website/AGENTS.md

**Domain: images**
Purpose: Custom container images and Dockerfiles
Location: /images/
Details: See /images/AGENTS.md

### Domain Communication

- tofu provisions VMs and bootstraps Talos cluster
- k8s manifests deploy applications and infrastructure to cluster
- images provides container images referenced by k8s manifests
- website documents entire system

Changes flow: tofu → k8s (via cluster bootstrapping) → Argo CD GitOps sync

## Universal Standards

### Commits

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

### Pull Requests

Process:
1. Create feature branch from main
2. Make changes following commit message format
3. Validate changes using domain-specific commands
4. Create PR with descriptive title and body
5. Request review from maintainers
6. Address review feedback
7. Merge to main when approved

Requirements:
- All commits follow Conventional Commits format
- Pre-commit hooks pass
- Domain-specific validations pass (kustomize build, tofu validate, npm test)
- CI checks pass (GitHub Actions workflows)
- Description includes context and impact

### Documentation

When to document:
- Architecture changes
- New applications or infrastructure components
- Operational procedures
- Breaking changes or migration paths
- Known issues and workarounds

Where to document:
- README.md for project overview
- website/docs/ for user-facing documentation
- AGENTS.md files for developer/AI guidance
- Inline comments for non-obvious implementation details

Markdown File Placement:
- User-facing markdown files MUST be placed in `website/docs/` matching the structure of what they document
- The ONLY markdown files allowed outside `website/docs/` are `AGENTS.md` files (for coding agents, not humans)
- Never create markdown documentation files in domain directories (k8s/, tofu/, images/)
- Documentation must live in the website to be discoverable and maintainable

Format:
- Markdown (.md) for documentation
- Use imperative voice: "Configure the setting"
- Use present tense: "The system uses X"
- No first-person plural: "We use", "We investigated"
- No temporal language: "Now uses", "Has been updated"

## Cross-Cutting Concerns

### Security

Universal security practices:
- Never commit secrets or credential material to Git
- Externalize secrets using appropriate operator (External Secrets Operator, Bitwarden)
- Use non-root containers by default
- Apply network policies to restrict traffic
- Use TLS certificates for external endpoints
- Follow principle of least privilege for RBAC
- Keep base images and dependencies updated

### Error Handling

Philosophy:
- Treat deprecation warnings as critical errors
- Never guess resource names or secret keys
- Always query cluster to verify state before making changes

Structure:
- Query cluster resources to identify issues
- Read logs and events to understand root cause
- Apply fixes via Git/declarative config, not imperative commands

Logging:
- Never log sensitive data (passwords, tokens, API keys)
- Use structured logging where applicable
- Include correlation IDs for debugging

### Testing

Philosophy:
- Validate changes before committing
- Use domain-specific tools for validation
- Test locally before pushing to remote

Coverage:
- k8s manifests: `kustomize build` validation
- tofu: `tofu fmt` and `tofu validate`
- website: `npm run typecheck` and `npm run lint:all`
- images: `docker build` and smoke tests

Types:
- Validation: Syntax and structure checks
- Smoke tests: Basic functionality verification
- Integration: End-to-end flows (manual)

## Technology Stack

### Domains and Technologies

**Domain: k8s**
Technology: Kubernetes, Kustomize, Helm, Argo CD
Purpose: Application and infrastructure deployment
Details: See /k8s/AGENTS.md

**Domain: tofu**
Technology: OpenTofu (Terraform fork), Proxmox API, Talos Linux
Purpose: Infrastructure provisioning and cluster bootstrapping
Details: See /tofu/AGENTS.md

**Domain: website**
Technology: Docusaurus, TypeScript, React
Purpose: Documentation and operational guides
Details: See /website/AGENTS.md

**Domain: images**
Technology: Docker, GitHub Actions
Purpose: Custom container image builds
Details: See /images/AGENTS.md

## Code Style Guidelines

### Naming Conventions

- Directories: kebab-case (e.g., `getting-started/`, `k8s/applications/`)
- Files: kebab-case for markdown/yaml (e.g., `deployment.yaml`, `api-guide.md`)
- TypeScript/JavaScript: camelCase for variables, PascalCase for classes/types
- YAML/HCL resources: snake_case for resource names and variables

### YAML Formatting

- Indentation: 2 spaces
- Max line length: 120 characters
- Use `.yamllint.yml` for validation

### JavaScript/TypeScript Formatting

- Quotes: Single quotes
- Trailing commas: es5 style
- Print width: 120 characters
- Use `.prettierrc` for consistency

### Configuration File Comments

State what the setting does, not why you chose it:
- Bad: `# We use Kopia because snapshots didn't work`
- Good: `# Kopia filesystem backup to S3`
- When comparison is relevant: Good: `# instead of CSI snapshots`

### External Libraries

When adding or updating external libraries/packages/SDKs:
1. Fetch authoritative documentation using MCP Context7 and DeepWiki tools
2. Record provenance: Include resolved library ID and referenced docs pages in PR description
3. Use MCP resolver to get Context7-compatible library ID
4. Fetch docs in `code` mode (API refs) or `info` mode (narrative guides)

## Solution Standards

**Enterprise at Home** - Production-grade only, no homelab shortcuts.

**When multiple solutions exist:**
- Rank from hardest/most-capable to simplest
- Recommend the hardest (best practices, most capabilities)
- Explain what each simpler option sacrifices
- Complexity is a feature, not a problem

**Prohibited:**
- "Good enough for homelab" framing
- Workarounds that lose capabilities
- Assuming simpler is better

**Default:** Aim for perfection. Only compromise when explicitly directed.

If there's one obvious correct solution, just present it.

**Long-term thinking:**
- Every change must hold up 10+ years without modifications
- Shortcuts compound into 100x future pain
- Do it right once, not half-right repeatedly
- Favor the most maintainable path, even if harder upfront
- Harder upfront means less total compute time for you and future agents
- If something is clearly not maintainable, document the tradeoff explicitly

## AGENTS.md Discovery and Coverage

### How to Find Context

**ALWAYS read ALL AGENTS.md files from root to the closest directory containing your working file.**

Context is cumulative: each level adds more specific guidance for that domain/component.

Order of reading:
1. Root AGENTS.md (this file) - ALWAYS read first
2. Domain AGENTS.md (k8s/, tofu/, website/, images/) - read if working in that domain
3. Component AGENTS.md - read if working in that component (e.g., k8s/infrastructure/database/)

Example: Working on `k8s/infrastructure/database/` means read:
- /AGENTS.md
- /k8s/AGENTS.md
- /k8s/infrastructure/database/AGENTS.md

### Self-Healing Rule

**If you need to look up information not in the closest AGENTS.md, that file is incomplete.**

Action: Create or update the appropriate AGENTS.md file with missing context.

### Currently Available

**Domain-level:**
- k8s/AGENTS.md - Kubernetes domain patterns
- tofu/AGENTS.md - Infrastructure provisioning (OpenTofu)
- website/AGENTS.md - Documentation website
- images/AGENTS.md - Custom container images

**Component-level:**

**Kubernetes Applications:**
- k8s/applications/ai/AGENTS.md - AI applications (LiteLLM, Qdrant, VLLM, etc.)
- k8s/applications/automation/AGENTS.md - Home automation (Home Assistant, Frigate, MQTT, Zigbee2MQTT, N8N)
- k8s/applications/media/AGENTS.md - Media services (Jellyfin, Immich, arr-stack, Audiobookshelf)
- k8s/applications/web/AGENTS.md - Web applications (BabyBuddy, Pinepods, HeadlessX, Kiwix)

**Kubernetes Infrastructure:**
- k8s/infrastructure/auth/authentik/AGENTS.md - Authentik SSO and identity provider
- k8s/infrastructure/controllers/AGENTS.md - Cluster operators (Argo CD, Velero, Cert Manager, CNPG, etc.)
- k8s/infrastructure/database/AGENTS.md - CloudNativePG database management
- k8s/infrastructure/network/AGENTS.md - CNI (Cilium), Gateway API, DNS
- k8s/infrastructure/storage/AGENTS.md - Storage providers (Proxmox CSI, Longhorn)

## Critical Boundaries

Never commit secrets or credential material to Git.

Never commit generated artifacts: `website/build/`, `terraform.tfstate*`, `.tofu/`

Never modify CRD definitions without understanding operator compatibility.

Never apply changes directly to cluster — use GitOps.

Never run `tofu apply` without explicit human authorization and review.

Never use `--auto-approve` in tofu commands. Always review the plan first.

Never use destructive kubectl flags. This includes:
- `--force` - bypasses safety checks, causes data loss
- `--grace-period=0` - terminates pods without graceful shutdown
- `--ignore-not-found` - masks errors by ignoring missing resources
- Any other flag that bypasses safety mechanisms

These flags are NEVER acceptable. Find and fix the root cause instead.

Never guess resource names, connection strings, or secret keys — query the cluster to verify.

Never skip backup configuration for stateful workloads.

## Operational Rules

### Verify, Don't Guess

Before writing references to resources (Secrets, Services, URLs) in configuration files, query the active environment to confirm the exact name and existence:

```bash
kubectl get secret <name> -n <namespace>
kubectl get service <name> -n <namespace>
```

If a command fails due to configuration error, do not retry or change the name to what you think it should be. Inspect the failing resource:

```bash
kubectl describe pod <pod-name> -n <namespace>
```

### Deprecation & Schema Compliance

Treat deprecation warnings as critical errors. If a tool warns that a feature is deprecated, stop immediately. Search official documentation for the migration path and implement the modern standard.

Never hallucinate YAML fields. If API server rejects a manifest, use `kubectl explain <resource>.<field>` or fetch official CRD documentation.

### State Verification vs. Assumption

`kubectl apply` ≠ success. After applying changes, actively check the status to confirm successful reconciliation:

```bash
kubectl get <resource> <name> -n <namespace>
kubectl describe <resource> <name> -n <namespace>
```

When migrating between systems, explicitly identify which resources belong to which system. Check labels, age, and controller references to distinguish legacy from new infrastructure.

### Destructive Action Protocol

Never delete a Job, Pod, or PVC to "fix" configuration errors without proof from logs that the resource is in an unrecoverable state.

**Required evidence before deletion:**
- Check Pod logs: `kubectl logs <pod-name> -n <namespace>`
- Check Pod events: `kubectl describe pod <pod-name> -n <namespace>`
- Check Job status if applicable

### Resource Identification & Migration

When migrating infrastructure, use labels and metadata to distinguish resources:

```bash
# Check resource ownership
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.metadata.ownerReferences}'

# Check resource age
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.metadata.creationTimestamp}'

# Check resource labels
kubectl get pod <pod-name> -n <namespace> --show-labels
```

### Config Is Source of Truth

When debugging, reason from manifests and operator CRDs, not runtime state. Fixes must be declarative config changes, not imperative commands.

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

## Anti-Patterns

### Never Create Summary Documentation
Never create summary documents, reports, or writeups about work performed. Agents should complete tasks directly without generating additional documentation files explaining what was done.

### Never Commit Secrets
Never commit secrets, credentials, or API keys to Git. Use External Secrets Operator or similar mechanisms.

### Never Apply Directly
Never apply changes directly to cluster with `kubectl apply` for permanent changes. All changes must go through GitOps.

### Never Guess Names
Never guess resource names or secret keys. Query the cluster to verify.

### Never Skip Validation
Never skip validation steps. Run `tofu fmt/validate`, `kustomize build`, and `npm test/lint` before committing.

### Never Delete Without Evidence
Never delete resources without evidence from logs and events. Diagnose root cause first.

### Never Ignore Deprecations
Treat deprecation warnings as critical errors. Implement migration paths immediately.

### Never Leave Documentation Stale
After completing EVERY task, review and update relevant documentation. Outdated documentation causes more confusion than no documentation. Keep docs in sync with code and configuration changes.

### Never Hallucinate Fields
Never guess YAML field names. Use `kubectl explain` or fetch official documentation.

### Never Create Documentation from Scratch
When documentation is needed for an existing component, extend the current docs — never create new comprehensive documentation files. Find existing documentation and add to it. For genuinely new concepts or complex topics, a new page is justified. Do what's necessary: don't overdo, don't underdeliver.

## Philosophy

- GitOps is Law: All changes must go through Git
- Automate Everything: If it can be scripted or managed by a controller, it should be
- Security is Not an Afterthought: Non-root containers, network policies, externalized secrets by default
