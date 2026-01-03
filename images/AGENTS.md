# Container Images - Domain Guidelines

SCOPE: Custom container images and Dockerfiles
INHERITS FROM: /AGENTS.md
TECHNOLOGIES: Docker, Docker Compose, GitHub Actions

## DOMAIN CONTEXT

Purpose: Define and build custom container images for homelab applications.

Architecture:
- `images/<image-name>/` - Directory per image with Dockerfile and supporting files
- `images/<image-name>/Dockerfile` - Multi-stage build definition
- `images/<image-name>/entrypoint.py` - Entry point scripts (Python images)
- `images/<image-name>/.dockerignore` - Build context exclusions

## QUICK-START COMMANDS

```bash
# Build locally
docker build -t local/<image-name>:dev images/<image-name>/

# Test container
docker run --rm -it local/<image-name>:dev /bin/bash
docker run --rm local/<image-name>:dev <test-command>

# Push to registry
docker tag local/<image-name>:dev <registry>/<image-name>:<version>
docker push <registry>/<image-name>:<version>
```

## PATTERNS

### Multi-Stage Build Pattern
Use multiple FROM statements to create layers and discard build dependencies. Final stage contains only runtime dependencies.

### Security Pattern
- Run as non-root user with `USER` directive
- Don't include secrets in Dockerfile
- Use `.dockerignore` to exclude sensitive files
- Keep base images updated with security patches

### Optimization Pattern
- Use `.dockerignore` to reduce build context size
- Order Dockerfile instructions by change frequency
- Combine RUN commands to reduce layers
- Use build cache effectively

### CI/CD Pattern
GitHub Actions `image-build.yaml` builds images when:
- Files under `images/<name>/` change
- Git tag `image-<version>` is pushed
- Images are pushed to registry and deployed via Kubernetes manifests

## TESTING

- Local build test: Verify Dockerfile builds successfully
- Smoke test: Run container and verify basic functionality
- Requirements: Dockerfile builds, container runs cleanly, no secrets in Dockerfile, non-root user execution

## WORKFLOWS

**Development:**
- Create directory `images/<image-name>/`
- Write Dockerfile with multi-stage build
- Add `.dockerignore` and `README.md`
- Test locally: `docker build -t local/<image-name>:dev images/<image-name>/`
- Run smoke test: `docker run --rm local/<image-name>:dev <test-command>`

**Build & Deploy:**
- Commit Dockerfile and supporting files
- GitHub Actions workflow triggers on PR/merge
- CI builds and pushes image to registry
- Kubernetes manifests reference new image tag

## COMPONENTS

### Existing Images
- `headlessx/` - Headless browser automation
- `sabnzbd/` - Usenet download client with custom entrypoint
- `vllm-cpu/` - CPU-optimized LLM inference

### CI/CD
- `image-build.yaml` - GitHub Actions workflow for building images

## IMAGES-DOMAIN ANTI-PATTERNS

### Security & Safety
- Never commit secrets or credentials to Dockerfile or build context
- Never include sensitive data in images (passwords, API keys, certificates)
- Never run containers as root user - use `USER` directive

### Build & Tagging
- Never use `latest` tag for base images or production images - pin specific versions
- Never build large images - use multi-stage builds and slim base images
- Never skip local testing before committing - build and run smoke tests
- Never build images without `.dockerignore` file

## ADDING NEW IMAGES

1. Create directory: `images/<image-name>/`
2. Add `Dockerfile` with multi-stage build
3. Add `.dockerignore` file
4. Add `README.md` documenting purpose and usage
5. Add entry point script if needed
6. Test locally with `docker build` and `docker run`
7. Create PR (GitHub Actions will build and publish on merge)

## REFERENCES

## Container Security Philosophy

### Security as Learning
Container security patterns teach enterprise defense-in-depth:
- Multi-stage builds = enterprise build pipeline security
- Non-root containers = enterprise principle of least privilege
- Secret management = enterprise security operations

### Production Security Standards
Enterprise environments require:
- Security scanning at every build
- Immutable infrastructure patterns
- Zero-trust networking principles
- Comprehensive audit trails

### Integration with Cluster Security
Container security extends to cluster security:
- Image security → Pod security policies
- Build secrets → Runtime secret management
- CI/CD patterns → GitOps security pipelines

### Enterprise Compliance Patterns
- SBOM generation teaches enterprise software supply chain security
- Vulnerability scanning teaches enterprise compliance
- Signed images teach enterprise software trust

## REFERENCES

For commit format: /AGENTS.md
For Kubernetes deployment: k8s/AGENTS.md
For Docker best practices: Docker documentation