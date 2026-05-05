# syntax=docker/dockerfile:1

###############################################################################
# Stage 0: fetch source and install Python deps
###############################################################################
FROM python:3.12-slim AS build
ARG IMAGE_VERSION=3.4.4 # renovate: github-releases=assafelovic/gpt-researcher

RUN apt-get update && apt-get install -y --no-install-recommends \
        git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
RUN git clone --depth 1 --branch "v${IMAGE_VERSION}" \
        https://github.com/assafelovic/gpt-researcher.git .

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Patch missing `import os` in v3.4.3 websocket_manager (upstream bug)
RUN sed -i '1s/^/import os\n/' backend/server/websocket_manager.py

###############################################################################
# Stage 1: runtime — non-root, minimal image
###############################################################################
FROM python:3.12-slim

RUN groupadd -g 3000 researcher \
    && useradd -u 1000 -g 3000 -m -s /bin/sh -d /usr/src/app researcher

# Copy installed packages and binaries from build stage
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /usr/local/bin /usr/local/bin

# Copy application source, owned by runtime user
COPY --from=build --chown=1000:3000 /usr/src/app /usr/src/app

WORKDIR /usr/src/app

# Writable runtime directories; actual data is mounted via PVC in k8s
RUN mkdir -p outputs logs my-docs \
    && chown 1000:3000 outputs logs my-docs

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER 1000

EXPOSE 8000

CMD ["python", "main.py"]
