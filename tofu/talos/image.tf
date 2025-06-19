locals {
  # Determine if any node in the cluster has igpu=true
  needs_nvidia_extensions = anytrue([
    for name, config in var.nodes : lookup(config, "igpu", false)
  ])
}

locals {
  version = var.talos_image.version
  schematic = templatefile("${path.root}/${var.talos_image.schematic_path}", {
    needs_nvidia_extensions = local.needs_nvidia_extensions
  })
  schematic_id = talos_image_factory_schematic.this.id

  update_version        = coalesce(var.talos_image.update_version, var.talos_image.version)
  update_schematic_path = coalesce(var.talos_image.update_schematic_path, var.talos_image.schematic_path)
  update_schematic = templatefile("${path.root}/${local.update_schematic_path}", {
    needs_nvidia_extensions = local.needs_nvidia_extensions
  })
  update_schematic_id = talos_image_factory_schematic.updated.id

  image_id        = "${local.schematic_id}_${local.version}"
  update_image_id = "${local.update_schematic_id}_${local.update_version}"
}

locals {
  image_downloads = {
    for name, node in var.nodes : "${name}_${node.update ? "update" : "base"}" => {
      host_node = node.host_node
      version   = node.update ? local.update_version : local.version
      schematic = node.update ? talos_image_factory_schematic.updated.id : talos_image_factory_schematic.this.id
    }
  }
}



resource "talos_image_factory_schematic" "this" {
  schematic = local.schematic
}

# Always create update schematic resource
resource "talos_image_factory_schematic" "updated" {
  schematic = local.update_schematic
}

resource "proxmox_virtual_environment_download_file" "this" {
  for_each = local.image_downloads

  node_name    = each.value.host_node
  content_type = "iso"
  datastore_id = var.talos_image.proxmox_datastore

  file_name               = "talos-${each.value.schematic}-${each.value.version}-${var.talos_image.platform}-${var.talos_image.arch}.img"
  url                     = "${var.talos_image.factory_url}/image/${each.value.schematic}/${each.value.version}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false

}

