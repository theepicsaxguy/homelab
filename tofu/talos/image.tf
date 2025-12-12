# tofu/talos/image.tf

# Moved blocks to handle resource renaming without recreation
moved {
  from = talos_image_factory_schematic.main["std_inst"]
  to   = talos_image_factory_schematic.main["std"]
}

moved {
  from = proxmox_virtual_environment_download_file.iso["host3-inst-std"]
  to   = proxmox_virtual_environment_download_file.iso["host3-std"]
}

locals {
  has_gpu_nodes = anytrue([for name, node in var.nodes : lookup(node, "igpu", false)])

  # Simplified schematic configs - only one version per type (std/gpu)
  schematic_configs = merge(
    {
      "std" = {
        needs_nvidia_extensions = false
        version                 = var.talos_image.version
        schematic_path          = var.talos_image.schematic_path
      }
    },
    local.has_gpu_nodes ? {
      "gpu" = {
        needs_nvidia_extensions = true
        version                 = var.talos_image.version
        schematic_path          = var.talos_image.schematic_path
      }
    } : {}
  )

  get_schematic_key = {
    for name, node in var.nodes :
    name => lookup(node, "igpu", false) ? "gpu" : "std"
  }

  # one stable key per host+schematic-type
  #   <host>-<gpu|std>
  image_download_groups = {
    for name, node in var.nodes :
    "${node.host_node}-${lookup(node, "igpu", false) ? "gpu" : "std"}" => {
      host_node    = node.host_node
      schematic_id = talos_image_factory_schematic.main[local.get_schematic_key[name]].id
      version      = var.talos_image.version
    }...
    # External nodes manage their own images, skip factory download
    if !lookup(node, "is_external", false)
  }

  image_downloads = {
    for k, v in local.image_download_groups : k => v[0]
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
