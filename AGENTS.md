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
- Top-level flow: frontend SPA (website) → API services in `k8s/applications/*` → controllers & infra in `k8s/infrastructure/*` → long-lived data in Postgres (CloudNativePG) and persistent storage.
- **Storage**: Proxmox CSI (`csi.proxmox.sinextra.dev`) is the primary storage provisioner for new workloads, providing dynamic volume provisioning directly from Proxmox datastores. Legacy workloads may still use Longhorn (`driver.longhorn.io`).
  - StorageClass: `proxmox-csi` (Retain policy, WaitForFirstConsumer binding)
  - Backend: Proxmox Nvme1 datastore with ZFS
  - Bootstrap: Terraform creates Proxmox user/role/token in `tofu/bootstrap/proxmox-csi-plugin/`
  - Deployment: Helm chart deployed via Kustomize in `k8s/infrastructure/storage/proxmox-csi/`
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
- **When migrating between systems** (e.g., between database operators, or upgrading operators), explicitly identify which resources belong to which system. Do not look at an existing "Running" pod and assume it is the new deployment. Check labels, age, and controller references to distinguish legacy infrastructure from new infrastructure:
  ```bash
  kubectl get pod <pod-name> -n <namespace> -o yaml | grep -E 'ownerReferences|labels|creationTimestamp'
  ```

**External Libraries Requirement**

- **MCP tools required:** When an agent or developer adds, updates, or references an external library (package, SDK, or third-party API client) they MUST use the MCP Context7 and DeepWiki tools to resolve the library and fetch authoritative, up-to-date documentation and code examples before making changes. Use the resolver to obtain a Context7-compatible library ID and the docs endpoints to retrieve relevant pages; do not rely on memory or informal web searches.
- **Record provenance:** Include which MCP calls and the resolved library ID(s) in the PR description so reviewers can verify sources.

**Context7 (resolver + docs - `code` mode)**

- **Resolve the library:** Use the MCP resolver to get the Context7-compatible library ID before fetching API docs. Example: call the resolver with `library-name` to get an ID like `/org/project` or `/org/project/version`.

- **Fetch API references:** With the resolved ID, call the MCP docs endpoint in `code` mode to retrieve API references, signatures, and code examples. Start with `page=1` and paginate if needed.

**OpenWiki / DeepWiki (docs - `info` mode)**

- **Fetch conceptual guides:** Use the MCP docs endpoint in `info` mode or query DeepWiki/OpenWiki for narrative guides, migration notes, and best-practices that explain design intent and upgrade paths.

