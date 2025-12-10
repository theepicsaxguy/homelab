# Images (images/) - Agent Guidelines

This `AGENTS.md` covers custom container images stored under `images/`.

## Purpose & Scope

- Scope: `images/` directories containing Dockerfiles and supporting build files.
- Goal: allow agents to add or update Dockerfiles, helper scripts, and local test harnesses; CI builds are handled by GitHub Actions.

## Quick-start Commands

Run from repository root or the image directory.

```bash
# Build an image locally (example: images/spilo17-vchord)
docker build -t local/spilo17-vchord:dev images/spilo17-vchord/

# Run container locally
docker run --rm -it local/spilo17-vchord:dev /bin/bash

# For testing Python-based images, use a virtualenv and run test harness inside container
```

Notes:
- GitHub Actions `image-build.yaml` builds images when files under `images/<name>/` change or when a tag `image-<version>` is pushed.
- Keep images small and multi-stage build optimized.

## Structure & Examples

- Typical image dir: `images/<name>/Dockerfile`, `entrypoint.py`, `README.MD`.
- Example images present: `headlessx/`, `sabnzbd/`, `spilo17-vchord/`, `vllm-cpu/`.

## CI & Publishing

- CI builds images via `image-build.yaml`. If you modify an image, include a README and minimal changelog in the image directory.
- Do not hardcode registry credentials; CI uses repository secrets to push.

## Tests & Validation

- Local build + smoke-run is usually sufficient.
- For language-specific images, run their unit tests inside the container or by mounting source into the container at runtime.

## Code Style & Patterns

- Use multi-stage builds to minimize final image size
- Run containers as non-root user (add `USER` directive)
- Pin base image versions for reproducibility (e.g., `python:3.11-slim`, not `python:latest`)
- Label images with metadata (maintainer, description, version)
- Use `.dockerignore` to exclude unnecessary files from build context
- Reference existing images for patterns: `images/spilo17-vchord/Dockerfile`, `images/vllm-cpu/Dockerfile`

## How to Add a New Image

1. Create directory: `images/<image-name>/`
2. Add `Dockerfile` with multi-stage build pattern
3. Add `README.md` documenting purpose, build args, and usage
4. Test locally: `docker build -t local/<image-name>:dev images/<image-name>/`
5. Run smoke test: `docker run --rm -it local/<image-name>:dev <test-command>`
6. Create PR (GitHub Actions will build and publish on merge)

## Boundaries & Safety

- Never commit secrets or credentials to image files
- Do not include sensitive data in build context
- CI uses repository secrets for registry authentication
- Image tags are generated from git tags or commits by CI

## Pre-Merge Checklist

Before merging container image changes, verify:

- [ ] Image builds successfully locally: `docker build -t test images/<name>/`
- [ ] Container runs and passes smoke tests
- [ ] Dockerfile uses multi-stage build for optimization
- [ ] Container runs as non-root user
- [ ] Base images are pinned to specific versions (not `latest`)
- [ ] README.md documents build args, usage, and entry points
- [ ] `.dockerignore` excludes unnecessary files
- [ ] Image includes proper labels (maintainer, version)
- [ ] No secrets or credentials in Dockerfile or build context
- [ ] CI workflow (`image-build.yaml`) will trigger on merge

---

