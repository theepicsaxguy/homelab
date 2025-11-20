---
title: 'vLLM CPU Embedding Server'
---

We run an OpenAI-compatible embedding server to power our RAG (Retrieval-Augmented Generation) pipelines. This service sits behind **LiteLLM**, which routes traffic between our local models and external providers.

While we use GPUs for generation (LLMs), we run embeddings on **CPU**. Why? Because the `Qwen/Qwen3-Embedding-0.6B` model is small enough that wasting a GPU on it feels like overkill, and we have plenty of spare CPU cycles in our cluster.

However, making a modern AI engine (vLLM) run efficiently on a constrained CPU budget (4 cores, 4GB RAM) was a fight. This document details exactly how we configured it and the specific walls we hit along the way.

## The Architecture

*   **Engine:** vLLM (Custom CPU build based on OpenVINO/IPEX).
*   **Model:** `Qwen/Qwen3-Embedding-0.6B` (Standard `bfloat16` weights).
*   **Routing:** LiteLLM proxies requests to this service.
*   **Infrastructure:** Kubernetes Deployment.
*   **Resource Limits:** 4 CPU Cores, 4GB RAM.

## The Optimization Log (A Post-Mortem)

We expected this to be "plug and play." It wasn't. We encountered four distinct issues that took the service from "unusable" to "production-ready." Here is the raw breakdown of what broke and why.

### 1. The "Death Spiral" (195s Latency)
**The Symptom:**
Our first deployment successfully loaded the model, but a simple request for 5,000 tokens took **195 seconds** to process. That is roughly 25 tokens per second. You can read faster than that.

**The Root Cause:**
We were victims of a hardware mismatch.
*   **Kubernetes** limited the pod to 4 Cores.
*   **The Physical Host** had 64+ Cores.

By default, PyTorch and vLLM queried the *physical hardware*, saw 64 cores, and spawned 64 worker threads. The Kubernetes scheduler (CFS) saw 64 heavy threads fighting for a tiny 4-core quota and aggressively throttled them. The CPU spent 99% of its time context-switching between threads and only 1% doing actual math.

**The Fix:**
We had to force the application to ignore the reality of the hardware. We hardcoded the `OMP_NUM_THREADS` and `MKL_NUM_THREADS` environment variables to **4**. This aligned the thread count with our CPU limit, stopping the thrashing immediately. Speed jumped from 25 tokens/s to ~300 tokens/s.

### 2. The Memory Crash (OOM)
**The Symptom:**
Once the speed was fixed, the pod became unstable. It would crash with `Exit Code 137` (Out of Memory) almost immediately upon receiving a request.

**The Root Cause:**
We got greedy. We initially tried to force `float32` precision, assuming `bfloat16` would be too slow on CPUs without native AVX-512 support.
We were wrong. Forcing `float32` doubled the model size.
*   Model Weights: 2.4GB
*   Mandatory KV Cache: 1GB
*   Python Overhead: ~800MB
*   **Total:** > 4.2GB (Crash).

**The Fix:**
We swallowed our pride and reverted to `bfloat16`. It turns out the speed penalty is negligible, but it reduced the model weights to ~1.2GB. We also tuned `MALLOC_ARENA_MAX=1`, which forces the C memory allocator to be aggressive about releasing unused RAM, saving us an extra ~300MB of headroom.

### 3. The "Context Length" Rejection
**The Symptom:**
To save RAM, we capped the model's maximum context window (the amount of text it can "see" at once) to **1,024 tokens**. However, we often need to embed documents that are 8,000+ tokens long. vLLM rejected these requests with a `ValueError`.

**The Root Cause:**
Standard inference requires the entire document to be loaded into RAM at once. We simply didn't have the RAM to process 8,000 tokens in a single pass.

**The Fix:**
We enabled vLLM's **Chunked Processing**.
This is a configuration that tells the engine: *"If a document is too big, chop it into 1,024-token slices, process them one by one, and mathematically average the results."* This allows us to process infinite-length documents without increasing our memory footprint.

### 4. The "Auto" Config Bug
**The Symptom:**
After enabling chunking, the pod crashed again with a cryptic `KeyError: 'auto'`.

**The Root Cause:**
The vLLM documentation claims you can set `pooling_type="auto"` and the engine will detect the model architecture. On the specific CPU version of vLLM we are using, **this is broken**. The auto-detection logic failed to map the Qwen architecture to a valid pooling class.

**The Fix:**
We manually overrode the pooler configuration. Since Qwen is a Causal LM (like GPT), embeddings are derived from the **LAST** token in the sequence. We hardcoded `pooling_type="LAST"`, bypassing the broken auto-detection logic.

## Final Status

The service is now stable.
*   It respects the **4GB RAM** hard limit.
*   It handles documents of **arbitrary length** via chunking.
*   It processes roughly **300 tokens/second** (12x faster than our first attempt).