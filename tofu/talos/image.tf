# tofu/talos/image.tf

# tofu/talos/image.tf

locals {
  version = var.talos_image.version

  schematic_this = templatefile("${path.root}/${var.talos_image.schematic_path}", {
    needs_nvidia_extensions = false
  })

  schematic_gpu = templatefile("${path.root}/${var.talos_image.schematic_path}", {
    needs_nvidia_extensions = true
  })

  update_version        = coalesce(var.talos_image.update_version, var.talos_image.version)
  update_schematic_path = coalesce(var.talos_image.update_schematic_path, var.talos_image.schematic_path)

  update_schematic_this = templatefile("${path.root}/${local.update_schematic_path}", {
    needs_nvidia_extensions = false
  })

  update_schematic_gpu = templatefile("${path.root}/${local.update_schematic_path}", {
    needs_nvidia_extensions = true
  })
}

locals {
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
      is_update = lookup(nodes[0], "update", false)
      igpu      = lookup(nodes[0], "igpu", false)
    }
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = local.schematic_this
}

resource "talos_image_factory_schematic" "updated" {
  schematic = local.update_schematic_this
}

resource "talos_image_factory_schematic" "gpu" {
  schematic = local.schematic_gpu
}

resource "talos_image_factory_schematic" "gpu_updated" {
  schematic = local.update_schematic_gpu
}

resource "proxmox_virtual_environment_download_file" "this" {
  for_each = local.image_downloads

  node_name    = each.value.host_node
  content_type = "iso"
  datastore_id = var.talos_image.proxmox_datastore

  file_name = "talos-${each.value.is_update ? (each.value.igpu ? talos_image_factory_schematic.gpu_updated.id : talos_image_factory_schematic.updated.id) : (each.value.igpu ? talos_image_factory_schematic.gpu.id : talos_image_factory_schematic.this.id)}-${each.value.version}-${var.talos_image.platform}-${var.talos_image.arch}.img"
  url       = "${var.talos_image.factory_url}/image/${each.value.is_update ? (each.value.igpu ? talos_image_factory_schematic.gpu_updated.id : talos_image_factory_schematic.updated.id) : (each.value.igpu ? talos_image_factory_schematic.gpu.id : talos_image_factory_schematic.this.id)}/${each.value.version}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz"

  decompression_algorithm = "gz"
  overwrite               = false
}
