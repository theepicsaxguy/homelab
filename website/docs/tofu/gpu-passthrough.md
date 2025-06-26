---
sidebar_position: 3
title: GPU Passthrough
---

# GPU Passthrough Configuration

This document outlines the process for configuring GPU passthrough in your Proxmox-based Kubernetes cluster using OpenTofu, specifically addressing the requirements for API token authentication with Proxmox.

## The Proxmox API Token Limitation

Proxmox does not allow API identities that contain a token (e.g., `root@pam!...`) to directly attach raw PCI BDF (Bus:Device.Function) addresses (e.g., `0000:BB:DD.f`) to virtual machines. This is a security guard-rail. Instead, you must reference a pre-declared alias, known as a "PCI mapping."

The `proxmox_virtual_environment_hardware_mapping_pci` resource in the Proxmox Terraform provider is used to manage these aliases.

## Finding Your GPU Device Information

To create the necessary PCI mappings, you need three pieces of information for each GPU device you intend to pass through:

1.  **PCI Vendor:Device ID**: This uniquely identifies the type of PCI device.
2.  **Subsystem Vendor:Device ID**: This identifies the specific board partner or manufacturer of the device.
3.  **IOMMU Group**: This is the IOMMU group the device belongs to, which is required by Proxmox for passthrough.

### 1. Finding PCI Vendor:Device IDs and Subsystem IDs

On your Proxmox host, use the `lspci` command with the `-nnv` and `-s` flags to get the numeric IDs and subsystem information. Replace `03:00.0` with your device's BDF:

```bash
lspci -nnv -s 03:00.0 | grep -i subsystem
```

**Example Output:**

```
03:00.0 VGA compatible controller [0300]: NVIDIA Corporation GM107GL [Quadro K2200] [10de:13ba] (rev a2)
        Subsystem: NVIDIA Corporation GM107GL [Quadro K2200] [10de:1097]
```

From this output, you can extract the `Vendor:Device` ID (`10de:13ba`) and the `Subsystem Vendor:Device` ID (`10de:1097`). Repeat for all your GPU devices.

### 2. Finding IOMMU Groups

On your Proxmox host, use `readlink -f` to find the IOMMU group for each PCI device:

```bash
readlink -f /sys/bus/pci/devices/0000:03:00.0/iommu_group
```

**Example Output:**

```
/sys/kernel/iommu_groups/50
```

In this example, the IOMMU group for the device is `50`.

## OpenTofu Configuration

Once you have the necessary IDs and IOMMU groups, you can configure your OpenTofu code.

### 1. Define `gpu_device_meta` and `gpu_mappings` in `locals`

Add a `locals` block (or extend an existing one) in your `tofu/talos/virtual-machines.tf` (or a suitable `locals.tf` file) to define the GPU metadata and mappings. This block will dynamically generate the necessary data for the PCI mapping resources.

```terraform
locals {
  gpu_device_meta = {
    "0000:03:00.0" = {
      id            = "10de:13ba",     # Replace with your GPU's Vendor:Device ID
      subsystem_id  = "10de:1097",     # Replace with your GPU's Subsystem Vendor:Device ID
      iommu_group   = 50               # Replace with your IOMMU group
    }
    "0000:03:00.1" = {
      id            = "10de:0fbc",     # Replace with your GPU's Audio Vendor:Device ID
      subsystem_id  = "10de:1097",     # Replace with your GPU's Audio Subsystem Vendor:Device ID
      iommu_group   = 50               # Replace with your IOMMU group
    }
  }

  gpu_mappings = flatten([
    for node_name, node_cfg in var.nodes : [
      for idx, bdf in node_cfg.gpu_devices : {
        name = "gpu-${node_name}-${idx}"    # Unique name for the mapping
        node = node_cfg.host_node           # The Proxmox node where the device is located
        path = bdf                          # The BDF of the PCI device (e.g., "0000:03:00.0")
        meta = local.gpu_device_meta[bdf]
      }
    ]
  ])
}
```

### 2. Create `proxmox_virtual_environment_hardware_mapping_pci` Resources

Use the `gpu_mappings` local to create `proxmox_virtual_environment_hardware_mapping_pci` resources. These resources will create the PCI aliases in Proxmox.

```terraform
resource "proxmox_virtual_environment_hardware_mapping_pci" "gpu" {
  for_each = { for m in local.gpu_mappings : m.name => m }

  name = each.value.name
  map  = [{
    node          = each.value.node
    path          = each.value.path
    id            = each.value.meta.id
    subsystem_id  = each.value.meta.subsystem_id
    iommu_group   = each.value.meta.iommu_group
  }]
}
```

### 3. Reference the Alias in the VM `hostpci` Block

Finally, modify the `dynamic "hostpci"` block within your `proxmox_virtual_environment_vm` resource to reference these aliases using the `mapping` attribute instead of the raw `id`.

```terraform
dynamic "hostpci" {
  for_each = zipmap(range(length(each.value.gpu_devices)), each.value.gpu_devices)
  content {
    device  = "hostpci${hostpci.key}"
    mapping = "gpu-${each.key}-${hostpci.key}" # Matches the 'name' in gpu_mappings
    pcie    = true
    rombar  = true
  }
}
```

By following these steps, your OpenTofu configuration will correctly create the necessary PCI mapping aliases in Proxmox, allowing for GPU passthrough even when using API tokens for authentication.