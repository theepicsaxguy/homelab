# tofu/talos/image.tf

# tofu/talos/image.tf

locals {
  update_version        = coalesce(var.talos_image.update_version, var.talos_image.version)
  update_schematic_path = coalesce(var.talos_image.update_schematic_path, var.talos_image.schematic_path)

  has_gpu_nodes = anytrue([for name, node in var.nodes : lookup(node, "igpu", false)])

  schematic_configs = merge(
    {
      "std_inst" = {
        needs_nvidia_extensions = false
        version                 = var.talos_image.version
        schematic_path          = var.talos_image.schematic_path
      },
      "std_upd" = {
        needs_nvidia_extensions = false
        version                 = local.update_version
        schematic_path          = local.update_schematic_path
      }
    },
    local.has_gpu_nodes ? {
      "gpu_inst" = {
        needs_nvidia_extensions = true
        version                 = var.talos_image.version
        schematic_path          = var.talos_image.schematic_path
      },
      "gpu_upd" = {
        needs_nvidia_extensions = true
        version                 = local.update_version
        schematic_path          = local.update_schematic_path
      }
    } : {}
  )

  get_schematic_key = {
    for name, node in var.nodes :
    name => "${lookup(node, "igpu", false) ? "gpu" : "std"}_${lookup(node, "update", false) ? "upd" : "inst"}"
  }

  # one stable key per host+schematic-type
  #   <host>-<inst|upd>-<gpu|std>
  image_download_groups = {
    for name, node in var.nodes :
    "${node.host_node}-${lookup(node, "update", false) ? "upd" : "inst"}-${lookup(node, "igpu", false) ? "gpu" : "std"}" => {
      host_node    = node.host_node
      schematic_id = local.schematic_ids[local.get_schematic_key[name]]
      version      = lookup(node, "update", false) ? local.update_version : var.talos_image.version
    }...
    # External nodes manage their own images, skip factory download
    if !lookup(node, "is_external", false)
  }

  image_downloads = {
    for k, v in local.image_download_groups : k => v[0]
  }

  schematic_ids = {
    for k, v in local.schematic_configs : k => (
      v.needs_nvidia_extensions ?
      "29e27ffc20b46e05fccac0b226db69c2cc6987f0d5bca89ab49d02b286674646" :
      "53513e54bb39202f35694412577a6bc53d484744d35a126e5d42ef34785c0d83"
    )
  }
}

resource "talos_image_factory_schematic" "main" {
  for_each = local.schematic_configs
  schematic = templatefile("${path.module}/image/schematic.yaml.tftpl", {
    needs_nvidia_extensions = each.value.needs_nvidia_extensions
  })
}

resource "proxmox_virtual_environment_download_file" "iso" {
  for_each                = local.image_downloads
  node_name               = each.value.host_node
  content_type            = "iso"
  datastore_id            = var.talos_image.proxmox_datastore
  file_name               = "talos-${each.value.schematic_id}-${each.value.version}-${var.talos_image.platform}-${var.talos_image.arch}.img"
  url                     = "${var.talos_image.factory_url}/image/${each.value.schematic_id}/${each.value.version}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz"
  upload_timeout          = 800
  decompression_algorithm = "gz"
  overwrite               = false
}
