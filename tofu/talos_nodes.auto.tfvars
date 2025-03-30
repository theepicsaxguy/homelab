talos_nodes = {
  "ctrl-00" = {
    host_node     = "host3"
    machine_type  = "controlplane"
    ip = "10.25.150.11"
    dns           = ["10.25.150.1"]
    mac_address   = "bc:24:11:e6:ba:07"
    vm_id         = 800
    cpu           = 8
    ram_dedicated = 3096
    igpu          = false
  }
  "ctrl-01" = {
    host_node     = "host3"
    machine_type  = "controlplane"
    ip            = "10.25.150.12"
    dns           = ["10.25.150.1"]
    mac_address   = "bc:24:11:44:94:5c"
    vm_id         = 801
    cpu           = 4
    ram_dedicated = 3096
    igpu          = false
    #update        = true
  }
  "ctrl-02" = {
    host_node     = "host3"
    machine_type  = "controlplane"
    ip            = "10.25.150.13"
    dns           = ["10.25.150.1"]
    mac_address   = "bc:24:11:1e:1d:2f"
    vm_id         = 802
    cpu           = 4
    ram_dedicated = 3096
    #update        = true
  }
     "work-00" = {
       host_node     = "host3"
       machine_type  = "worker"
       ip            = "10.25.150.21"
       dns           = ["10.25.150.1"]
       mac_address   = "bc:24:11:64:5b:cb"
       vm_id         = 810
       cpu           = 8
       ram_dedicated = 5096
     }
     "work-01" = {
       host_node     = "host3"
       machine_type  = "worker"
       ip            = "10.25.150.22"
       dns           = ["10.25.150.1"]
       mac_address   = "bc:24:11:c9:22:c3"
       vm_id         = 811
       cpu           = 8
       ram_dedicated = 5096
     }
     "work-02" = {
       host_node     = "host3"
       machine_type  = "worker"
       ip            = "10.25.150.23"
       dns           = ["10.25.150.1"]
       mac_address   = "bc:24:11:6f:20:03"
       vm_id         = 813
       cpu           = 8
       ram_dedicated = 5096
     }
}
