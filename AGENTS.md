# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a GitOps-managed homelab built on Kubernetes (Talos Linux), using Argo CD for continuous deployment. The entire infrastructure and all applications are declaratively defined in Git. Infrastructure is provisioned with OpenTofu (Terraform fork), and all Kubernetes manifests use Kustomize for configuration management.

**Philosophy:**
- GitOps is Law: All changes must go through Git. No manual `kubectl apply` for permanent changes.
- Automate Everything: If it can be scripted or managed by a controller, it should be.
- Security is Not an Afterthought: Non-root containers, network policies, and externalized secrets by default.

## Repository Structure

```
.
├── k8s/                    # All Kubernetes manifests
│   ├── applications/       # User-facing applications (media, ai, web, automation, etc.)
│   └── infrastructure/     # Core infrastructure (controllers, network, storage, auth, database)
├── tofu/                   # OpenTofu (Terraform) infrastructure as code
│   ├── talos/             # Talos Linux configuration
│   └── lb/                # Load balancer configuration
├── images/                 # Custom container images (Dockerfiles)
└── website/                # Docusaurus documentation site
```

## Common Development Commands

### Kubernetes Manifests

All Kubernetes resources use Kustomize. To validate manifests:

```bash
# Build and validate any kustomization directory
kustomize build --enable-helm k8s/applications/<category>/<app>
kustomize build --enable-helm k8s/infrastructure/<component>

# Build top-level applications or infrastructure
kustomize build --enable-helm k8s/applications
kustomize build --enable-helm k8s/infrastructure
```

### OpenTofu/Terraform

```bash
cd tofu

# Format code
tofu fmt

# Validate configuration
tofu validate

# Plan changes
tofu plan

# Apply changes (only when explicitly requested by user)
tofu apply
```

### Documentation Website

```bash
cd website

# Install dependencies
npm install

# Start development server
npm start

# Type check
npm run typecheck

# Lint markdown
npm run lint:all

# Build for production
npm run build
```

### Linting & Pre-commit

```bash
# Run pre-commit hooks manually (includes Vale linting)
pre-commit run --all-files

# Run pre-commit on specific files
pre-commit run --files website/docs/path/to/file.md
```

**Note:** Pre-commit must be installed first (`pip install pre-commit` or `pipx install pre-commit`), then initialized with `pre-commit install`. The pre-commit hooks will automatically download and install Vale and other linting tools on first run.

### Git Workflow

This repository uses:
- **Conventional Commits**: Follow the format `type(scope): description`
- **Commitlint**: Enforced via git hooks
# AGENTS – Steering & Design Guidelines

This document defines how to structure and maintain `AGENTS.md` (and nested variants) so that AI coding agents can work across the entire repository with no external tools. The goal: an agent can onboard as a new teammate using only the repo + AGENTS files.

## 1. Purpose & Scope of AGENTS.md

`AGENTS.md` is the repository's README for automated agents. Treat it as the single predictable place for agent-focused technical guidance, separate from human-centric docs. Use it to:

- Describe architecture, workflows, and conventions an agent must follow.
- Specify exact commands and patterns that define "how we do things here." Prioritize machine-actionable instructions.
- Document deployment, routing, and secrets handling at a conceptual level (no secret values).
- Provide clear boundaries: what the agent should and should not touch.

Every line should help an automated agent work effectively and safely.

## 2. Layout Strategy — Root and Nested AGENTS

Follow a hierarchy: the closest `AGENTS.md` to a file wins. Root file contains global rules and a directory map; nested AGENTS refine for their scope.

- Root `AGENTS.md` (this file)
   - Global conventions, architecture overview, deployment and routing patterns.
   - Directory map linking to subproject AGENTS (if present).
   - Cross-cutting rules (security, commit style, logging, minimal changes).

- Nested `AGENTS.md`
   - Eg: `k8s/AGENTS.md`, `tofu/AGENTS.md`, `website/AGENTS.md`, `images/AGENTS.md`.
   - Narrow, actionable guidance for that area (build/test commands, structure, patterns).

Rule: the closest AGENTS.md to a target file or folder takes precedence for that scope.

## 3. Core Sections (for root and for nested AGENTS)

Each AGENTS file should follow this minimal structure. Keep it short and machine-friendly.

