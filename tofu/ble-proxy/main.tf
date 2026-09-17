locals {
  host_nodes = toset([for n in var.nodes : n.host_node])
}

resource "proxmox_virtual_environment_download_file" "debian_amd64" {
  for_each       = local.host_nodes
  node_name      = each.value
  content_type   = "iso"
  datastore_id   = var.proxmox_datastore
  file_name      = "debian-13-generic-amd64.img"
  url            = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
  upload_timeout = 800
}

resource "proxmox_virtual_environment_file" "cloudinit" {
  for_each     = var.nodes
  content_type = "snippets"
  node_name    = each.value.host_node
  datastore_id = coalesce(each.value.datastore_id, "local")
  source_raw {
    data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
      matter_server_ble_url = var.matter_server_ble_url
    })
    file_name = "ble-proxy-${each.key}-cloudinit.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  for_each = var.nodes

  node_name   = each.value.host_node
  name        = each.key
  description = "Matter BLE proxy client (bridges USB BLE dongle to matter-server /ble)"
  tags        = ["automation", "ble-proxy"]
  vm_id       = each.value.vm_id
  on_boot     = true

  agent { enabled = true }

  cpu {
    cores = coalesce(each.value.cpu, 1)
    type  = "host"
  }
  memory { dedicated = coalesce(each.value.ram_dedicated, 512) }

  network_device {
    bridge      = var.network.bridge
    vlan_id     = var.network.vlan_id
    mac_address = each.value.mac_address
  }

  usb {
    host = each.value.usb_host
  }

  disk {
    datastore_id = coalesce(each.value.datastore_id, var.proxmox_datastore)
    interface    = "scsi0"
    ssd          = true
    size         = 4
    file_format  = "qcow2"
    file_id      = proxmox_virtual_environment_download_file.debian_amd64[each.value.host_node].id
  }

  operating_system { type = "l26" }

  initialization {
    datastore_id      = coalesce(each.value.datastore_id, var.proxmox_datastore)
    user_data_file_id = proxmox_virtual_environment_file.cloudinit[each.key].id
    dns {
      domain  = var.cluster_domain
      servers = var.network.dns_servers
    }
    ip_config {
      ipv4 {
        address = "${each.value.ip}/${var.network.cidr_prefix}"
        gateway = var.network.gateway
      }
    }
  }

  boot_order = ["scsi0"]

  lifecycle {
    ignore_changes = [network_device[0].disconnected]
  }
}
