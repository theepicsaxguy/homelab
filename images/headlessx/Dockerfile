FROM node:20-slim AS website-builder

WORKDIR /app/website

COPY website/package*.json ./
RUN npm ci

COPY website/ ./
RUN npm run build

FROM mcr.microsoft.com/playwright:v1.56.0-noble

RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN if [ -f "package-lock.json" ]; then \
        npm ci --omit=dev; \
    else \
        npm install --production; \
    fi && npm cache clean --force

COPY src/ ./src/
COPY --from=website-builder /app/website/out/ ./website/out/

RUN mkdir -p logs
RUN groupadd -r headlessx && useradd -r -g headlessx headlessx
RUN chown -R headlessx:headlessx /app

ENV NODE_ENV=production \
    PORT=3000 \
    AUTH_TOKEN="" \
    DOMAIN=localhost \
    SUBDOMAIN=headlessx

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

USER headlessx

CMD ["node", "src/server.js"]
