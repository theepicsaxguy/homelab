# Build arguments:
#   IMAGE_VERSION=git-039f9c5 (default)
#
ARG IMAGE_VERSION=git-039f9c5

FROM ghcr.io/open-webui/pipelines:${IMAGE_VERSION}

# Switch to root to install dependencies
USER root

# Install required Python packages for pipelines
# - pydantic: for mem0 filter pipeline
# - ollama: for mem0 filter pipeline
# - mem0ai: for mem0 filter pipeline
# - wikipedia: for wikipedia pipeline
RUN pip install --no-cache-dir \
    pydantic==2.10.4 \
    ollama==0.4.4 \
    mem0ai==0.1.39 \
    wikipedia==1.4.0

# Switch back to non-root user
USER 1000

ENTRYPOINT ["bash", "start.sh"]
