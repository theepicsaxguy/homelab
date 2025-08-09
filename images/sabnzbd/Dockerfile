# syntax=docker/dockerfile:1
###############################################################################
# Stage 0 – build unrar (static) + par2cmdline-turbo
###############################################################################
FROM alpine:3.22 AS prepstage
SHELL ["/bin/ash","-o","pipefail","-c"]

ARG UNRAR_VER=6.2.12
ARG UNRAR_MD5=1f526429e8e50a9b3b94f325b2848c24   # MD5 from BLFS/SlackBuilds

RUN apk add --no-cache \
        build-base curl openssl-dev git ca-certificates \
        automake autoconf libtool m4 && \
    ###########################################################################
    # 1.  Download *once* with --insecure (TLS chain is broken on rarlab.com)
    ###########################################################################
    curl -L --insecure -o unrarsrc.tar.gz \
         "https://www.rarlab.com/rar/unrarsrc-${UNRAR_VER}.tar.gz" && \
    echo "${UNRAR_MD5}  unrarsrc.tar.gz" | md5sum -c - && \
    ###########################################################################
    # 2.  Build static unrar
    ###########################################################################
    tar xf unrarsrc.tar.gz --strip-components=1 && \
    sed -i 's|LDFLAGS=-pthread|LDFLAGS=-pthread -static|' makefile && \
    make -j"$(nproc)" && install -m755 unrar /usr/local/bin/unrar && \
    ###########################################################################
    # 3.  Build par2cmdline-turbo (needs Autotools)
    ###########################################################################
    git clone --depth 1 https://github.com/animetosho/par2cmdline-turbo.git /tmp/par2 && \
    cd /tmp/par2 && aclocal && automake --add-missing && autoconf && \
    ./configure && make -j"$(nproc)" && make install


###############################################################################
# Stage 1 – build SABnzbd, create venv, collect runtime deps
###############################################################################
FROM alpine:3.22 AS build
SHELL ["/bin/ash","-o","pipefail","-c"]

ARG SAB_VERSION=4.3.2
ENV VENV=/venv

RUN apk add --no-cache python3 py3-pip py3-virtualenv git p7zip

# binaries from prepstage
COPY --from=prepstage /usr/local/bin/unrar /usr/local/bin/unrar
COPY --from=prepstage /usr/local/bin/par2  /usr/local/bin/par2

# build SABnzbd + default config
WORKDIR /app
RUN python3 -m venv $VENV \
 && $VENV/bin/pip install --upgrade pip setuptools wheel \
 && git clone --depth 1 --branch "$SAB_VERSION" \
        https://github.com/sabnzbd/sabnzbd.git /app/sabnzbd \
 && $VENV/bin/pip install --no-cache-dir -r /app/sabnzbd/requirements.txt \
 && mkdir /defaults \
 && $VENV/bin/python -m sabnzbd --config-file /defaults/sabnzbd.ini \
      --server 127.0.0.1:9 || true

# shared libs needed by par2 and 7z (unrar is static)
RUN mkdir /deps \
 && for bin in /usr/local/bin/par2 /usr/bin/7z; do \
      ldd "$bin" | awk '{print $3}' | grep -Ev '^$|^\(.*\)$' | \
      xargs -r -I '{}' cp --parents '{}' /deps; \
    done

###############################################################################
# Stage 2 – minimal distroless runtime 
###############################################################################
FROM gcr.io/distroless/python3-debian12:nonroot
LABEL org.opencontainers.image.description="SABnzbd with static unrar and par2"

# tiny busybox shell for user scripts
COPY --from=busybox:1.37.0-musl /bin/busybox /bin/sh

# runtime artefacts
COPY --from=build /venv                /venv
COPY --from=build /app/sabnzbd         /app/sabnzbd
COPY --from=build /usr/local/bin/unrar /usr/bin/unrar
COPY --from=build /usr/local/bin/par2  /usr/bin/par2
COPY --from=build /usr/bin/7z          /usr/bin/7z
COPY --from=build /deps/              /
COPY --from=build /defaults           /defaults
COPY entrypoint.py                    /entrypoint.py

USER 2501:2501
ENV PATH="/venv/bin:$PATH" PYTHONPATH="/app"
VOLUME ["/config", "/downloads/incomplete", "/app/data"]
EXPOSE 8080
ENTRYPOINT ["python", "/entrypoint.py"]
