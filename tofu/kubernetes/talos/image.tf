locals {
  version = var.image.version
  schematic = var.image.schematic
  image_id = "${talos_image_factory_schematic.this.id}_${local.version}"

  update_version = coalesce(var.image.update_version, var.image.version)
  update_schematic = coalesce(var.image.update_schematic, var.image.schematic)
  update_image_id = "${talos_image_factory_schematic.updated.id}_${local.update_version}"
}

resource "talos_image_factory_schematic" "this" {
  schematic = local.schematic
}

resource "talos_image_factory_schematic" "updated" {
  schematic = local.update_schematic
}

resource "proxmox_virtual_environment_download_file" "this" {
  for_each = var.nodes

  node_name    = each.value.host_node
  content_type = "iso"
  datastore_id = var.image.proxmox_datastore

  file_name = "talos-${each.value.update ? (local.update_image_id) : (local.image_id)}-${var.image.platform}-${var.image.arch}.img"
  url       = "${var.image.factory_url}/image/${each.value.update ? (local.update_image_id) : (local.image_id)}/${var.image.platform}-${var.image.arch}.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}

# resource "proxmox_virtual_environment_download_file" "this" {
#   for_each = toset(distinct([for k, v in var.nodes : "${v.host_node}_${v.update == true ? local.update_image_id : local.image_id}"]))

#   node_name    = split("_", each.key)[0]
#   content_type = "iso"
#   datastore_id = var.image.proxmox_datastore

#   file_name               = "talos-${split("_",each.key)[1]}-${split("_", each.key)[2]}-${var.image.platform}-${var.image.arch}.img"
#   url = "${var.image.factory_url}/image/${split("_", each.key)[1]}/${split("_", each.key)[2]}/${var.image.platform}-${var.image.arch}.raw.gz"
#   decompression_algorithm = "gz"
#   overwrite               = false
# }
