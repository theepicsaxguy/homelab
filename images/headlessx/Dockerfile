# syntax=docker/dockerfile:1
# HeadlessX v1.2.0 - Modular Browserless Web Scraping API
# Multi-stage build for optimized production image with modular architecture

###############################################################################
# Stage 1: Clone HeadlessX source
###############################################################################
FROM alpine:3.22 AS source

ARG IMAGE_VERSION=1.2.0
ARG HEADLESSX_REPO=https://github.com/saifyxpro/HeadlessX

RUN apk add --no-cache git ca-certificates

WORKDIR /src

RUN if [ "${IMAGE_VERSION}" = "latest" ]; then REF="main"; else REF="v${IMAGE_VERSION}"; fi \
  && git clone --depth 1 --branch "${REF}" "${HEADLESSX_REPO}" .

###############################################################################
# Stage 2: Build website
###############################################################################
FROM node:20-slim AS website-builder

WORKDIR /app/website

# Copy website package files from source
COPY --from=source /src/website/package*.json ./

# Install website dependencies
RUN npm ci

# Copy website source
COPY --from=source /src/website/ ./

# Build website for production
RUN npm run build

###############################################################################
# Stage 3: Production runtime
###############################################################################
FROM mcr.microsoft.com/playwright:v1.56.0-noble

# Install essential system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files from source
COPY --from=source /src/package*.json ./

# Install production dependencies
RUN if [ -f "package-lock.json" ]; then \
    npm ci --omit=dev; \
    else \
    npm install --production; \
    fi && npm cache clean --force

# Copy modular application source
COPY --from=source /src/src/ ./src/

# Copy built website from previous stage
COPY --from=website-builder /app/website/out/ ./website/out/

# Create logs directory
RUN mkdir -p logs

# Create non-root user for security (using UID/GID 1000 to match Kubernetes deployment)
RUN groupadd -r -g 1000 headlessx && useradd -r -u 1000 -g headlessx headlessx
RUN chown -R headlessx:headlessx /app

# Environment variables (override with docker-compose or runtime)
ENV NODE_ENV=production
ENV PORT=3000
ENV AUTH_TOKEN=""
ENV DOMAIN=localhost
ENV SUBDOMAIN=headlessx

# Expose the application port directly
EXPOSE 3000

# Health check targets the Node.js application directly
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

# Switch to non-root user for security
USER headlessx

# Start the Node.js application directly
CMD ["node", "src/server.js"]
