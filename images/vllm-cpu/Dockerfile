# Stage 1: build vLLM from source with CPU support
FROM ubuntu:24.04@sha256:c35e29c9450151419d9448b0fd75374fec4fff364a27f176fb458d472dfc9e54 AS build

ENV DEBIAN_FRONTEND=noninteractive

# Install build tools and dependencies pinned to Ubuntu 24.04 versions
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates=20240203 \
    curl=8.5.0-2ubuntu10.6 \
    gnupg2=2.4.4-2ubuntu17.3 \
    python3.12=3.12.3-1ubuntu0.8 \
    python3.12-venv=3.12.3-1ubuntu0.8 \
    python3.12-dev=3.12.3-1ubuntu0.8 \
    gcc-13=13.3.0-6ubuntu2~24.04 \
    g++-13=13.3.0-6ubuntu2~24.04 \
    git=1:2.43.0-1ubuntu7.3 \
    wget=1.21.4-1ubuntu4.1 \
    cmake=3.28.3-1build7 \
    ninja-build=1.11.1-2 \
    libnuma-dev=2.0.18-1build1 \
    libtcmalloc-minimal4t64=2.15-3build1 \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtualenv
RUN python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

# Set C and C++ compilers for CMake
ENV CC=gcc-13
ENV CXX=g++-13

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
FROM ubuntu:24.04@sha256:c35e29c9450151419d9448b0fd75374fec4fff364a27f176fb458d472dfc9e54

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates=20240203 \
    curl=8.5.0-2ubuntu10.6 \
    gnupg2=2.4.4-2ubuntu17.3 \
    python3.12=3.12.3-1ubuntu0.8 \
    python3.12-venv=3.12.3-1ubuntu0.8 \
    libnuma1=2.0.18-1build1 \
    libtcmalloc-minimal4t64=2.15-3build1 \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy venv from build image
COPY --from=build /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

# Create unprivileged user for running the service
RUN useradd -m -s /sbin/nologin -c "vllm user" vllm \
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
