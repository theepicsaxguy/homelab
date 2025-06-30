---
sidebar_position: 3
title: GPU Passthrough
---

# GPU Passthrough Configuration

This guide explains how GPUs are exposed to Talos nodes.

## Finding GPU BDFs

On each Proxmox host, run `lspci` to locate the Bus:Device.Function (BDF) for your GPU.

## OpenTofu Configuration

Add the BDFs to `gpu_devices` in `tofu/nodes.auto.tfvars`:

```terraform
"work-03" = {
  machine_type = "worker"
  igpu         = true
  gpu_devices  = ["0000:03:00.0", "0000:03:00.1"]
}
```

The `gpu_devices` list is available in both `tofu/variables.tf` and `tofu/talos/variables.tf`.

## Virtual Machine Definition

`tofu/talos/virtual-machines.tf` attaches the devices directly:

```terraform
dynamic "hostpci" {
  for_each = each.value.igpu ? toset(each.value.gpu_devices) : []
  content {
    device = hostpci.value
    pcie   = true
  }
}
```

Talos loads the NVIDIA drivers through system extensions, and Node Feature Discovery labels the node so the device plugin runs only on GPU nodes.