1. Purpose & Scope — what this AGENTS covers.
2. Quick-start Commands — actionable build/test/deploy commands for that scope.
3. Architecture / Layout — concise map of code responsibilities.
4. Testing — how to run full and partial test suites.
5. Code Style & Patterns — concrete examples and references to real files.
6. Boundaries & Safety — what must not be changed, where secrets live.
7. How to Extend — step-by-step recipes for common tasks (add endpoint, new page, DB table).
8. Checklist — things to verify before merging architecture or infra changes.

### 3.1 Project & Architecture Overview

At root, include a short architecture summary. Example for this repo:

- Multicomponent homelab on Kubernetes (Talos) using GitOps (Argo CD).
- Top-level flow: frontend SPA (website) → API services in `k8s/applications/*` → controllers & infra in `k8s/infrastructure/*` → long-lived data in Postgres (Zalando Spilo) and Longhorn volumes.
- Infrastructure provisioning via OpenTofu (Terraform fork) in `tofu/`.
- Secrets are sourced via External Secrets Operator from Bitwarden and injected into pods as env vars or mounted volumes.

Reference real files when possible (e.g., `k8s/infrastructure/application-set.yaml`, `tofu/`) so an agent can find examples.

### 3.2 Setup & Build Commands

Put the most-used commands first so an agent can quickly bootstrap. Example commands (tool-agnostic where possible):

- Kubernetes manifests: `kustomize build --enable-helm k8s/applications` and `kustomize build --enable-helm k8s/infrastructure`.
- OpenTofu: `cd tofu && tofu fmt && tofu validate && tofu plan` (apply only in infra PRs by humans).
- Website: `cd website && npm install && npm run build` (dev: `npm start`).
- Image builds: GitHub Actions runs `images/*/Dockerfile` builds via `image-build.yaml`.

State environment assumptions (Node.js, npm versions) and where to run commands.

### 3.3 Testing Instructions

- How to run all tests for the repo (if applicable) and per-subproject commands.
- Where test files live and naming conventions (e.g., `**/*.test.*`, `__tests__`).
- What CI expects (lint, typecheck, build, tests). Keep machine-readable exit conditions.

### 3.4 Code Style & Patterns

- Use concrete examples (point to `website/src/`, `images/*/Dockerfile`) rather than vague rules.
- State patterns: controllers thin, services contain business logic, repositories handle DB access.
- Naming: kebab-case for directories, camelCase for JS/TS variables, PascalCase for types/classes.
- Linting and format: pre-commit, Vale for prose; include commands to run them.

### 3.5 Boundaries & Safety

- Files/folders NOT to modify unless explicitly allowed:
   - Generated artifacts: `website/build/`, any `build/` outputs, `terraform.tfstate*` files.
   - Secrets and vaults: `secrets/`, any local env files (never commit `.env` with values).
   - CI runners or central infrastructure state outside the repo.
- Read-only vs write-allowed rules: nested AGENTS may allow write in their scope.
- Never commit secrets or secret material into code or logs.

### 3.6 Global Operational Rules

**Verify, Don't Guess**

- **Never guess resource names, connection strings, or secret keys.** Before writing a reference to a resource (like a Secret, Service, or URL) in a configuration file, query the active environment to confirm the exact name and existence:
  ```bash
  kubectl get secret <name> -n <namespace>
  kubectl get service <name> -n <namespace>
  ```
- **If a command fails due to a configuration error** (e.g., `CreateContainerConfigError`), do not simply retry or change the name to what you think it should be. Inspect the actual failing resource:
  ```bash
  kubectl describe pod <pod-name> -n <namespace>
  ```
  Read the specific error message to identify the missing dependency.

**Deprecation & Schema Compliance**

- **Treat deprecation warnings as Critical Errors.** If a tool (like CNPG, Helm, or kubectl) warns that a feature is deprecated, stop immediately. Do not attempt to use the deprecated field. Search the official documentation for the specific migration path and implement the modern standard.
- **Never hallucinate YAML fields.** If the API server rejects a manifest with "field not declared in schema," do not guess variations of the spelling. Use `kubectl explain <resource>.<field>` or fetch the official CRD documentation to validate the schema before attempting a fix.

**State Verification vs. Assumption**

- **`kubectl apply` ≠ "Success".** Applying a manifest only validates syntax, not functionality. After applying a change, actively check the status of the resource to confirm it has reconciled successfully:
  ```bash
  kubectl get <resource> <name> -n <namespace>
  kubectl describe <resource> <name> -n <namespace>
  ```
