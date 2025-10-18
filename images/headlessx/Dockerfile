# syntax=docker/dockerfile:1

###############################################################################
# Stage 1: Clone and build HeadlessX from source
###############################################################################
FROM node:23-alpine AS builder

ARG IMAGE_VERSION=1.2.0
ARG HEADLESSX_REPO=https://github.com/saifyxpro/HeadlessX

RUN apk add --no-cache git ca-certificates \
  && update-ca-certificates

WORKDIR /src

RUN if [ "${IMAGE_VERSION}" = "latest" ]; then REF="main"; else REF="v${IMAGE_VERSION}"; fi \
  && git clone --depth 1 --branch "${REF}" "${HEADLESSX_REPO}" .

RUN npm ci --only=production \
  && npm cache clean --force

###############################################################################
# Stage 2: Runtime image
###############################################################################
FROM node:23-alpine

RUN apk add --no-cache tzdata chromium \
  && mkdir -p /app/logs /tmp

WORKDIR /app

COPY --from=builder /src /app

# Set environment variables
ENV NODE_ENV=production \
    PORT=3000 \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

VOLUME ["/app/logs"]

EXPOSE 3000

USER node

ENTRYPOINT ["node", "src/index.js"]
