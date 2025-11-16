FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /workspace

RUN apt-get update && apt-get install -y git curl ca-certificates

ARG VLLM_VERSION=v0.11.0
RUN git clone --depth 1 --branch ${VLLM_VERSION} https://github.com/vllm-project/vllm.git

WORKDIR /workspace/vllm

# Build upstream CPU image using their existing dockerfile
# This produces the exact same result as upstream, with your env layered on top

ARG VLLM_CPU_DISABLE_AVX512=true
ARG VLLM_CPU_AVX512BF16=false
ARG VLLM_CPU_AVX512VNNI=false
ARG VLLM_CPU_AMXBF16=false

ENV VLLM_CPU_DISABLE_AVX512=${VLLM_CPU_DISABLE_AVX512}
ENV VLLM_CPU_AVX512BF16=${VLLM_CPU_AVX512BF16}
ENV VLLM_CPU_AVX512VNNI=${VLLM_CPU_AVX512VNNI}
ENV VLLM_CPU_AMXBF16=${VLLM_CPU_AMXBF16}

# Delegate everything to upstream CPU dockerfile
RUN docker buildx build \
    -f docker/Dockerfile.cpu \
    --target vllm-openai \
    --build-arg VLLM_CPU_DISABLE_AVX512=${VLLM_CPU_DISABLE_AVX512} \
    --build-arg VLLM_CPU_AVX512BF16=${VLLM_CPU_AVX512BF16} \
    --build-arg VLLM_CPU_AVX512VNNI=${VLLM_CPU_AVX512VNNI} \
    --build-arg VLLM_CPU_AMXBF16=${VLLM_CPU_AMXBF16} \
    -t vllm-cpu-from-upstream \
    --load \
    .
