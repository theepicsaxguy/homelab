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

After you have the necessary IDs and IOMMU groups, you can configure your OpenTofu code.

### 1. Extend `nodes_config` and `nodes` in `variables.tf`

The `nodes_config` variable in `tofu/variables.tf` and the `nodes` variable in `tofu/talos/variables.tf` have been extended to include `gpu_devices` (a list of BDF strings) and `gpu_device_meta` (a map keyed by BDF strings, containing `id`, `subsystem_id`, and `iommu_group`). This ensures that GPU metadata is part of the node's definition.

```terraform
variable "nodes_config" {
  type = map(object({
    # ... existing attrs
    gpu_devices      = optional(list(string), [])
    gpu_device_meta  = optional(
      map(object({
        id            = string
        subsystem_id  = string
        iommu_group   = number
      })),
      {}
    )
  }))
  # ... existing validations
  validation {
    condition = alltrue(flatten([
      for _, n in var.nodes_config :
      [
        for bdf in lookup(n, "gpu_devices", []) :
        contains(keys(lookup(n, "gpu_device_meta", {})), bdf)
      ]
    ]))
    error_message = "Every BDF in gpu_devices must exist in gpu_device_meta."
  }
}

variable "nodes" {
  type = map(object({
    # ... existing attributes
    gpu_devices     = optional(list(string), [])
    gpu_device_meta = optional(
      map(object({
        id            = string
        subsystem_id  = string
        iommu_group   = number
      })),
      {}
    )
  }))
  # ...
}
```

### 2. Add Metadata to `nodes.auto.tfvars`

For each node that has GPU devices, you will now add the `gpu_devices` list and the `gpu_device_meta` map directly to its configuration in `tofu/nodes.auto.tfvars`.

```terraform
"work-03" = {
  machine_type = "worker"
  # ...
  igpu         = true
  gpu_devices  = ["0000:03:00.0", "0000:03:00.1"]
  gpu_device_meta = {
    "0000:03:00.0" = {
      id            = "10de:13ba"
      subsystem_id  = "10de:1097"
      iommu_group   = 50
    }
    "0000:03:00.1" = {
      id            = "10de:0fbc"
      subsystem_id  = "10de:1097"
      iommu_group   = 50
    }
  }
}
```

### 3. Update `gpu_mappings` in `virtual-machines.tf`

The `gpu_mappings` local in `tofu/talos/virtual-machines.tf` now directly accesses the `gpu_device_meta` from the node configuration. The hard-coded `gpu_device_meta` local has been removed.

```terraform
locals {
  gpu_mapping_alias_prefix = "gpu"
  gpu_mappings = flatten([
    for node_name, node_cfg in var.nodes : [
      for idx, bdf in node_cfg.gpu_devices : {
        name         = "${local.gpu_mapping_alias_prefix}-${node_name}-${idx}"
        node         = node_cfg.host_node
        path         = bdf
        meta         = lookup(node_cfg, "gpu_device_meta", {})[bdf]
      }
    ]
  ])
}
```

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

### 4. Reference the Alias in the VM `hostpci` Block

Finally, modify the `dynamic "hostpci"` block within your `proxmox_virtual_environment_vm` resource to reference these aliases using the `mapping` attribute instead of the raw `id`.

```terraform
dynamic "hostpci" {
  for_each = each.value.igpu && length(each.value.gpu_devices) > 0 ? {
    for i, bdf in each.value.gpu_devices : i => bdf
  } : {}
  content {
    device  = "hostpci${hostpci.key}"
    mapping = "${local.gpu_mapping_alias_prefix}-${each.key}-${hostpci.key}"
    pcie    = true
    rombar  = true
  }
}
```

By following these steps, your OpenTofu configuration will correctly create the necessary PCI mapping aliases in Proxmox, allowing for GPU passthrough even when using API tokens for authentication.