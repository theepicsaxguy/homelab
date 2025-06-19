resource "terraform_data" "image_version" {
  # Tracks the intended Talos image version. Bumping
  # `var.talos_image.update_version` forces a VM replacement
  # through `replace_triggered_by` in the VM resource.
  input = var.talos_image.update_version
}
