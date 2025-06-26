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
  # one stable key per host+schematic-type
  #   <host>-<inst|upd>-<gpu|std>
  image_download_groups = {
    for name, node in var.nodes :
    "${node.host_node}-${lookup(node,"update",false) ? "upd" : "inst"}-${lookup(node,"igpu",false) ? "gpu" : "std"}" => {
      host_node    = node.host_node
      schematic_id = lookup(node,"igpu",false) ? (lookup(node,"update",false) ? talos_image_factory_schematic.gpu_updated.id : talos_image_factory_schematic.gpu.id) : (lookup(node,"update",false) ? talos_image_factory_schematic.updated.id : talos_image_factory_schematic.this.id)
    } ...
  }

  image_downloads = {
    for k, v in local.image_download_groups : k => v[0]
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

resource "proxmox_virtual_environment_download_file" "iso" {
  for_each     = local.image_downloads
  node_name    = each.value.host_node
  content_type = "iso"
  datastore_id = var.talos_image.proxmox_datastore

  file_name = "talos-${each.value.schematic_id}-${var.talos_image.version}-${var.talos_image.platform}-${var.talos_image.arch}.img"
  url       = "${var.talos_image.factory_url}/image/${each.value.schematic_id}/${var.talos_image.version}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz"

  decompression_algorithm = "gz"
  overwrite               = false
}