- **When migrating between systems** (e.g., Zalando to CNPG, or upgrading operators), explicitly identify which resources belong to which system. Do not look at an existing "Running" pod and assume it is the new deployment. Check labels, age, and controller references to distinguish legacy infrastructure from new infrastructure:
  ```bash
  kubectl get pod <pod-name> -n <namespace> -o yaml | grep -E 'ownerReferences|labels|creationTimestamp'
  ```

## 4. Deployment, Routing, Gateway & Secrets

This section captures conceptual deployment and routing so an agent can reason about adding services or routes.

### 4.1 Deployment & Environments

- Environments: `dev`, `test`, `prod` (conceptual).
- Deployment: GitOps. Changes are made in Git and Argo CD auto-syncs Kubernetes manifests from `k8s/`.
- Artifacts: container images (built via GitHub Actions) are pushed to the registry and referenced by manifests in `k8s/applications/*`.
- OpenTofu manages infrastructure resources and VMs in `tofu/` (Talos, load balancers).
- Configuration differences by environment are represented via separate kustomize overlays or Kustomize variables in the infra folders.

### 4.2 HTTP Routing & Gateways

- Public ingress is managed via Gateway API and Cloudflared tunnels.
- Base API patterns: e.g., `/api/...` for backend services; specific apps live under `k8s/applications/<category>/<app>/httproute.yaml`.
- Versioning: use `/api/v1/...` if the service is versioned; prefer semantic versioning for breaking changes.
- Contracts: OpenAPI/Swagger (if present) should be referenced from `k8s/applications/*` or `website/` when clients are generated.
- Auth: Authentik (SSO). Services typically use bearer tokens or OIDC flows; local dev may use test tokens.
- CORS: described in each service's httproute or ingress policy. Local dev may be permissive; production should be restrictive.

### 4.3 Secrets & Bitwarden

- Secrets live conceptually in Bitwarden (or the configured external secrets provider). External Secrets Operator syncs them into Kubernetes Secrets.
- Local dev: use developer-managed local secrets or `.local.env` (never committed). Provide sample config files with dummy values only.
- Access patterns: pods receive secrets via env vars or mounted volumes; pipelines reference secrets from CI secret stores.
- Rules: do not commit secrets; never log secret values; use placeholders in config examples.

## 5. Agent Personas (optional folder)

Create machine-readable agent persona files in `.github/agents/` or `agents/` to define focused roles. Each persona file should:

- State scope and responsibilities.
- List allowed file areas and prohibited paths.
- Give example tasks and constraints (e.g., "Test-agent: only add tests and update docs, never change infra").

Example persona names: `system-architect.agent.md`, `test-agent.agent.md`, `docs-agent.agent.md`, `infra-agent.agent.md`.

## 6. Making the Repo Self-Explanatory (No Tools Required)

To ensure an agent can operate without external tools, follow these practices:

- Use this root `AGENTS.md` as an index with a Directory Map pointing to nested AGENTS.
- Keep instructions concise, deterministic, and example-driven.
- Provide recipes for common tasks (add endpoint, add page, add DB table) as step-by-step numbered lists.
- Update AGENTS files whenever architecture or deployment changes; require AGENTS updates in the same PR as structural changes.

## 7. Checklist for Repository Maintainers

Before merging changes that affect architecture, workflows, or structure, ensure:

- [ ] Root `AGENTS.md` accurately describes overall architecture and workflows.
- [ ] Nested AGENTS in modified subprojects match actual folder roles and patterns.
- [ ] Deployment patterns (environments, gateways, routes) are current.
- [ ] Secrets handling / Bitwarden usage is correctly described.
- [ ] No references to deprecated patterns or obsolete tools.
- [ ] Commands listed actually work (build, test, deploy).
- [ ] Boundaries remain clear (what agents must not modify).

---

Directory Map (high-level):

- `k8s/` — Kubernetes manifests and kustomize overlays. See `k8s/AGENTS.md` (if present).
- `tofu/` — OpenTofu/terraform for provisioning. See `tofu/AGENTS.md` (if present).
- `images/` — custom container images and Dockerfiles. See `images/AGENTS.md` (if present).
- `website/` — docs website (Docusaurus). See `website/AGENTS.md` (if present).


Completion note: keep AGENTS files concise, example-rich, and always up-to-date with infra and repo changes.
