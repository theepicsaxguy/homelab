# syntax=docker/dockerfile:1

FROM python:3.12-alpine

# Match workflow: it looks for SAB_VERSION or IMAGE_VERSION and passes SAB_VERSION
ARG IMAGE_VERSION=latest
ARG SAB_VERSION=${IMAGE_VERSION}

# Source repo and ref
ARG HYPEBOT_REPO=https://github.com/v411e/hype

# Minimal runtime deps
RUN apk add --no-cache git tzdata file py3-pip

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