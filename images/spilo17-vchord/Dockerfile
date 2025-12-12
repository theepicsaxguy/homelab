FROM ghcr.io/zalando/spilo-17:4.0-p2
LABEL org.opencontainers.image.description="PostgreSQL 17 with VectorChord extension"

ARG VCHORD_VERSION=0.3.0 # renovate: github-releases=tensorchord/VectorChord
ARG IMAGE_VERSION=0.1.0


RUN curl -o vchord.deb -fsSL https://github.com/tensorchord/VectorChord/releases/download/${VCHORD_VERSION}/postgresql-17-vchord_${VCHORD_VERSION}-1_amd64.deb && \
    dpkg -i vchord.deb && rm -f vchord.deb
