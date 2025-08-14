# syntax=docker/dockerfile:1

FROM python:3.13-alpine

# Pin to latest release by default; workflow can override via SAB_VERSION
ARG IMAGE_VERSION=1.0.0
ARG SAB_VERSION=${IMAGE_VERSION}

# Source repo and ref
ARG HYPEBOT_REPO=https://github.com/v411e/hype

# Minimal runtime deps + CA certs for git over HTTPS
RUN apk add --no-cache git tzdata file py3-pip ca-certificates \
  && update-ca-certificates

WORKDIR /app

# Pick git ref from SAB_VERSION. If latest, use main.
RUN if [ "${SAB_VERSION}" = "latest" ]; then REF="main"; else REF="${SAB_VERSION}"; fi \
  && git clone --depth 1 --branch "${REF}" "${HYPEBOT_REPO}" .

# Python deps
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
  && pip install --no-cache-dir -r requirements.txt

# Ensure writable dirs exist
RUN mkdir -p /app/config /app/secrets

VOLUME ["/app/config", "/app/secrets"]

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1

ENTRYPOINT ["python", "-m", "hype"]
