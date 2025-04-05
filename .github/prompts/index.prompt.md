# GitHub Copilot - Homelab Infrastructure Guidelines

## Purpose
This is the main instruction file for GitHub Copilot when working with this GitOps-only homelab infrastructure. All code generation and suggestions should adhere to these guidelines.

## Core Architecture

- **Kubernetes (Talos)**: Container orchestration platform
- **OpenTofu (Terraform)**: Infrastructure as Code
- **ArgoCD**: GitOps deployment mechanism
- **Cilium**: Networking with eBPF enabled
- **Monitoring Stack**: Prometheus, Loki, Falco

## Key Principles

- **GitOps-Only**: All changes must be defined in Git and applied automatically
- **Zero Manual Changes**: No `kubectl apply` or `helm install` commands allowed
- **ArgoCD as Single Source**: Only deployment mechanism
- **Full Documentation**: All components must be documented
- **Kustomize Overlays**: No raw manifests allowed
- **Security First**: Zero-trust approach with strict mTLS enforcement

## Repository Structure

- **k8s/**: Kubernetes manifests and ArgoCD configurations
- **tofu/**: OpenTofu/Terraform configurations
- **docs/**: Architecture and guidelines documentation
- **scripts/**: Helper scripts (validation only, no manual deployment)

## Usage Instructions

Import this prompt for general homelab context. For specific tasks, combine with specialized prompts:

- Use `#import:.github/prompts/kubernetes.prompt.md` for Kubernetes tasks
- Use `#import:.github/prompts/kustomize/base.prompt.md` for Kustomize tasks
- Use `#import:.github/prompts/gitops-optimization.prompt.md` for GitOps improvements

## References

- Repository structure: `#file:../../README.md`
- Kubernetes configuration: `#file:../../k8s/README.md`
- Infrastructure design: `#file:../../docs/architecture.md`
