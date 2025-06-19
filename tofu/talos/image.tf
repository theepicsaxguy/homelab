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
  image_key = {
    for name, node in var.nodes :
    name => "${node.host_node}_${lookup(node, "update", false) ? local.update_image_id : local.image_id}"
  }

  image_download_key = {
    for name, node in var.nodes :
    name => "${node.host_node}_${lookup(node, "update", false)}"
  }

  image_downloads = {
    for key, nodes in {
      for name, node in var.nodes :
      local.image_download_key[name] => node...
      } : key => {
      host_node = nodes[0].host_node
      version   = lookup(nodes[0], "update", false) ? local.update_version : local.version
      schematic = lookup(nodes[0], "update", false) ? talos_image_factory_schematic.updated.id : talos_image_factory_schematic.this.id
    }
  }
}



resource "talos_image_factory_schematic" "this" {
  schematic = local.schematic
}

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

