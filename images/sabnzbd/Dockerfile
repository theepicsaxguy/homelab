# syntax=docker/dockerfile:1

#############################################################
# Builder stage: Python 3.12 slim, SABNZBD from release tarball
#############################################################
FROM python:3.12-slim AS build

ARG SAB_VERSION=4.5.2
ARG SAB_SRC_URL="https://github.com/sabnzbd/sabnzbd/releases/download/${SAB_VERSION}/SABnzbd-${SAB_VERSION}-src.tar.gz"
ENV VENV=/venv

# Install runtime helpers SAB uses
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      curl \
      ca-certificates \
      unzip \
      p7zip-full \
      par2 \
      unrar && \
    rm -rf /var/lib/apt/lists/*

# Create venv and install SAB from official release tarball
RUN python -m venv $VENV && \
    curl -sSL "$SAB_SRC_URL" -o /tmp/sabnzbd.tar.gz && \
    tar -xzf /tmp/sabnzbd.tar.gz -C /tmp && \
    pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir /tmp/SABnzbd-${SAB_VERSION}

# Add SAB user
RUN adduser --uid 2501 --disabled-login --gecos '' sabnzbd

# Pre-generate default config file using SAB's own generator
RUN mkdir -p /defaults && \
    $VENV/bin/python -m sabnzbd --config-file /defaults/sabnzbd.ini --server 127.0.0.1:9 || true && \
    chown -R 2501:2501 /defaults

#############################################################
# Runtime stage: distroless, python3
#############################################################
FROM gcr.io/distroless/python3-debian12:nonroot

COPY --from=build /venv /venv
COPY --from=build /usr/bin/unrar /usr/bin/par2 /usr/bin/7z /usr/bin/
COPY --from=build /defaults /defaults

USER 2501:2501
ENV PATH="/venv/bin:$PATH"

# Ensure mountpoints exist
RUN mkdir -p /config /downloads/incomplete /app/data

VOLUME ["/config","/downloads/incomplete","/app/data"]
EXPOSE 8080

# Copy default ini if none exists in /config, then run SAB
ENTRYPOINT ["sh", "-c", "cp -n /defaults/sabnzbd.ini /config/sabnzbd.ini && exec python -m sabnzbd --config-file /config/sabnzbd.ini"]
