# tofu/talos/image.tf

locals {
  # Determine if any node in the cluster has igpu=true
  needs_nvidia_extensions = anytrue([
    for _, node in var.nodes : lookup(node, "igpu", false)
  ])
}

locals {
  version = var.talos_image.version

  schematic = templatefile("${path.root}/${var.talos_image.schematic_path}", {
    needs_nvidia_extensions = local.needs_nvidia_extensions
  })

  update_version        = coalesce(var.talos_image.update_version, var.talos_image.version)
  update_schematic_path = coalesce(var.talos_image.update_schematic_path, var.talos_image.schematic_path)
  update_schematic = templatefile("${path.root}/${local.update_schematic_path}", {
    needs_nvidia_extensions = local.needs_nvidia_extensions
  })
}

locals {
  image_download_key = {
    for name, node in var.nodes :
    name => "${node.host_node}_${lookup(node, "update", false)}"
  }

  # This local is now NON-SENSITIVE and valid for for_each.
  image_downloads = {
    for key, nodes in {
      for name, node in var.nodes :
      local.image_download_key[name] => node...
    } : key => {
      host_node = nodes[0].host_node
      version   = lookup(nodes[0], "update", false) ? local.update_version : local.version
      is_update = lookup(nodes[0], "update", false)
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

  # The sensitive schematic ID is used here, which is allowed.
  file_name = "talos-${each.value.is_update ? talos_image_factory_schematic.updated.id : talos_image_factory_schematic.this.id}-${each.value.version}-${var.talos_image.platform}-${var.talos_image.arch}.img"
  url       = "${var.talos_image.factory_url}/image/${each.value.is_update ? talos_image_factory_schematic.updated.id : talos_image_factory_schematic.this.id}/${each.value.version}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz"

  decompression_algorithm = "gz"
  overwrite               = false
}