**DeepWiki (#cognitionai/deepwiki) usage**

- **Preferred source for narrative guidance:** When seeking conceptual guidance, migration notes, rationale, or best-practices prefer `#cognitionai/deepwiki` as the authoritative DeepWiki collection.
- **How to call (resolver + docs):**
  1. If you don't have the exact library ID, call `mcp_io_github_ups_resolve-library-id` with `libraryName` to resolve the library to a Context7-compatible ID.
  2. Call `mcp_io_github_ups_get-library-docs` with `context7CompatibleLibraryID` and `mode=info` to fetch DeepWiki/OpenWiki-style narrative pages. If you specifically want `#cognitionai/deepwiki`, include that as the `libraryName` in the resolver or reference its pages in the docs call.
  3. Use `page=1` initially and increment pages if the topic is large.

- **What to include in the PR:**
  - Which resolver call you ran and the returned `context7CompatibleLibraryID`.
  - Which DeepWiki/OpenWiki pages you referenced (copy URLs or page titles).
  - A short summary of the guidance you used and how it affected the change.

- **Example sequence (pseudo):**
  1. `mcp_io_github_ups_resolve-library-id { libraryName: "some-lib" }` → returns `/org/some-lib`
  2. `mcp_io_github_ups_get-library-docs { context7CompatibleLibraryID: "/org/some-lib", mode: "info", page: 1 }` → returns narrative pages
  3. Paste resolved ID and pages into PR: "Resolved `/org/some-lib` via resolver; used DeepWiki pages X,Y for migration guidance."


**Practical workflow**

1. Run the resolver for `library-name` → obtain `context7CompatibleLibraryID`.
2. Call docs with `mode=code` and `context7CompatibleLibraryID` to collect API examples and reference snippets.
3. Call docs with `mode=info` (or DeepWiki/OpenWiki) to collect conceptual guidance and migration notes.
4. Copy the exact `context7CompatibleLibraryID` and the docs page URLs into the PR description as provenance.

**Example PR note**

Resolved library `/vercel/next.js/v14.3.0-canary.87` via MCP resolver; used Context7 docs pages A,B for API examples and OpenWiki page Z for migration guidance.

### Agent Session Efficiency Rules

These rules prevent wasted turns, repeated mistakes, and user frustration, especially in infra/Kubernetes/DB debugging contexts.

#### 1. Respect Explicit User Constraints Immediately
- If the user states a constraint (e.g. *"no superusers"*, *"CNPG best practice"*, *"use the config named X"*), **treat it as a hard rule**.
- Never suggest or retry approaches that violate explicitly rejected patterns.
- Do **not** "double-check" by rerunning the same commands hoping for a different result.

✅ Good: "CNPG forbids superusers; we must work within managed roles."
❌ Bad: Re-running `psql -U postgres` grants after user objected.

#### 2. Never Re-run Identical Commands After User Pushback
- If the user complains about repeated commands, **stop immediately**.
- Switch to:
  - static reasoning
  - reading configs
  - explaining *why* something fails
- Repetition without new information is strictly disallowed.

Trigger phrase examples:
- "stop running the same commands"
- "that's an antipattern"
- "why are you doing this again"

#### 3. Config Is Source of Truth
- When the user says *"use the config"*:
  - Stop mutating runtime state manually
  - Stop issuing `GRANT`, `ALTER`, `CREATE` commands
  - Only reason from:
    - Kubernetes manifests
    - operator CRDs (CNPG)
    - application config files
- All fixes must be expressed **as declarative config changes**, not imperative commands.

✅ Correct: Modify `database.yaml`, `proxy_server_config.yaml`
❌ Incorrect: Applying runtime SQL grants repeatedly

#### 4. Operator-Managed Resources Must Be Solved at Operator Level
- For Kubernetes operators (CNPG, Argo, etc.):
  - Do not invent unsupported fields
  - Validate CRD schema mentally before suggesting changes
- If an error says `unknown field`, the fix is:
  - Remove it
  - Or use the operator's supported mechanism (roles, bootstrap SQL, init scripts)

✅ Correct: "CNPG v1 does not support `managed.roles[].privileges`"
❌ Incorrect: Retrying `kubectl apply` with the same invalid schema

#### 5. Diagnose Root Cause Before Acting
Before running *any* command, answer silently:
1. What component is failing?
2. Why is it failing?
3. Who is responsible for fixing it (app, DB, operator, config)?

In debugging sessions, the real causes are often:
- Application attempting database creation with insufficient privileges
- App pointing to wrong database name
- Operator app user lacking CREATE DATABASE, by design

Commands should only confirm a hypothesis, not replace thinking.

#### 6. Application Expectations vs Platform Guarantees Must Be Reconciled
- If an application assumes:
  - superuser privileges
  - CREATE DATABASE rights
  - schema ownership
- And the platform forbids it:
  - The fix is **application configuration**, not privilege escalation.

Rule:
> Always downgrade the application's expectations to match the platform, never the reverse.

#### 7. Avoid Tool Thrashing
- Do not alternate rapidly between:
  - kubectl
  - SQL
  - file edits
without a clear plan.
- Every tool invocation must introduce **new information**.

If no new information is needed → explain, don't execute.

#### 8. Acknowledge User Frustration and Adapt
- When the user escalates language:
  - Shorten responses
  - Stop exploratory actions
  - Provide a single, clear corrective explanation

Do **not** defend previous actions. Pivot immediately.

#### 9. Health Checks Passing ≠ System Working
- If `/health` is OK but auth/migrations fail:
  - Treat the app as **logically broken**
  - Focus on startup hooks, migrations, and auth paths

Never declare success based on readiness alone.

#### 10. Summarize the Fix Path Explicitly
At the end of analysis, always provide:
- What was wrong (1–2 bullets)
- Where it must be fixed (file/operator/config)
- What must *not* be done again

Example:
> "The failure is Prisma trying to create a database using a CNPG app user. Fix by pointing LiteLLM to the existing `app` database and disabling database-creation migrations. Do not add superusers or runtime grants."

#### One-Line Meta Rule (Most Important)
> **If the user tells you *how* to fix something, your job is to explain *why it works*, not to try alternative fixes.**

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

## Directory Map & Nested AGENTS

This repository follows a hierarchical AGENTS.md structure. The closest AGENTS.md to a target file takes precedence for that scope.

### Active Nested AGENTS.md Files

The following directories have their own AGENTS.md files with scope-specific guidance:

- **`k8s/AGENTS.md`** — Kubernetes manifests, kustomize overlays, and GitOps patterns. Covers both `k8s/applications/` and `k8s/infrastructure/`.
- **`k8s/applications/ai/AGENTS.md`** — AI-specific patterns, GPU access, vector databases, and shared resources like Qdrant.
- **`tofu/AGENTS.md`** — OpenTofu/Terraform infrastructure provisioning (VMs, networking, cluster bootstrap).
- **`images/AGENTS.md`** — Custom container images and Dockerfiles, CI build patterns.
- **`website/AGENTS.md`** — Docusaurus documentation site, build and lint commands.

### Application Categories

Application categories under `k8s/applications/` follow the patterns defined in `k8s/AGENTS.md`:

- `k8s/applications/ai/` — AI and ML applications (LiteLLM, OpenHands, etc.) **[Has dedicated AGENTS.md]**
- `k8s/applications/automation/` — Home automation (Home Assistant, Frigate, MQTT, Zigbee2MQTT)
- `k8s/applications/external/` — External service proxies (Proxmox, TrueNAS)
- `k8s/applications/media/` — Media management (Jellyfin, Immich, arr-stack, Audiobookshelf)
- `k8s/applications/network/` — Network services (Unifi)
- `k8s/applications/tools/` — Utility applications (IT-Tools, Unrar)
- `k8s/applications/web/` — Web applications (BabyBuddy, HeadlessX, Pinepods)

Note: Category-level AGENTS.md files can be added when a category develops unique patterns or workflows not covered by `k8s/AGENTS.md`.

### Agent Maintenance

AGENTS.md files are maintained according to the specification in `.github/agents/agents-maintainer.agent.md`. When making architectural or workflow changes, update the relevant AGENTS.md files in the same PR.

---

Completion note: keep AGENTS files concise, example-rich, and always up-to-date with infra and repo changes.
