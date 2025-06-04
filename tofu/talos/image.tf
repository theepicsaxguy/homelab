locals {
  # Determine if any node in the cluster has igpu=true
  needs_nvidia_extensions = anytrue([
    for name, config in var.nodes : lookup(config, "igpu", false)
  ])
  download_keys = distinct([
    for n in var.nodes : "${n.host_node}|${try(n.update, false) ? local.update_version : local.version}|${tostring(try(n.update, false))}"
  ])

  downloads_map = {
    for key in local.download_keys :
    key => {
      host_node = split("|", key)[0]
      version   = split("|", key)[1]
      update    = split("|", key)[2]
    }
  }
  version      = var.talos_image.version
  schematic    = templatefile("${path.root}/${var.talos_image.schematic_path}", {
    needs_nvidia_extensions = local.needs_nvidia_extensions
  })
  schematic_id = jsondecode(data.http.schematic_id.response_body)["id"]

  # Always compute update version and schematic path/content
  update_version        = coalesce(var.talos_image.update_version, var.talos_image.version)
  update_schematic_path = coalesce(var.talos_image.update_schematic_path, var.talos_image.schematic_path)
  # Render the update schematic template (could be the same or different schematic)
  update_schematic      = templatefile("${path.root}/${local.update_schematic_path}", {
    needs_nvidia_extensions = local.needs_nvidia_extensions
  })

  # These will now always be available because data.http.updated_schematic_id and talos_image_factory_schematic.updated will always exist.
  update_schematic_id = jsondecode(data.http.updated_schematic_id.response_body)["id"]

  # These are now always computed
  image_id        = "${local.schematic_id}_${local.version}"
  update_image_id = "${local.update_schematic_id}_${local.update_version}"
}

data "http" "schematic_id" {
  url          = "${var.talos_image.factory_url}/schematics"
  method       = "POST"
  request_body = local.schematic
}

# Always fetch update schematic ID
data "http" "updated_schematic_id" {
  url          = "${var.talos_image.factory_url}/schematics"
  method       = "POST"
  request_body = local.update_schematic
}

resource "talos_image_factory_schematic" "this" {
  schematic = local.schematic
}

# Always create update schematic resource
resource "talos_image_factory_schematic" "updated" {
  schematic = local.update_schematic
}

resource "proxmox_virtual_environment_download_file" "this" {
  for_each = local.downloads_map

  node_name    = each.value.host_node
  content_type = "iso"
  datastore_id = var.talos_image.proxmox_datastore

  file_name    = "talos-${each.value.host_node}-${each.value.version}-${var.talos_image.platform}-${var.talos_image.arch}.img"
  url = (
    each.value.update == "true"
    ? format("%s/image/%s/%s/%s-%s.raw.gz",
        var.talos_image.factory_url,
        talos_image_factory_schematic.updated.id,
        local.update_version,
        var.talos_image.platform,
        var.talos_image.arch
      )
    : format("%s/image/%s/%s/%s-%s.raw.gz",
        var.talos_image.factory_url,
        talos_image_factory_schematic.this.id,
        local.version,
        var.talos_image.platform,
        var.talos_image.arch
      )
  )
  decompression_algorithm = "gz"
  overwrite               = false
}

# Debug outputs to understand the current state
output "debug_image_state" {
  value = {
    image_id                   = local.image_id
    update_image_id            = local.update_image_id
    update_schematic_id        = local.update_schematic_id
    nodes_with_update          = [for k, v in var.nodes : k if lookup(v, "update", false) == true]
    proxmox_download_file_keys = keys(proxmox_virtual_environment_download_file.this)
  }
}
