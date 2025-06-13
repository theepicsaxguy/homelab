FROM ghcr.io/zalando/spilo-17:4.0-p2

# Don't forget to run the update command on postgresql server
# https://immich.app/docs/administration/postgres-standalone#updating-vectorchord
ARG VCHORD_VERSION=0.3.0
ARG IMAGE_VERSION=0.1.0


RUN apt-get update \
    && apt-get install -y --no-install-recommends gnupg wget \
    && wget -qO /usr/share/keyrings/vectorchord.gpg https://apt.tensorchord.dev/VectorChord/gpg.key \
    && echo "deb [signed-by=/usr/share/keyrings/vectorchord.gpg] https://apt.tensorchord.dev/VectorChord stable main" > /etc/apt/sources.list.d/vectorchord.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-17-vchord=${VCHORD_VERSION}-1 \
    && apt-get purge -y --auto-remove gnupg wget \
    && rm -rf /var/lib/apt/lists/*
