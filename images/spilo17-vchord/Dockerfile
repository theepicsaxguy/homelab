FROM ghcr.io/zalando/spilo-17:4.0-p2

# Don't forget to run the update command on postgresql server
# https://immich.app/docs/administration/postgres-standalone#updating-vectorchord
ARG VCHORD_VERSION=0.3.0
ARG VCHORD_SHA256=d68535ca1325d1260d294a7f8d9e4a18b74b8875d6e57f88895a6c7ef13992b5
ARG IMAGE_VERSION=0.1.0

RUN curl -fsSL -o vchord.deb https://github.com/tensorchord/VectorChord/releases/download/${VCHORD_VERSION}/postgresql-17-vchord_${VCHORD_VERSION}-1_amd64.deb && \
    echo "${VCHORD_SHA256}  vchord.deb" | sha256sum -c - && \
    dpkg -i vchord.deb && rm -f vchord.deb
