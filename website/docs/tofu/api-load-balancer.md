---
title: API load balancer
---

# API load balancer

Two small VMs run `HAProxy` and `Keepalived`. OpenTofu downloads an Ubuntu 24.04 cloud image and configures the VMs with Proxmox `cloud-init`. `HAProxy` checks `/readyz` on each control plane node over HTTPS and routes only to nodes that respond. `Keepalived` advertises a virtual IP used by the Domain Name System (DNS) record `api.<cluster-domain>`.

## Configuration

Add the virtual IP and load balancer nodes in `config.auto.tfvars`.

```hcl
network = {
  api_lb_vip = "10.25.150.9"
}

lb_nodes = {
  lb-00 = {
    host_node   = "host3"
    ip          = "10.25.150.5"
    mac_address = "bc:24:11:aa:aa:05"
    vm_id       = 8005
  }
  lb-01 = {
    host_node   = "host3"
    ip          = "10.25.150.6"
    mac_address = "bc:24:11:aa:aa:06"
    vm_id       = 8006
  }
}
```

Create a Domain Name System (DNS) A record `api.<cluster-domain>` pointing at `api_lb_vip`.

## Verification

After planning the infrastructure, verify the API responds.

```shell
curl -k "https://api.<cluster-domain>:6443/readyz"
```

The command prints `ok` when the API is ready.
