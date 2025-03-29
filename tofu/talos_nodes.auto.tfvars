talos_nodes = {
  "ctrl-00" = {
    host_node     = "host3"
    machine_type  = "controlplane"
    ip = "10.25.150.11"
    dns           = ["10.25.150.1"]
    mac_address   = "BC:24:11:2E:C8:00"
    vm_id         = 800
    cpu           = 8
    ram_dedicated = 4096
    igpu          = false
  }
  "ctrl-01" = {
    host_node     = "host3"
    machine_type  = "controlplane"
    ip            = "10.25.150.12"
    dns           = ["10.25.150.1"]
    mac_address   = "BC:24:11:2E:C8:01"
    vm_id         = 801
    cpu           = 4
    ram_dedicated = 4096
    igpu          = false
    #update        = true
  }
  "ctrl-02" = {
    host_node     = "host3"
    machine_type  = "controlplane"
    ip            = "10.25.150.13"
    dns           = ["10.25.150.1"]
    mac_address   = "BC:24:11:2E:C8:02"
    vm_id         = 802
    cpu           = 4
    ram_dedicated = 4096
    #update        = true
  }
     "work-00" = {
       host_node     = "host3"
       machine_type  = "worker"
       ip            = "10.25.150.21"
       dns           = ["10.25.150.1"]
       mac_address   = "BC:24:11:2E:A8:00"
       vm_id         = 810
       cpu           = 8
       ram_dedicated = 3096
     }
     "work-01" = {
       host_node     = "host3"
       machine_type  = "worker"
       ip            = "10.25.150.22"
       dns           = ["10.25.150.1"]
       mac_address   = "BC:24:11:2E:A8:00"
       vm_id         = 811
       cpu           = 8
       ram_dedicated = 3096
     }
     "work-02" = {
       host_node     = "host3"
       machine_type  = "worker"
       ip            = "10.25.150.23"
       dns           = ["10.25.150.1"]
       mac_address   = "BC:24:11:2E:A8:00"
       vm_id         = 813
       cpu           = 8
       ram_dedicated = 3096
     }
}
