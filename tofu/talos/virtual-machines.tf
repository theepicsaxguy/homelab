variable "longhorn_disk_files" {
  description = "A map of Longhorn disk files to attach to each VM."
  type        = map(string)
  default     = {}
}

resource "proxmox_virtual_environment_vm" "this" {
  # ... Keep original attributes like for_each, node_name, name, tags ...
  for_each = var.nodes
  node_name = each.value.host_node
  name      = each.key
  tags      = lookup(local.default_tags, each.value.machine_type, [])


  # ... Keep original agent block if present ...
  agent {
    enabled = true
  }

  # Original OS disk block - KEEP THIS
  disk {
     datastore_id = each.value.datastore_id        # ← keep exactly as before
     interface    = "scsi0"
     iothread     = true
     cache        = "writethrough"
     discard      = "on"
     ssd          = true
     file_format  = "raw"
     size         = 20
     file_id      = local.os_disk_file_id          # ← our hoisted var
   }


  # Remove any existing dynamic disk block here

  dynamic "disk" {
     for_each = {
       for k, spec in local.worker_disk_specs :
       k => spec if spec.vm_id == each.value.vm_id
     }
     content {
       datastore_id = each.value.datastore_id
       file_id      = local.longhorn_disk_files[disk.value.node]
       interface    = disk.value.interface
       iothread     = true
       cache        = "writethrough"
       discard      = "on"
       ssd          = true
       # NO size or file_format here—pre-existing LVM volume
     }
   }


  # Protect the new VM itself from accidentally deleting disks - Use argument syntax
  protection = false

  # ... Keep other original essential settings (cpu, memory, network_device, scsi_hardware etc.) ...
  cpu {
    # ... original cpu settings ...
  }
  memory {
    # ... original memory settings ...
  }
  network_device {
    # ... original network_device settings ...
  }
  scsi_hardware = "virtio-scsi-single" # Example: Keep if original

  # REMOVE unrelated blocks/attributes added in previous attempts (bios, efi_disk, hostpci, initialization, machine, operating_system, etc.)
}

###############################################################################
#  PERSISTENT LONGHORN DISKS — DETACH BEFORE DESTROY, ATTACH AFTER CREATE     #
###############################################################################

resource "null_resource" "longhorn_prepare" {
  for_each = {
    for k, spec in local.worker_disk_specs :
    k => spec if spec.disk_key == "longhorn"
  }
}

resource "null_resource" "longhorn_detach" {
  for_each = {
    for k, spec in local.worker_disk_specs :
    k => spec if spec.disk_key == "longhorn"
  }

  triggers = {
    host      = each.value.host
    vm_id     = each.value.vm_id
    interface = each.value.interface
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      pvesh set /nodes/${self.triggers.host}/qemu/${self.triggers.vm_id}/config \
        -delete ${self.triggers.interface}
    EOF
  }
}

resource "null_resource" "longhorn_attach" {
  for_each   = {
    for k, spec in local.worker_disk_specs :
    k => spec if spec.disk_key == "longhorn"
  }
  depends_on = [proxmox_virtual_environment_vm.this, null_resource.longhorn_detach]

  provisioner "local-exec" {
    when    = create
    command = <<-EOF
      pvesh set /nodes/${each.value.host}/qemu/${each.value.vm_id}/config \
        --${each.value.interface} ${each.value.pool}:vm-${each.value.vm_id}-disk-${each.value.disk_key}
    EOF
  }
}
