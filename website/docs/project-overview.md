---
sidebar_position: 1
title: Project Overview
description: Why this homelab exists and where to find the docs
---

A GitOps Kubernetes lab built to keep tinkering fun—not time‑consuming.

## About this homelab

This project combines Talos Linux, ArgoCD, and a few open source services to run a self‑healing cluster with minimal manual work. It began as a way to stop chasing broken VMs and spend more time with family.

## Why this homelab?

I was fed up with fixing and maintaining countless VMs. With a baby on the way, I needed a foolproof setup that wouldn't steal my sleep. This project aims to be that solution:

- **Automation Overhead?** Gone.
- **Manual Fixes at 3 AM?** Not happening.
- **Downtime?** Reduced to a minimum.

It's designed to be robust and self‑recovering so I can focus on family instead of battling infrastructure meltdowns.

## Documentation map

Use the links below to dive deeper into specific topics:

- [Quick Start](./quick-start.md) – launch a cluster in minutes.
- [Getting Started](./getting-started.md) – full installation walkthrough.
- [System architecture](./architecture.md) – overview of components and networking.
- [Infrastructure overview](./infrastructure/overview.md) – core controllers and services.
- [Application guides](./applications/media-stack.md) – examples of self‑hosted apps.
- [Disaster recovery](./disaster/disaster-recovery.md) – restore the cluster after a failure.
- [CI/CD setup](./github/github-configuration.md) – how automation ties everything together.

## Credits

Special thanks to the inspiration and work behind [Vehagn's Homelab](https://github.com/vehagn/homelab).
