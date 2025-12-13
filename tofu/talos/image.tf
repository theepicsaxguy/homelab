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

  # Target version for upgrades
  target_version = coalesce(var.talos_image.update_version, var.talos_image.version)

  # Simplified schematic configs - only one version per type (std/gpu)
  schematic_configs = merge(
    {
      "std" = {
        needs_nvidia_extensions = false
        schematic_path          = var.talos_image.schematic_path
      }
    },
    local.has_gpu_nodes ? {
      "gpu" = {
        needs_nvidia_extensions = true
        schematic_path          = var.talos_image.schematic_path
      }
    } : {}
  )

  get_schematic_key = {
    for name, node in var.nodes :
    name => lookup(node, "igpu", false) ? "gpu" : "std"
  }

  # Effective version per node (matches upgrade-nodes.tf logic)
  node_effective_versions = {
    for name, config in var.nodes : name =>
    coalesce(config.upgrade, false) ? local.target_version : var.talos_image.version
  }

  # Collect all version+host+schematic combinations needed
  # Key format: <host>-<std|gpu>-<version>
  image_download_list = flatten([
    for name, node in var.nodes : {
      key          = "${node.host_node}-${local.get_schematic_key[name]}-${local.node_effective_versions[name]}"
      host_node    = node.host_node
      schematic_id = talos_image_factory_schematic.main[local.get_schematic_key[name]].id
      version      = local.node_effective_versions[name]
    }
    if !lookup(node, "is_external", false)
  ])

  # Deduplicate - only one download per unique key
  image_downloads = {
    for item in local.image_download_list : item.key => item...
  }

  # Final downloads map (take first item from each group)
  image_downloads_final = {
    for k, v in local.image_downloads : k => v[0]
  }

  # Map each node to its image download key
  node_image_key = {
    for name, node in var.nodes :
    name => "${node.host_node}-${local.get_schematic_key[name]}-${local.node_effective_versions[name]}"
    if !lookup(node, "is_external", false)
  }
}

resource "talos_image_factory_schematic" "main" {
  for_each = local.schematic_configs
  schematic = templatefile("${path.module}/image/schematic.yaml.tftpl", {
    needs_nvidia_extensions = each.value.needs_nvidia_extensions
  })
}

resource "proxmox_virtual_environment_download_file" "iso" {
  for_each                = local.image_downloads_final
  node_name               = each.value.host_node
  content_type            = "iso"
  datastore_id            = var.talos_image.proxmox_datastore
  file_name               = "talos-${each.value.schematic_id}-${each.value.version}-${var.talos_image.platform}-${var.talos_image.arch}.img"
  url                     = "${var.talos_image.factory_url}/image/${each.value.schematic_id}/${each.value.version}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz"
  upload_timeout          = 800
  decompression_algorithm = "gz"
  overwrite               = false
}
