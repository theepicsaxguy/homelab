# syntax=docker/dockerfile:1
# HeadlessX v1.2.0 - Modular Browserless Web Scraping API
# Multi-stage build for optimized production image with modular architecture

###############################################################################
# Stage 1: Clone HeadlessX source
###############################################################################
FROM alpine:3.23 AS source

ARG IMAGE_VERSION=2.0.2 # renovate: github-releases=saifyxpro/HeadlessX
ARG HEADLESSX_REPO=https://github.com/saifyxpro/HeadlessX

RUN apk add --no-cache git ca-certificates

WORKDIR /src

RUN REF=$([ "${IMAGE_VERSION}" = "latest" ] && echo "main" || echo "v${IMAGE_VERSION}") && \
    git clone --depth 1 --branch "${REF}" "${HEADLESSX_REPO}" .

###############################################################################
# Stage 2: Build website
###############################################################################
FROM node:24-slim AS website-builder

WORKDIR /app/website

COPY --from=source /src/website/package*.json ./
RUN npm ci --prefer-offline --no-audit

COPY --from=source /src/website/ ./
RUN npm run build

###############################################################################
# Stage 3: Production runtime
###############################################################################
FROM mcr.microsoft.com/playwright:v1.58.2-noble

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Node.js dependencies
COPY --from=source /src/package*.json ./
RUN if [ -f "package-lock.json" ]; then \
    npm ci --omit=dev --prefer-offline --no-audit; \
    else \
    npm install --production --prefer-offline --no-audit; \
    fi && \
    npm cache clean --force

# Copy application files
COPY --from=source /src/src/ ./src/
COPY --from=website-builder /app/website/out/ ./website/out/

# Setup directories and permissions
RUN mkdir -p logs && \
    groupadd -r headlessx && \
    useradd -r -g headlessx -m headlessx && \
    chown -R headlessx:headlessx /app

# Configuration
ENV NODE_ENV=production \
    PORT=3000 \
    AUTH_TOKEN="" \
    DOMAIN=localhost \
    SUBDOMAIN=headlessx

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

USER headlessx

CMD ["node", "src/server.js"]
