locals {
  version      = var.talos_image.version
  schematic    = file("${path.root}/${var.talos_image.schematic_path}")
  schematic_id = jsondecode(data.http.schematic_id.response_body)["id"]

  # Check if any nodes need updates (restore old conditional logic)
  needs_update_image = anytrue([for node in var.nodes : lookup(node, "update", false)])

  # Only compute update values if updates are needed
  update_version        = local.needs_update_image ? coalesce(var.talos_image.update_version, var.talos_image.version) : null
  update_schematic_path = local.needs_update_image ? coalesce(var.talos_image.update_schematic_path, var.talos_image.schematic_path) : null
  update_schematic      = local.needs_update_image ? file("${path.root}/${local.update_schematic_path}") : null
  update_schematic_id   = local.needs_update_image ? jsondecode(data.http.updated_schematic_id[0].response_body)["id"] : null

  image_id        = "${local.schematic_id}_${local.version}"
  update_image_id = local.needs_update_image ? "${local.update_schematic_id}_${local.update_version}" : null

  # Comment the above 2 lines and un-comment the below 2 lines to use the provider schematic ID instead of the HTTP one
  # ref - https://github.com/vehagn/homelab/issues/106
  # image_id = "${talos_image_factory_schematic.this.id}_${local.version}"
  # update_image_id = local.needs_update_image ? "${talos_image_factory_schematic.updated[0].id}_${local.update_version}" : null
}

data "http" "schematic_id" {
  url          = "${var.talos_image.factory_url}/schematics"
  method       = "POST"
  request_body = local.schematic
}

# Only make HTTP call for update schematic if updates are needed
data "http" "updated_schematic_id" {
  count        = local.needs_update_image ? 1 : 0
  url          = "${var.talos_image.factory_url}/schematics"
  method       = "POST"
  request_body = local.update_schematic
}

resource "talos_image_factory_schematic" "this" {
  schematic = local.schematic
}

# Only create update schematic resource if updates are needed
resource "talos_image_factory_schematic" "updated" {
  count     = local.needs_update_image ? 1 : 0
  schematic = local.update_schematic
}

# Create a map of unique image downloads needed per host
locals {
  # Create unique combinations of host_node + image_id
  image_downloads = {
    for combo in distinct([
      for k, v in var.nodes : {
        host_node = v.host_node
        image_id  = v.update == true ? local.update_image_id : local.image_id
        version   = v.update == true ? local.update_version : local.version
        schematic = v.update == true ? (local.needs_update_image ? talos_image_factory_schematic.updated[0].id : null) : talos_image_factory_schematic.this.id
        is_update = v.update == true
      }
      # Only include valid combinations
      if (v.update == false) || (v.update == true && local.needs_update_image)
    ]) : "${combo.host_node}_${combo.image_id}" => combo
    # Filter out any entries where image_id or schematic is null
    if combo.image_id != null && combo.schematic != null
  }
}

# Use for_each for efficient distribution to host nodes, downloading each unique image only once per host
resource "proxmox_virtual_environment_download_file" "this" {
  for_each = local.image_downloads

  node_name    = each.value.host_node
  content_type = "iso"
  datastore_id = var.talos_image.proxmox_datastore

  file_name               = "talos-${each.value.schematic}-${each.value.version}-${var.talos_image.platform}-${var.talos_image.arch}.img"
  url                     = "${var.talos_image.factory_url}/image/${each.value.schematic}/${each.value.version}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false

  lifecycle {
    create_before_destroy = true
  }
}

# Migration helpers - create locals to map old resource references to new ones
locals {
  # Create a mapping from node name to the new download file resource
  node_to_download_file = {
    for k, v in var.nodes : k => {
      # Determine which download file this node should use
      download_key = "${v.host_node}_${v.update == true ? local.update_image_id : local.image_id}"
      file_id = contains(keys(local.image_downloads), "${v.host_node}_${v.update == true ? local.update_image_id : local.image_id}") ? proxmox_virtual_environment_download_file.this["${v.host_node}_${v.update == true ? local.update_image_id : local.image_id}"].id : null
    }
  }
}
