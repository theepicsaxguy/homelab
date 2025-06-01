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

  # Safely access the response_body, using try() to prevent errors if updated_schematic_id has count 0
  _update_schematic_response_body = local.needs_update_image ? try(data.http.updated_schematic_id[0].response_body, null) : null
  update_schematic_id   = local.needs_update_image && local._update_schematic_response_body != null ? jsondecode(local._update_schematic_response_body)["id"] : null

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
  image_downloads = merge(
    {
      for combo in distinct([
        for v in var.nodes : {
          host_node = v.host_node
          image_id  = local.image_id
          version   = local.version
          schematic = talos_image_factory_schematic.this.id
          is_update = false
        }
      ]) :
      "${combo.host_node}_${combo.image_id}" => combo
    },
    local.update_image_id != null ? {
      for combo in distinct([
        for v in var.nodes : {
          host_node = v.host_node
          image_id  = local.update_image_id
          version   = local.update_version
          schematic = talos_image_factory_schematic.updated[0].id
          is_update = true
        }
      ]) :
      "${combo.host_node}_${combo.image_id}" => combo
    } : {}
  )
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

resource "null_resource" "fail_on_invalid_update" {
  for_each = {
    for k, v in var.nodes : k => v
    if v.update == true && !local.needs_update_image
  }
  provisioner "local-exec" {
    command = "echo 'ERROR: Node ${each.key} (${each.value.name}) has .update set to true, but local.needs_update_image is false. This indicates an invalid configuration where an update is requested but no update image is scheduled for download. Please check var.talos_version_update and node configurations.' && exit 1"
  }
}

# Debug outputs to understand the current state
output "debug_image_state" {
  value = {
    needs_update_image = local.needs_update_image
    image_id = local.image_id
    update_image_id = local.update_image_id
    update_schematic_id = local.update_schematic_id
    nodes_with_update = [
      for k, v in var.nodes : k if lookup(v, "update", false) == true
    ]
    image_downloads_keys = keys(local.image_downloads)
  }
}
