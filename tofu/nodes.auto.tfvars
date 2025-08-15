nodes_config = {
  "ctrl-00" = {
    machine_type  = "controlplane"
    ip            = "10.25.150.11"
    mac_address   = "bc:24:11:e6:ba:07"
    vm_id         = 8101
    ram_dedicated = 7168
  }
  "ctrl-01" = {
    machine_type = "controlplane"
    ip           = "10.25.150.12"
    mac_address  = "bc:24:11:44:94:5c"
    vm_id        = 8102
  }
  "ctrl-02" = {
    machine_type = "controlplane"
    ip           = "10.25.150.13"
    mac_address  = "bc:24:11:1e:1d:2f"
    vm_id        = 8103
  }
  "work-00" = {
    machine_type = "worker"
    ip           = "10.25.150.21"
    mac_address  = "bc:24:11:64:5b:cb"
    vm_id        = 8201
  }
  "work-01" = {
    machine_type = "worker"
    ip           = "10.25.150.22"
    mac_address  = "bc:24:11:c9:22:c3"
    vm_id        = 8202
  }
  "work-02" = {
    machine_type = "worker"
    ip           = "10.25.150.23"
    mac_address  = "bc:24:11:6f:20:03"
    vm_id        = 8203
    disks = {
      longhorn = {
        device      = "/dev/sdb"
        size        = "180G"
        type        = "scsi"
        mountpoint  = "/var/lib/longhorn"
        unit_number = 1
      }
    }
  }
  "work-03" = {
    machine_type  = "worker"
    ip            = "10.25.150.24"
    mac_address   = "bc:24:11:6f:20:04"
    vm_id         = 8204
    ram_dedicated = 5168
    datastore_id  = "rpool2"
    disks = {
      longhorn = {
        device      = "/dev/sdb"
        size        = "180G"
        type        = "scsi"
        mountpoint  = "/var/lib/longhorn"
        unit_number = 1
      }
    }
  }
  # "work-04" = {
  #   machine_type       = "worker"
  #   ip                 = "10.25.150.24"
  #   mac_address        = "bc:24:11:7f:20:04"
  #   vm_id              = 8204
  #   ram_dedicated      = 5168
  #   datastore_id       = "rpool2"
  #   igpu               = true
  #   gpu_node_exclusive = true
  #   gpu_devices        = ["0000:03:00.0", "0000:03:00.1"]
  #   gpu_device_meta = {
  #     "0000:03:00.0" = { id = "10de:13ba", subsystem_id = "10de:1097", iommu_group = 50 }
  #     "0000:03:00.1" = { id = "10de:0fbc", subsystem_id = "10de:1097", iommu_group = 50 }
  #   }
  # }
  # "baremetal-01" = {
  #   machine_type = "worker"
  #   ip           = "10.25.150.30"
  #   is_external  = true
  # }
}
