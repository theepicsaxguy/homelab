---
title: Talos Upgrade Process
---

## Overview

Upgrades now rely on `talosctl` directly. Each node is upgraded one by one while the cluster stays online.

## Steps

1. Update the desired versions in `main.tf` under `talos_image` and `cluster`.
2. Apply the configuration so the new versions are written to disk:
   ```bash
   tofu apply
   ```
3. Upgrade each node:
   ```bash
   talosctl upgrade --nodes <node-ip> --image ghcr.io/siderolabs/installer:<version>
   ```
   Wait for the node to become `Ready` before moving on.
4. After all nodes are upgraded, verify the control plane and workers are running the new versions:
   ```bash
   kubectl get nodes -o wide
   ```

If a node fails to upgrade, reboot it into the previous version and investigate before continuing.
