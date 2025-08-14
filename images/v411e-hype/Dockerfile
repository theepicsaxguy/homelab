# syntax=docker/dockerfile:1
FROM python:3.13-alpine

ARG IMAGE_VERSION=1.0.0
ARG HYPEBOT_REPO=https://github.com/goingdark-social/hypebot

RUN apk add --no-cache git tzdata file py3-pip ca-certificates \
  && update-ca-certificates

WORKDIR /app

RUN if [ "${IMAGE_VERSION}" = "latest" ]; then REF="main"; else REF="${IMAGE_VERSION}"; fi \
  && git clone --depth 1 --branch "${REF}" "${HYPEBOT_REPO}" .

RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
  && pip install --no-cache-dir -r requirements.txt

RUN mkdir -p /app/config /app/secrets

VOLUME ["/app/config", "/app/secrets"]

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1

ENTRYPOINT ["python", "-m", "hype"]
