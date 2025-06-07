---
title: Homelab Kubernetes Configuration Guide
---

# Overview

This guide explains our homelab Kubernetes setup, designed to help IT admins understand, run, and maintain the system.

## Searching the docs

The site now includes local search powered by a lightweight plugin. Use the search bar at the top of any page to quickly find topics without relying on an external service.

# Core Design Principles

1. **GitOps as Source of Truth**

   - All cluster states live in this Git repo
   - ArgoCD syncs cluster state with Git definitions
   - Changes require Git commits for audit tracking

2. **Declarative Configuration**

   - Uses Kubernetes YAML, Kustomize, and Terraform
   - Tools manage state based on defined specs

3. **Automated Operations**

   - ArgoCD ApplicationSets handle deployments
   - Cert-Manager runs certificate lifecycle
   - CI/CD pipelines automate testing and deployment

4. **Security First**

   - Non-root container execution
   - Network policies control traffic
   - External secrets management
   - Regular security scans

5. **Clean Organization**
   - Kustomize manages configurations
   - ArgoCD projects group related apps
   - ApplicationSets simplify scaling

# Documentation Map

## Cluster Setup

- [Provision Talos Kubernetes](./tofu/opentofu-provisioning.md)
  - OpenTofu-based Talos deployment on Proxmox
  - Infrastructure setup steps

## Kubernetes Management

- [GitOps Configuration](./k8s/manage-kubernetes.md)
  - ArgoCD setup and usage
  - Manifest structure
  - Service management

## Application Guides

- [Deploy Apps](./k8s/applications/application-management.md)
  - User application deployment
  - App lifecycle management

## Infrastructure

- [Core Services](./k8s/infrastructure/infrastructure-management.md)
  - Network setup
  - Storage configuration
  - Auth systems
  - Monitoring stack

## CI/CD

- [Pipeline Configuration](./github/github-configuration.md)
  - CI/CD workflow setup
  - Dependabot settings
  - Repo maintenance

## Website Updates

The site used to include a small blog for notes and experiments. To keep the focus on documentation, the blog has been
removed. You'll now find all relevant updates here in the docs.
