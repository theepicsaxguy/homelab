# syntax=docker/dockerfile:1
# Runs Next.js in development mode so NEXT_PUBLIC_* env vars are read at
# runtime rather than baked into a static build.  The .next cache directory
# must be backed by a writable volume (emptyDir in k8s).

###############################################################################
# Stage 0: fetch source and install Node deps
###############################################################################
FROM node:24-alpine AS build
ARG IMAGE_VERSION=3.4.3 # renovate: github-releases=assafelovic/gpt-researcher

RUN apk add --no-cache git ca-certificates

RUN git clone --depth 1 --branch "v${IMAGE_VERSION}" \
    https://github.com/assafelovic/gpt-researcher.git /src

WORKDIR /src/frontend/nextjs

# No lock file in upstream; --legacy-peer-deps matches upstream Dockerfile.dev
RUN npm install --legacy-peer-deps

###############################################################################
# Stage 1: runtime
###############################################################################
FROM node:24-alpine

RUN addgroup -g 1001 nextjs \
    && adduser -S -u 1001 -G nextjs nextjs

COPY --from=build --chown=nextjs:nextjs /src/frontend/nextjs /app

WORKDIR /app

# .next is intentionally left absent; it will be populated at runtime by
# next dev and should be backed by a writable volume.

USER 1001

EXPOSE 3000

CMD ["npm", "run", "dev"]
