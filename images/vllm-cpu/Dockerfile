# Stage 1: build vLLM from source with CPU support
FROM ubuntu:22.04@sha256:104ae83764a5119017b8e8d6218fa0832b09df65aae7d5a6de29a85d813da2fb AS build

# Install build tools and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates=20240203~22.04.1 \
    curl=7.81.0-1ubuntu1.21 \
    gnupg2=2.2.27-3ubuntu2.4 \
    && curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get\&search=0xF23C5A6CF475977595C89F51BA6932366A755776 | gpg --dearmor -o /etc/apt/trusted.gpg.d/deadsnakes.gpg \
    && echo "deb https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu/ jammy main" > /etc/apt/sources.list.d/deadsnakes.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    python3.12=3.12.12-1+jammy1 \
    python3.12-venv=3.12.12-1+jammy1 \
    python3.12-dev=3.12.12-1+jammy1 \
    gcc-12=12.3.0-1ubuntu1~22.04.2 \
    g++-12=12.3.0-1ubuntu1~22.04.2 \
    git=1:2.34.1-1ubuntu1.15 \
    wget=1.21.2-2ubuntu1.1 \
    cmake=3.22.1-1ubuntu1.22.04.2 \
    ninja-build=1.10.1-1 \
    libnuma-dev=2.0.14-3ubuntu2 \
    libtcmalloc-minimal4=2.9.1-0ubuntu3 \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtualenv
RUN python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

# Copy pinned build requirements
COPY requirements-build.txt /tmp/requirements-build.txt

# Install pinned build tools
RUN pip install --no-cache-dir -r /tmp/requirements-build.txt

# Clone vLLM at specific tag
RUN git clone --depth 1 --branch v0.10.0 https://github.com/vllm-project/vllm.git /workspace/vllm
WORKDIR /workspace/vllm

# Install vLLM dependencies from its own requirements
RUN pip install --no-cache-dir -r requirements/cpu-build.txt --extra-index-url https://download.pytorch.org/whl/cpu \
    && pip install --no-cache-dir -r requirements/cpu.txt --extra-index-url https://download.pytorch.org/whl/cpu

# Build and install vLLM with target device CPU
# pass build args to disable AVX512 if your CPU lacks it
ARG VLLM_CPU_DISABLE_AVX512=true
ARG VLLM_CPU_AVX512BF16=false
ARG VLLM_CPU_AVX512VNNI=false
ENV VLLM_CPU_DISABLE_AVX512=${VLLM_CPU_DISABLE_AVX512}
ENV VLLM_CPU_AVX512BF16=${VLLM_CPU_AVX512BF16}
ENV VLLM_CPU_AVX512VNNI=${VLLM_CPU_AVX512VNNI}

RUN VLLM_TARGET_DEVICE=cpu python setup.py bdist_wheel \
    && pip install dist/*.whl

# Stage 2: runtime image
FROM ubuntu:22.04@sha256:104ae83764a5119017b8e8d6218fa0832b09df65aae7d5a6de29a85d813da2fb

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates=20240203~22.04.1 \
    curl=7.81.0-1ubuntu1.21 \
    gnupg2=2.2.27-3ubuntu2.4 \
    && curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get\&search=0xF23C5A6CF475977595C89F51BA6932366A755776 | gpg --dearmor -o /etc/apt/trusted.gpg.d/deadsnakes.gpg \
    && echo "deb https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu/ jammy main" > /etc/apt/sources.list.d/deadsnakes.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    python3.12=3.12.12-1+jammy1 \
    python3.12-venv=3.12.12-1+jammy1 \
    libnuma1=2.0.14-3ubuntu2 \
    libtcmalloc-minimal4=2.9.1-0ubuntu3 \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy venv from build image
COPY --from=build /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

# Create unprivileged user for running the service
RUN useradd -m -u 65534 -s /sbin/nologin -c "vllm user" vllm \
    && mkdir -p /tmp /var/tmp \
    && chown vllm:vllm /tmp /var/tmp

# Environment variables to tune CPU backend (adjust VLLM_CPU_KVCACHE_SPACE for available RAM)
ENV VLLM_CPU_DISABLE_AVX512=true \
    VLLM_CPU_AVX512BF16=false \
    VLLM_CPU_AVX512VNNI=false \
    VLLM_CPU_NUM_OF_RESERVED_CPU=1 \
    VLLM_CPU_KVCACHE_SPACE=10
ENV LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4:$LD_PRELOAD"

# Make filesystem immutable (except tmpfs mounts)
RUN find / -type f -perm /u+w,g+w,o+w ! -path '/proc/*' ! -path '/sys/*' ! -path '/dev/*' ! -path '/tmp/*' ! -path '/var/tmp/*' ! -path '/run/*' 2>/dev/null -exec chmod a-w {} \; \
    && find / -type d -perm /u+w,g+w,o+w ! -path '/proc/*' ! -path '/sys/*' ! -path '/dev/*' ! -path '/tmp/*' ! -path '/var/tmp/*' ! -path '/run/*' 2>/dev/null -exec chmod a-w {} \;

# Switch to non-root user
USER vllm

# Expose port for OpenAI compatible API
EXPOSE 8000

# Command to serve embedding model
# Adjust model name if you choose different model than intfloat/e5-base-v2
ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
CMD ["--model", "intfloat/e5-base-v2", "--task", "embed", "--port", "8000", "--host", "0.0.0.0", "--device", "cpu"]
