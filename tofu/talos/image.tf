locals {
  # Determine if any node in the cluster has igpu=true
  needs_nvidia_extensions = anytrue([
    for name, config in var.nodes : lookup(config, "igpu", false)
  ])
}

locals {
  version = var.talos_image.version

  # 1. render – keep exact text for provider (no ID drift)
  schematic = templatefile("${path.root}/${var.talos_image.schematic_path}", {
    needs_nvidia_extensions = local.needs_nvidia_extensions
  })

  # 2. deterministic hash using only built-ins
  #    yamldecode → structural object (whitespace gone)
  #    jsonencode → canonical JSON string (stable key order)
  schematic_hash = sha256(jsonencode(yamldecode(local.schematic)))
  schematic_id = talos_image_factory_schematic.this.id

  update_version        = coalesce(var.talos_image.update_version, var.talos_image.version)
  update_schematic_path = coalesce(var.talos_image.update_schematic_path, var.talos_image.schematic_path)
  update_schematic = templatefile("${path.root}/${local.update_schematic_path}", {
    needs_nvidia_extensions = local.needs_nvidia_extensions
  })
  update_schematic_hash = sha256(jsonencode(yamldecode(local.update_schematic)))
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
      hash = lookup(nodes[0], "update", false) ? local.update_schematic_hash : local.schematic_hash
    }
  }
}

locals {
  image_id        = "${local.schematic_hash}_${local.version}"
  update_image_id = "${local.update_schematic_hash}_${local.update_version}"
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

  file_name = "talos-${local.image_downloads[each.key].hash}-${each.value.version}-${var.talos_image.platform}-${var.talos_image.arch}.img"
  url       = "${var.talos_image.factory_url}/image/${local.image_downloads[each.key].hash}/${each.value.version}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz"

  decompression_algorithm = "gz"
  overwrite               = false

}

