locals {
  version            = var.image.version
  schematic          = var.image.schematic
  image_id           = "${talos_image_factory_schematic.this.id}_${local.version}"
  needs_update_image = anytrue([for node in var.nodes : lookup(node, "update", false)])
  update_image_id    = local.needs_update_image ? "${talos_image_factory_schematic.updated[0].id}_${var.image.update_version}" : null
  # Collapse ternary onto one line
  # Revert back to using .id for the downloaded file identifier
}

resource "talos_image_factory_schematic" "this" {
  schematic = local.schematic
}

resource "talos_image_factory_schematic" "updated" {
  count     = local.needs_update_image ? 1 : 0
  schematic = coalesce(var.image.update_schematic, local.schematic)
}

resource "proxmox_virtual_environment_download_file" "this" {
  node_name    = "host3"
  content_type = "iso"
  datastore_id = var.image.proxmox_datastore

  file_name               = "talos-${local.image_id}-${var.image.platform}-${var.image.arch}.img"
  url                     = "${var.image.factory_url}/image/${talos_image_factory_schematic.this.id}/${local.version}/${var.image.platform}-${var.image.arch}.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}

resource "proxmox_virtual_environment_download_file" "update" {
  count = local.needs_update_image ? 1 : 0

  node_name    = "host3"
  content_type = "iso"
  datastore_id = var.image.proxmox_datastore

  file_name               = try("talos-${local.update_image_id}-${var.image.platform}-${var.image.arch}.img", "")
  url                     = try("${var.image.factory_url}/image/${talos_image_factory_schematic.updated[0].id}/${var.image.update_version}/${var.image.platform}-${var.image.arch}.raw.gz", "")
  decompression_algorithm = "gz"
  overwrite               = false
}
