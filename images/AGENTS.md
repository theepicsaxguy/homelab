# Container Images - Domain Guidelines

SCOPE: Custom container images and Dockerfiles
INHERITS FROM: ../AGENTS.md
TECHNOLOGIES: Docker, Docker Compose, GitHub Actions

## DOMAIN CONTEXT

Purpose:
Define and build custom container images for homelab applications, including Dockerfiles, build scripts, and CI/CD pipelines.

Boundaries:
- Handles: Dockerfiles, multi-stage builds, local testing, CI build pipelines
- Does NOT handle: Kubernetes manifests (see k8s/), infrastructure (see tofu/)
- Integrates with: k8s/ (image references in manifests), GitHub Actions (CI builds)

Architecture:
- `images/<image-name>/` - Directory per image with Dockerfile and supporting files
- `images/<image-name>/Dockerfile` - Multi-stage build definition
- `images/<image-name>/entrypoint.py` - Entry point scripts (Python images)
- `images/<image-name>/README.md` - Documentation and usage instructions
- `images/<image-name>/.dockerignore` - Build context exclusions

## QUICK-START COMMANDS

```bash
# Build an image locally
docker build -t local/<image-name>:dev images/<image-name>/

# Run container locally
docker run --rm -it local/<image-name>:dev /bin/bash

# Test container with specific command
docker run --rm local/<image-name>:dev <test-command>

# Push to registry (manual)
docker tag local/<image-name>:dev <registry>/<image-name>:<version>
docker push <registry>/<image-name>:<version>
```

## TECHNOLOGY CONVENTIONS

### Dockerfile Structure
- Use multi-stage builds to minimize final image size
- Pin base images to specific versions (e.g., `python:3.11-slim`)
- Add labels for metadata (maintainer, description, version)
- Run as non-root user with `USER` directive
- Use `.dockerignore` to exclude unnecessary files

### Image Tagging
- Use semantic versioning: `1.0.0`, `1.1.0`, etc.
- Use descriptive tags for variants: `1.0.0-cpu`, `1.0.0-gpu`
- CI generates tags from git refs or tags
- Never use `latest` tag in production

### Base Images
- Use official images when possible (`python`, `node`, `alpine`)
- Pin to specific versions, not `latest` or rolling tags
- Prefer slim or alpine variants for smaller images
- Use distroless images for security-critical workloads

## PATTERNS

### Multi-Stage Build Pattern
Use multiple FROM statements to create layers and discard build dependencies. Final stage contains only runtime dependencies. Example: Build stage compiles code, runtime stage copies binaries.

### Security Pattern
- Run as non-root user with `USER` directive
- Don't include secrets or credentials in Dockerfile
- Use `.dockerignore` to exclude sensitive files
- Scan images with security tools (Trivy, Clair)
- Keep base images updated with security patches

### Optimization Pattern
- Use `.dockerignore` to reduce build context size
- Order Dockerfile instructions by change frequency (least frequently changed first)
- Combine RUN commands to reduce layers
- Use build cache effectively by layering correctly

### CI/CD Pattern
GitHub Actions workflow `image-build.yaml` builds images when:
- Files under `images/<name>/` change
- Git tag `image-<version>` is pushed
- Images are pushed to registry and deployed via Kubernetes manifests

## TESTING

Strategy:
- Local build test: Verify Dockerfile builds successfully
- Smoke test: Run container and verify basic functionality
- Language-specific tests: Run unit tests inside container or mount source
- CI validation: GitHub Actions builds images on PR

Requirements:
- Dockerfile builds without errors
- Container runs and exits cleanly
- Entry point scripts work correctly
- No secrets or credentials in Dockerfile
- Non-root user execution

Tools:
- docker build: Build images locally
- docker run: Test container execution
- docker inspect: Verify image metadata
- GitHub Actions: CI/CD builds and deployments

## WORKFLOWS

Development:
- Create directory: `images/<image-name>/`
- Write Dockerfile with multi-stage build
- Add `.dockerignore` file
- Add `README.md` with usage instructions
- Test locally: `docker build -t local/<image-name>:dev images/<image-name>/`
- Run smoke test: `docker run --rm local/<image-name>:dev <test-command>`
- Language-specific: Run unit tests inside container

Build:
- Local: `docker build -t <tag> images/<image-name>/`
- CI: Automatic on file changes or git tags
- Tagging: Use semantic versioning in tags

Deployment:
- Commit Dockerfile and supporting files
- GitHub Actions workflow triggers on PR/merge
- CI builds and pushes image to registry
- Kubernetes manifests reference new image tag
- Argo CD deploys updated manifests to cluster

## COMPONENTS

### Existing Images
- `headlessx/` - Headless browser automation
- `sabnzbd/` - Usenet download client with custom entrypoint
- `vllm-cpu/` - CPU-optimized LLM inference

### CI/CD
- `image-build.yaml` - GitHub Actions workflow for building images
- Triggers: File changes, git tags

## ANTI-PATTERNS

Never commit secrets or credentials to Dockerfiles or build context.

Never use `latest` tag for base images or production images. Pin specific versions.

Never skip `.dockerignore` file. Exclude unnecessary files from build context.

Never run containers as root user. Use `USER` directive to set non-root user.

Never build large images. Use multi-stage builds and slim base images.

Never skip local testing before committing. Build and run smoke tests.

Never commit large binary assets to image directories. Use external storage if needed.

## HOW TO ADD NEW IMAGE

1. Create directory: `images/<image-name>/`
2. Add `Dockerfile` with multi-stage build pattern
3. Add `.dockerignore` file to exclude unnecessary files
4. Add `README.md` documenting purpose, build args, and usage
5. Add entry point script if needed (e.g., `entrypoint.py`)
6. Test locally: `docker build -t local/<image-name>:dev images/<image-name>/`
7. Run smoke test: `docker run --rm local/<image-name>:dev <test-command>`
8. Create PR (GitHub Actions will build and publish on merge)

## CRITICAL BOUNDARIES

Never commit secrets or credentials to Dockerfile or build context.

Never include sensitive data in images (passwords, API keys, certificates).

Never use `latest` tag for base images. Pin specific versions.

Never skip local testing before committing changes.

Never build images without `.dockerignore` file.

## REFERENCES

For commit message format, see root AGENTS.md

For Kubernetes deployment, see k8s/AGENTS.md

For Docker best practices, see Docker documentation
