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
- **Release Please**: Automated changelog and versioning

## Architecture

### GitOps with Argo CD

The cluster uses Argo CD ApplicationSets to automatically deploy everything from Git:

1. **Infrastructure ApplicationSet** (`k8s/infrastructure/application-set.yaml`):
   - Sync wave: `-10` (deployed first)
   - Auto-discovers directories under `k8s/infrastructure/`
   - Manages: controllers, network, storage, auth, database, monitoring, deployment, CRDs
   - Project: `infrastructure`

2. **Applications ApplicationSet** (`k8s/applications/application-set.yaml`):
   - Sync wave: `0` (deployed after infrastructure)
   - Auto-discovers directories under `k8s/applications/`
   - Categories: ai, media, tools, web, network, automation, external
   - Project: `applications`

When adding a new application or infrastructure component, simply create a new directory with a `kustomization.yaml` file in the appropriate location. Argo CD will automatically discover and deploy it.

### Key Infrastructure Components

- **Networking**: Cilium (eBPF-based CNI), Gateway API for ingress, Cloudflared for tunnels
- **Storage**: Longhorn (distributed block storage)
- **Secrets**: External Secrets Operator (syncs from Bitwarden)
- **Auth**: Authentik (SSO)
- **Certificates**: cert-manager (automated TLS)
- **Database**: Zalando Postgres Operator
- **Backup**: Velero
- **GPU**: NVIDIA GPU Operator and device plugin
- **Controllers**: Argo CD, Crossplane, External Secrets, cert-manager

### Infrastructure Provisioning

OpenTofu provisions:
- Talos Linux VMs on Proxmox
- Kubernetes cluster configuration
- Load balancer VMs (HAProxy)
- Network configuration (VIP, gateway, DNS)
- Inline manifests for Cilium and CoreDNS

The Talos module (`tofu/talos/`) generates:
- Machine configs (control plane and worker nodes)
- Cluster configuration
- Client configuration (talosctl)
- Inline manifests injected during bootstrap

### Kustomize Structure

Every application and infrastructure component:
1. Lives in its own directory with a `kustomization.yaml`
2. Is referenced in the parent directory's `kustomization.yaml`
3. May include Helm charts, raw manifests, or both
4. Uses Kustomize's `generatorOptions.disableNameSuffixHash: true`

Example application structure:
```
k8s/applications/ai/litellm/
├── kustomization.yaml
├── deployment.yaml
├── service.yaml
└── httproute.yaml
```

### Custom Images

Custom container images are in `images/` with their own Dockerfiles:
- `headlessx/`: VNC/remote desktop container
- `sabnzbd/`: Usenet downloader
- `spilo17-vchord/`: Custom Postgres image with pgvector and vector-chord extensions

Images are built via GitHub Actions workflow (`image-build.yaml`) when:
- Files in the image directory change
- A tag matching `image-<version>` is pushed

## Adding New Components

### Adding an Application

1. Create directory: `k8s/applications/<category>/<app-name>/`
2. Add `kustomization.yaml` and manifests
3. Update `k8s/applications/<category>/kustomization.yaml` to include the new app
4. Commit and push - Argo CD will auto-deploy

### Adding Infrastructure

1. Create directory: `k8s/infrastructure/<component-name>/`
2. Add `kustomization.yaml` and manifests
3. Update `k8s/infrastructure/kustomization.yaml` to include the new component
4. Consider sync wave ordering (infrastructure uses wave `-10`)
5. Commit and push - Argo CD will auto-deploy

### Adding Custom Images

1. Create directory: `images/<image-name>/`
2. Add `Dockerfile` and any required files
3. GitHub Actions will build on file changes or `image-<version>` tags

## Important Notes

- **No manual kubectl apply**: Changes must go through Git for GitOps to work
- **ApplicationSets auto-discover**: New directories are automatically picked up by Argo CD
- **Helm via Kustomize**: Use `kustomize build --enable-helm` when testing Helm-based applications
- **Sync options**: Applications use ServerSideApply, PruneLast, and RespectIgnoreDifferences
- **Node requirements**: Node.js >=20.18.1, npm >=10.0.0
- **Documentation**: Primary docs site is at https://homelab.orkestack.com/

## CI/CD Workflows

- `image-build.yaml`: Builds custom Docker images
- `website-build.yaml`: Builds and deploys documentation site
- `vale.yaml`: Lints documentation prose
- `claude.yaml`: Claude Code integration
- `release-please.yml`: Automated releases and changelogs

## Testing Changes

Before submitting PRs:
1. Kubernetes: Run `kustomize build --enable-helm` on modified directories
2. OpenTofu: Run `tofu fmt` and `tofu validate` in `tofu/`
3. Website: Run `npm install`, `npm run typecheck`, and `npm run lint:all` in `website/`
4. Documentation: Run `pre-commit run --files <changed-files>` to validate with Vale
5. Validation happens via Kubechecks before Argo CD rollout
