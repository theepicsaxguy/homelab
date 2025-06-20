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
    memory = {
      dedicated = 12046
    }
  }
  "work-02" = {
    machine_type = "worker"
    ip           = "10.25.150.23"
    mac_address  = "bc:24:11:6f:20:03"
    vm_id        = 8203
  }
}
