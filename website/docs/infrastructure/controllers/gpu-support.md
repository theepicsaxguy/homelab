# GPU Support in Kubernetes

This document outlines how GPU support is enabled in the Kubernetes cluster, covering Node Feature Discovery and the NVIDIA GPU Operator.

## Node Feature Discovery (NFD)

Node Feature Discovery (NFD) is used to detect hardware features and system configurations on Kubernetes nodes. This allows for scheduling pods to nodes that have specific hardware capabilities, such as GPUs.

NFD is deployed as a Kustomize overlay under `k8s/infrastructure/controllers/node-feature-discovery/`. It includes:
*   A dedicated namespace.
*   A Helm chart for deploying NFD.
*   Values for configuring the NFD deployment.

## NVIDIA GPU Operator

The NVIDIA GPU Operator automates the management of all NVIDIA software components needed to provision GPU-enabled Kubernetes nodes. This includes the NVIDIA device plugin, which enables Kubernetes to recognize and schedule workloads to GPUs.

The NVIDIA GPU Operator components are deployed within the `nvidia-gpu-operator` namespace, which is configured with appropriate pod security labels.

Key components and configurations:
*   **NVIDIA Device Plugin**: Deployed via a Helm chart, it allows Kubernetes to expose NVIDIA GPUs as a schedulable resource.
*   **RuntimeClass `nvidia`**: A `RuntimeClass` named `nvidia` is created to enable pods to utilize the NVIDIA container runtime, which is necessary for GPU acceleration.
*   **Kustomization**: The `nvidia-gpu` components are included in the controllers `kustomization.yaml` under `k8s/infrastructure/controllers/nvidia-gpu/`.
*   **Containerd Runtime Configuration**: Worker nodes load the `nvidia-container-runtime` so GPU workloads can run without extra Pod tweaks.
*   **GPU Node Taint**: The GPU worker can be marked with a `gpu=true:NoSchedule` taint, reserving it for GPU-aware pods.

This setup ensures that GPU-enabled nodes are properly identified and that applications requiring GPU resources can be scheduled and executed efficiently within the Kubernetes cluster.
