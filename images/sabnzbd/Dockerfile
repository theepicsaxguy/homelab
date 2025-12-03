# images/sabnzbd/Dockerfile
# syntax=docker/dockerfile:1

###############################################################################
# Stage 0: build unrar from source (matches LSIO pattern)
###############################################################################
FROM alpine:3.23 AS unrar-build
ARG UNRAR_VER=6.2.12

RUN apk add --no-cache build-base ca-certificates curl tar \
     && update-ca-certificates \
     && curl -fsSL "https://www.rarlab.com/rar/unrarsrc-${UNRAR_VER}.tar.gz" -o /tmp/unrarsrc.tar.gz \
     && tar -xzf /tmp/unrarsrc.tar.gz -C /tmp \
     && make -C /tmp/unrar -f makefile -j"$(nproc)" \
     && install -Dm755 /tmp/unrar/unrar /out/usr/bin/unrar

###############################################################################
# Stage 1: build SABnzbd from source + venv (includes native deps)
###############################################################################
FROM alpine:3.23 AS sab-build
ARG IMAGE_VERSION=4.5.3

RUN apk add --no-cache \
     git ca-certificates tzdata \
     python3 py3-pip py3-virtualenv \
     build-base python3-dev musl-dev libffi-dev openssl-dev cargo

WORKDIR /src
RUN git clone --depth 1 --branch "${IMAGE_VERSION}" https://github.com/sabnzbd/sabnzbd.git .
RUN python3 -m venv /venv \
     && /venv/bin/pip install --upgrade pip setuptools wheel \
     && /venv/bin/pip install --no-cache-dir -r /src/requirements.txt \
     && /venv/bin/pip install --no-cache-dir sabctools \
     && /venv/bin/pip check

###############################################################################
# Stage 2: runtime (Kubernetes-ready)
###############################################################################
FROM alpine:3.23

RUN apk add --no-cache \
     ca-certificates tzdata tini \
     python3 py3-pip \
     libstdc++ p7zip par2cmdline ffmpeg su-exec

COPY --from=unrar-build /out/usr/bin/unrar /usr/bin/unrar
COPY --from=sab-build /venv /venv
COPY --from=sab-build /src /app

# Declarative env (overridable at runtime)
ENV PATH="/venv/bin:${PATH}" \
     PYTHONUNBUFFERED=1 \
     PYTHONDONTWRITEBYTECODE=1 \
     SAB_CONFIG_DIR=/config \
     SAB_DOWNLOAD_DIR=/downloads \
     SAB_INCOMPLETE_DIR=/downloads/incomplete \
     SAB_COMPLETE_DIR=/downloads/complete \
     SAB_HOST=0.0.0.0 \
     SAB_PORT=8080 \
     SAB_OVERWRITE_CONFIG=true \
     PUID=1000 \
     PGID=1000 \
     # Storage wait-probe defaults (apply to all FS, cheap on local; NFS-safe)
     SAB_WAIT_PROBE=1 \
     SAB_WAIT_TIMEOUT=60 \
     SAB_WAIT_INTERVAL=1 \
     SAB_WAIT_BACKOFF=1.5 \
     SAB_WAIT_MAX_INTERVAL=5 \
     SAB_WAIT_DIRS="download_dir,complete_dir,nzb_backup_dir"

WORKDIR /app
COPY entrypoint.py /entrypoint.py

VOLUME ["/config", "/downloads"]
EXPOSE 8080
ENTRYPOINT ["/sbin/tini","-g","--","/venv/bin/python","/entrypoint.py"] 