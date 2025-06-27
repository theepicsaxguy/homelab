resource "terraform_data" "image_version" {
  input = var.talos_image.version
}

resource "proxmox_virtual_environment_vm" "this" {
  for_each = var.nodes


  node_name = each.value.host_node

  name        = each.key
  description = lookup(each.value, "description", each.value.machine_type == "controlplane" ? "Talos Control Plane" : "Talos Worker")
  tags        = lookup(each.value, "tags", each.value.machine_type == "controlplane" ? ["k8s", "control-plane"] : ["k8s", "worker"])
  on_boot     = lookup(each.value, "on_boot", true)
  vm_id       = each.value.vm_id

  machine       = lookup(each.value, "machine", "q35")
  scsi_hardware = lookup(each.value, "scsi_hardware", "virtio-scsi-single")
  bios          = lookup(each.value, "bios", "seabios")

  agent {
    enabled = lookup(each.value, "agent_enabled", true)
  }

  cpu {
    cores = each.value.cpu
    type  = lookup(each.value, "cpu_type", "host")
  }

  memory {
    dedicated = each.value.ram_dedicated # minimum (guaranteed)
  }



  network_device {
    bridge      = lookup(each.value, "network_bridge", "vmbr0")
    vlan_id     = lookup(each.value, "network_vlan_id", 150)
    mac_address = each.value.mac_address
  }

  disk {
    datastore_id = each.value.datastore_id
    interface    = lookup(each.value, "root_disk_interface", "scsi0")
    iothread     = lookup(each.value, "root_disk_iothread", true)
    cache        = lookup(each.value, "root_disk_cache", "writethrough")
    discard      = lookup(each.value, "root_disk_discard", "on")
    ssd          = lookup(each.value, "root_disk_ssd", true)
    file_format  = lookup(each.value, "root_disk_file_format", "raw")
    size         = lookup(each.value, "root_disk_size", 40)
    file_id = proxmox_virtual_environment_download_file.iso[
      "${each.value.host_node}-${lookup(each.value,"update",false) ? "upd" : "inst"}-${lookup(each.value,"igpu",false) ? "gpu" : "std"}"
    ].id
  }

  # Create additional disks defined in the node configuration
  dynamic "disk" {
    for_each = each.value.disks
    content {
      datastore_id = each.value.datastore_id
      interface    = "${disk.value.type}${disk.value.unit_number}"
      iothread     = lookup(each.value, "additional_disk_iothread", true)
      cache        = lookup(each.value, "additional_disk_cache", "writethrough")
      discard      = lookup(each.value, "additional_disk_discard", "on")
      ssd          = lookup(each.value, "additional_disk_ssd", true)
      file_format  = lookup(each.value, "additional_disk_file_format", "raw")
      size         = tonumber(replace(disk.value.size, "G", ""))
    }
  }
  lifecycle {
    ignore_changes = [
      vga,
      network_device[0].disconnected,
      disk[0].file_id,
    ]

    replace_triggered_by = [
      terraform_data.image_version
    ]
  }
  boot_order = lookup(each.value, "boot_order", ["scsi0"])

  operating_system {
    type = lookup(each.value, "os_type", "l26")
  }

  initialization {
    datastore_id = each.value.datastore_id
    dns {
      domain  = var.cluster_domain
      servers = lookup(each.value, "dns_servers", ["10.25.150.1"])
    }
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.cluster.gateway
      }
    }
  }

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
}

locals {
  gpu_mapping_alias_prefix = "gpu"
  gpu_mappings = flatten([
    for node_name, node_cfg in var.nodes : [
      for idx, bdf in node_cfg.gpu_devices : {
        name = "${local.gpu_mapping_alias_prefix}-${node_name}-${idx}"
        node = node_cfg.host_node
        path = bdf
        meta = lookup(node_cfg, "gpu_device_meta", {})[bdf]
      }
    ]
  ])
}

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
