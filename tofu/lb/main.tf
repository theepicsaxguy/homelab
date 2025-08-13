locals {
  control_plane_ips = var.control_plane_ips
  auth_pass         = "k8sapi"
  haproxy_cfg = templatefile("${path.module}/templates/haproxy.cfg.tftpl", {
    control_plane_ips = local.control_plane_ips
    cluster_domain    = var.cluster_domain
  })
  lb_host_nodes = toset([for n in var.lb_nodes : n.host_node])
}

resource "proxmox_virtual_environment_download_file" "ubuntu_amd64" {
  for_each    = local.lb_host_nodes
  node_name   = each.value
  content_type = "iso"
  datastore_id = var.proxmox_datastore
  file_name    = "ubuntu-24.04-server-cloudimg-amd64.img"
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  upload_timeout = 800
}

resource "proxmox_virtual_environment_file" "cloudinit" {
  for_each     = var.lb_nodes
  content_type = "snippets"
  node_name    = each.value.host_node
  datastore_id = coalesce(each.value.datastore_id, "local")
  source_raw {
    data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
      haproxy_cfg = local.haproxy_cfg
      keepalived_cfg = templatefile("${path.module}/templates/keepalived.conf.tftpl", {
        state      = each.key == "lb-00" ? "MASTER" : "BACKUP"
        priority   = each.key == "lb-00" ? 200 : 150
        auth_pass  = local.auth_pass
        api_lb_vip = var.network.api_lb_vip
      })
    })
    file_name = "lb-${each.key}-cloudinit.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "lb" {
  for_each = var.lb_nodes

  node_name   = each.value.host_node
  name        = each.key
  description = "K8s API HA LB"
  tags        = ["k8s", "lb"]
  vm_id       = each.value.vm_id
  on_boot     = true

  agent { enabled = true }

  cpu {
    cores = coalesce(each.value.cpu, 2)
    type  = "host"
  }
  memory { dedicated = coalesce(each.value.ram_dedicated, 2048) }

  network_device {
    bridge      = var.network.bridge
    vlan_id     = var.network.vlan_id
    mac_address = each.value.mac_address
  }

  disk {
    datastore_id = coalesce(each.value.datastore_id, var.proxmox_datastore)
    interface    = "scsi0"
    ssd          = true
    size         = 8
    file_format  = "qcow2"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_amd64[each.value.host_node].id
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
