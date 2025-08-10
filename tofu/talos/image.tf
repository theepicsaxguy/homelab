locals {
  update_version        = coalesce(var.talos_image.update_version, var.talos_image.version)
  update_schematic_path = coalesce(var.talos_image.update_schematic_path, var.talos_image.schematic_path)

  # GPU/STD + update/install key per node
  get_schematic_key = {
    for name, node in var.nodes :
    name => "${lookup(node,"igpu",false) ? "gpu" : "std"}_${lookup(node,"update",false) ? "upd" : "inst"}"
  }

  # canonical keys: <host>-<upd|inst>-<gpu|std>, skip externals
  vm_keys = [
    for name, node in var.nodes :
    "${node.host_node}-${lookup(node,"update",false) ? "upd" : "inst"}-${lookup(node,"igpu",false) ? "gpu" : "std"}"
    if !lookup(node, "is_external", false)
  ]

  vm_key_set = toset(local.vm_keys)

  # Build the download URL and file name from either explicit URLs or factory pieces
  image_meta = {
    "inst" = {
      url       = coalesce(
        try(var.talos_image.image_url, null),
        try("${var.talos_image.factory_url}/image/${var.talos_image.schematic_id}/${var.talos_image.version}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz", null),
        "https://factory.talos.dev/image/invalid/v1.0.0/nocloud-amd64.raw.gz"
      )
      file_name = coalesce(
        try(var.talos_image.file_name, null),
        "talos-${coalesce(var.talos_image.schematic_id, "schem")}-${var.talos_image.version}-${var.talos_image.platform}-${var.talos_image.arch}.img"
      )
      version = var.talos_image.version
    }
    "upd" = {
      url       = coalesce(
        try(var.talos_image.update_image_url, null),
        try("${var.talos_image.factory_url}/image/${coalesce(var.talos_image.update_schematic_id, var.talos_image.schematic_id)}/${local.update_version}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz", null),
        "https://factory.talos.dev/image/invalid/v1.0.0/nocloud-amd64.raw.gz"
      )
      file_name = coalesce(
        try(var.talos_image.update_file_name, null),
        "talos-${coalesce(var.talos_image.update_schematic_id, var.talos_image.schematic_id, "schem")}-${local.update_version}-${var.talos_image.platform}-${var.talos_image.arch}.img"
      )
      version = local.update_version
    }
  }

  image_download_groups = {
    for k in local.vm_key_set :
    # k = "<host>-<upd|inst>-<gpu|std>"
    k => {
      host_node = element(split("-", k), 0)
      phase     = element(split("-", k), 1)  # "upd" | "inst"
      # gpu/std currently share same image; if you need GPU builds, feed a different schematic_id/url via vars for those nodes.
      url       = local.image_meta[element(split("-", k), 1)].url
      file_name = local.image_meta[element(split("-", k), 1)].file_name
    }
  }
}

# Used to trigger re-apply of VM boot disk on image change
resource "terraform_data" "image_version" {
  input = {
    version = var.talos_image.version
    update  = local.update_version
    hash    = filesha256(var.talos_image.schematic_path)
    hash_u  = filesha256(local.update_schematic_path)
  }
}

resource "proxmox_virtual_environment_download_file" "iso" {
  for_each     = local.image_download_groups
  node_name    = each.value.host_node
  content_type = "iso"
  datastore_id = var.talos_image.proxmox_datastore

  file_name               = each.value.file_name
  url                     = each.value.url
  decompression_algorithm = "gz"
  overwrite               = false
}
