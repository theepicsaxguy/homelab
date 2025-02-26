resource "kubernetes_persistent_volume" "volume" {
  metadata {
    name = var.volume.name
  }
  spec {
    capacity = {
      storage = var.volume.capacity
    }
    access_modes = ["ReadWriteOnce"]
    storage_class_name = "longhorn"
    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      csi {
        driver = "driver.longhorn.io"
        volume_handle = var.volume.name
        fs_type = "ext4"
      }
    }
  }
}
