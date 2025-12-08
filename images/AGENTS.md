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

---
