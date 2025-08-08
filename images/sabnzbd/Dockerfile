# syntax=docker/dockerfile:1
FROM python:3.12-slim AS build
ARG SAB_VERSION=4.5.2
ARG IMAGE_VERSION=4.5.2
ENV VENV=/venv
RUN python -m venv $VENV && \
    $VENV/bin/pip install --no-cache-dir --upgrade pip "sabnzbd==$SAB_VERSION"
RUN adduser --uid 2501 --disabled-login --gecos '' sabnzbd
FROM gcr.io/distroless/python3-debian12:nonroot
COPY --from=build /venv /venv
USER 2501:2501
ENV PATH="/venv/bin:$PATH"
EXPOSE 8080
VOLUME ["/config","/downloads/incomplete","/app/data"]
ENTRYPOINT ["python","-m","sabnzbd","--config-file","/config/sabnzbd.ini"]
