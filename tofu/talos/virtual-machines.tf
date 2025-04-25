resource "proxmox_virtual_environment_vm" "this" {
  for_each  = var.nodes
  node_name = each.value.host_node
  name      = each.key
  tags      = []

  agent {
    enabled = true
  }
  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    iothread     = true
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    file_format  = "raw"
    size         = 20
    file_id      = "${var.storage_pool}:vm-${each.value.vm_id}-os"
  }

  dynamic "disk" {
    for_each = {
      for k, spec in var.worker_disk_specs :
      k => spec if spec.vm_id == each.value.vm_id
    }
    content {
      datastore_id = var.storage_pool
      file_id   = var.longhorn_disk_files[disk.value.node]
      interface = disk.value.interface
      iothread  = true
      cache     = "writethrough"
      discard   = "on"
      ssd       = true
    }
  }

  protection = false

  cpu {
    cores = each.value.cpu
  }
  memory {
    dedicated = each.value.ram_dedicated
  }
  network_device {
    mac_address = each.value.mac_address
  }
  scsi_hardware = "virtio-scsi-single"
}

###############################################################################
#  PERSISTENT LONGHORN DISKS — DETACH BEFORE DESTROY, ATTACH AFTER CREATE     #
###############################################################################

resource "null_resource" "longhorn_detach" {
  for_each = {
    for k, spec in var.worker_disk_specs :
    k => spec if spec.disk_key == "longhorn"
  }
  triggers = {
    host      = each.value.host
    vm_id     = each.value.vm_id
    interface = each.value.interface
  }
  provisioner "local-exec" {
    when    = destroy
    command = "pvesh set /nodes/${self.triggers.host}/qemu/${self.triggers.vm_id}/config --${self.triggers.interface}=none"
  }
}

resource "null_resource" "longhorn_attach" {
  for_each = {
    for k, spec in var.worker_disk_specs :
    k => spec if spec.disk_key == "longhorn"
  }
  triggers = {
    host      = each.value.host
    vm_id     = each.value.vm_id
    interface = each.value.interface
    pool      = each.value.pool
    disk_key  = each.value.disk_key
  }
  depends_on = [proxmox_virtual_environment_vm.this, null_resource.longhorn_detach]
  provisioner "local-exec" {
    when    = create
    command = "pvesh set /nodes/${self.triggers.host}/qemu/${self.triggers.vm_id}/config --${self.triggers.interface} ${self.triggers.pool}:vm-${self.triggers.vm_id}-disk-${self.triggers.disk_key}"
  }
}
