# syntax=docker/dockerfile:1
FROM python:3.13-slim AS build
ARG SAB_VERSION=4.5.2
ARG SAB_SRC_URL="https://github.com/sabnzbd/sabnzbd/releases/download/${SAB_VERSION}/SABnzbd-${SAB_VERSION}-src.tar.gz"
ENV VENV=/venv
RUN apt-get update && apt-get install --no-install-recommends -y curl ca-certificates unzip p7zip-full par2 unrar && rm -rf /var/lib/apt/lists/*
RUN python -m venv $VENV && \
    curl -sSL "$SAB_SRC_URL" -o /tmp/sabnzbd.tar.gz && \
    tar -xzf /tmp/sabnzbd.tar.gz -C /tmp && \
    pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir /tmp/SABnzbd-${SAB_VERSION}
RUN adduser --uid 2501 --disabled-login --gecos '' sabnzbd
RUN mkdir -p /defaults && \
    $VENV/bin/python -m sabnzbd --config-file /defaults/sabnzbd.ini --server 127.0.0.1:9 || true && \
    chown -R 2501:2501 /defaults
RUN install -d -o 2501 -g 2501 /config /downloads/incomplete /app/data
RUN mkdir /deps && \
    for bin in /usr/bin/unrar /usr/bin/par2 /usr/bin/7z; do \
      ldd $bin | awk '{print $3}' | grep -Ev '^$|^\(.*\)$' | xargs -r -I '{}' cp --parents '{}' /deps; \
    done
FROM gcr.io/distroless/python3-debian12:nonroot
COPY --from=build /venv /venv
COPY --from=build /usr/bin/unrar /usr/bin/par2 /usr/bin/7z /usr/bin/
COPY --from=build /deps/ /
COPY --from=build /defaults /defaults
COPY --from=build /config /config
COPY --from=build /downloads/incomplete /downloads/incomplete
COPY --from=build /app/data /app/data
COPY entrypoint.py /entrypoint.py
USER 2501:2501
ENV PATH="/venv/bin:$PATH"
VOLUME ["/config","/downloads/incomplete","/app/data"]
EXPOSE 8080
ENTRYPOINT ["python","/entrypoint.py"]
