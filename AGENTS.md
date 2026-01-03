# Homelab - Repository Guidelines

**You are working in an over-engineered GitOps homelab repository designed for enterprise learning.** This is not a typical homelab - every choice prioritizes production-grade patterns over simplicity to develop real-world skills.

SCOPE: GitOps-managed homelab built on Kubernetes (Talos Linux) with Argo CD for continuous deployment

## Repository Purpose

Infrastructure-as-Code repository managing a Kubernetes-based homelab cluster. Infrastructure is provisioned with OpenTofu, and all Kubernetes manifests use Kustomize with GitOps deployment via Argo CD.

## Architecture

### High-Level Structure

**Domain: k8s** - Kubernetes manifests, operators, and GitOps patterns → `/k8s/AGENTS.md`
**Domain: tofu** - Infrastructure provisioning, VM management, cluster bootstrapping → `/tofu/AGENTS.md`
**Domain: website** - Documentation site and build system → `/website/AGENTS.md`
**Domain: images** - Custom container images and Dockerfiles → `/images/AGENTS.md`

### Domain Communication

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

Breaking changes require footer: `BREAKING CHANGE: <description>`

### Documentation

**Where to document:**
- `website/docs/` for user-facing documentation (matching structure)
- `AGENTS.md` files only for developer/AI guidance
- README.md for project overview
- Inline comments for non-obvious implementation details

**Rules:**
- User-facing markdown MUST be in `website/docs/`
- Never create markdown files in domain directories (k8s/, tofu/, images/)
- Use imperative voice, present tense, no first-person plural or temporal language

## Technology Stack

**k8s:** Kubernetes, Kustomize, Helm, Argo CD
**tofu:** OpenTofu, Proxmox API, Talos Linux  
**website:** Docusaurus, TypeScript, React
**images:** Docker, GitHub Actions

## Code Style

- Directories/files: kebab-case
- TypeScript: camelCase variables, PascalCase classes/types
- YAML/HCL: snake_case resources
- YAML: 2-space indent, 120-char line length
- TypeScript: single quotes, es5 trailing commas, 120-char width

## Solution Standards

**Enterprise at Home** - Production-grade only, no homelab shortcuts.

Rank solutions from hardest/most-capable to simplest. Complexity is a feature, not a problem. Default to perfection - every change must hold up 10+ years without modifications.

## Core Philosophy

### Learning-First Approach
This repository serves as a learning sandbox for enterprise patterns. Every "over-engineered" choice is intentional - complexity develops skills that translate directly to production environments.

### Over-Engineering by Design  
**Why complexity is a feature:** Homelab shortcuts don't teach enterprise resilience. Production systems require redundancy, observability, and automation - those patterns are learned here, not simplified away.

### Complete Auditable State
**Everything as Code rationale:** Full Git state representation enables instant rebuild capability and provides complete audit trails - exactly what enterprise environments require.

### Production Simulation
**Why no homelab shortcuts:** Enterprise environments can't take shortcuts. Learning proper patterns here prevents bad habits in professional environments.

### Domain Integration Philosophy
- **tofu → k8s**: Infrastructure bootstrapping enables application deployment
- **k8s → website**: Documentation captures implementation reality  
- **images → k8s**: Container security patterns extend to cluster security
- **All → GitOps**: Changes flow through pipeline, never directly applied

## AGENTS.md Discovery

**ALWAYS read ALL AGENTS.md files from root to your working directory.**

Context is cumulative. Read in order:
1. Root AGENTS.md (this file) - ALWAYS read first
2. Domain AGENTS.md (k8s/, tofu/, website/, images/)
3. Component AGENTS.md (if applicable)

**Self-Healing Rule:** If you need information not in the closest AGENTS.md, that file is incomplete - update it.

### Available AGENTS.md Files

**Domain-level:** k8s/, tofu/, website/, images/

**Component-level:**
- Applications: ai/, automation/, media/, web/
- Infrastructure: auth/authentik/, controllers/, database/, network/, storage/

## Universal Anti-Patterns

### Critical Security & Safety
- Never commit secrets or credentials to Git
- Never commit generated artifacts (build/, .tofu/, terraform.tfstate*)
- Never run `tofu apply` without explicit human authorization
- Never use `--auto-approve` in tofu commands
- Never use kubectl `--force`, `--grace-period=0`, or `--ignore-not-found` flags
- Never modify CRD definitions without understanding operator compatibility

### Operational Excellence  
- Never apply changes directly to cluster - use GitOps
- Never guess resource names, connection strings, or secret keys - query to verify
- Never skip validation steps before committing
- Never delete resources without evidence from logs/events
- Never ignore deprecation warnings - implement migration paths immediately
- Never leave documentation stale after completing tasks
- Never hallucinate YAML fields - use `kubectl explain` or official docs
- Never create summary documentation about work performed

### Documentation Integrity
- Never create documentation from scratch for existing components - extend existing docs
- Never reference AGENTS.md files from user-facing documentation

## Quick-Start Reference

```bash
# Universal validation
pre-commit run --all-files
pre-commit run --files <file-path>

# Domain-specific commands
# Kubernetes: see k8s/AGENTS.md
# Infrastructure: see tofu/AGENTS.md  
# Documentation: see website/AGENTS.md
# Containers: see images/AGENTS.md
```

## Philosophy

- GitOps is Law: All changes must go through Git
- Automate Everything: If it can be scripted or managed by a controller, it should be
- Security is Not an Afterthought: Non-root containers, network policies, externalized secrets by default

### CNPG Backup Strategy (Universal Reference)
**Continuous WAL → MinIO (plugin), weekly base backups → B2 (backup section), both in externalClusters for recovery flexibility.**

- **Only Plugin Architecture**: Use ObjectStore CRD + barman-cloud plugin (legacy barman deployment is deprecated)
- **Dual Destinations**: Configure in externalClusters - MinIO for fast local recovery, Backblaze B2 for disaster recovery
- **Recovery Flexibility**: Both destinations enable recovery if one location becomes unavailable