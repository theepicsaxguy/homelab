---
title: NVIDIA Driver Management
---

This document explains the process of managing NVIDIA drivers within the Talos Kubernetes environment, focusing on ensuring compatibility between the Talos kernel and NVIDIA kernel modules.

:::info Talos Linux, being an immutable operating system, requires specific handling for third-party kernel modules like NVIDIA drivers. The key challenge lies in matching the NVIDIA kernel module version with the running Talos kernel version. Mismatched versions can lead to driver loading failures and system instability. :::

## Overview of NVIDIA Driver Management in Talos

- **Kernel Version Dependency:** NVIDIA kernel modules (`nvidia.ko`, `nvidia_uvm`, `nvidia_drm`, `nvidia_modeset`) are tightly coupled with the Linux kernel version they were compiled against.
- **Talos Kernel Channels:** Talos offers "production" and "LTS" kernel channels. It is crucial to use NVIDIA extensions built for the *currently running* Talos kernel version (e.g., Linux 6.8 for Talos 1.10.3 production kernel).
- **Extension Tags:** NVIDIA extensions are distributed with specific tags (e.g., `siderolabs/nonfree-kmod-nvidia-production:535.247.01-v1.10.3`) that indicate compatibility with a particular Talos version and kernel channel.

## Common Use Cases

- **Initial Setup:** Installing NVIDIA drivers on a new Talos node with a GPU.
- **Driver Upgrades:** Updating NVIDIA drivers to a newer version.
- **Talos Upgrades:** Ensuring driver compatibility after a Talos Linux upgrade, which might involve a kernel version bump.

## Important Considerations

- **Matching Versions:** Always verify that the NVIDIA kernel modules and container toolkit extensions match the Talos Linux version and its corresponding kernel.
- **GSP Firmware:** For older NVIDIA GPUs (e.g., Maxwell GM107 like the Quadro K2200), disabling GSP (GPU System Processor) firmware is often unnecessary and can clutter configurations.
- **GitOps Principle:** All changes to NVIDIA driver configurations should be managed through Git, specifically by updating the Talos schematic. Direct modifications to the Talos nodes are not recommended and will be overwritten.
- **Validation:** After modifying the Talos schematic, always run `tofu fmt` and `tofu validate` to ensure the configuration is syntactically correct and valid.

## Procedure for Updating NVIDIA Extensions

1.  **Identify Correct Extensions:**
    Determine the appropriate NVIDIA kernel module and container toolkit extension tags that match your Talos Linux version and kernel. For example, for Talos 1.10.3 with the production kernel:
    - `siderolabs/nonfree-kmod-nvidia-production:535.247.01-v1.10.3`
    - `siderolabs/nvidia-container-toolkit-production:570.133.20-v1.17.6`

2.  **Update `schematic.yaml.tftpl`:**
    Modify the `tofu/talos/image/schematic.yaml.tftpl` file to include the correct extension tags:

    ```yaml
    customization:
      systemExtensions:
        officialExtensions:
          - siderolabs/qemu-guest-agent
          - siderolabs/iscsi-tools
          - siderolabs/util-linux-tools
    %{ if needs_nvidia_extensions }
          - siderolabs/nonfree-kmod-nvidia-production:535.247.01-v1.10.3
          - siderolabs/nvidia-container-toolkit-production:570.133.20-v1.17.6
    %{ endif }
    ```

3.  **Remove Redundant GSP Patches (if applicable):**
    If you have existing YAML overlays that disable GSP firmware (e.g., by creating `/etc/modprobe.d/20-nvidia-disable-gsp.conf` or adding `kernel.options = nvidia.NVreg_EnableGpuFirmware=0`), remove them. These are generally not required for Maxwell (GM107) GPUs and can clutter the configuration.

4.  **Re-build Talos Image:**
    Run the OpenTofu apply process (or your CI pipeline) to regenerate the Talos image with the updated schematic.

5.  **Roll Out and Verify:**
    Reboot the Talos nodes with the new image. Verify the driver loading and functionality using `talosctl dmesg | grep -i "nvidia.*GPU"` and `talosctl containers | grep nvidia`.
