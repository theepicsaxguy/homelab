# Setup step by step

```console
cd tofu/kubernetes
```

```console
tofu init
```

```console
tofu init
```

```console
tofu plan
```

## terraform.tfvars example
proxmox = {
  name         = "host3"
  cluster_name = "host3"
  endpoint     = "https://adress:8006"
  insecure     = false
  username     = "root"
  api_token    = "root@pam!ID=TOKEN"
}proxmox = {
  name         = "host3"
  cluster_name = "host3"
  endpoint     = "https://adress:8006"
  insecure     = false
  username     = "root"
  api_token    = "root@pam!ID=TOKEN"
}

image = {
  version           = "v1.6.4"
  schematic         = "standard"
  update_version    = "v1.6.4"
  update_schematic  = "standard"
  platform          = "proxmox"
  arch              = "amd64"
  proxmox_datastore = "local"
  factory_url       = "https://factory.talos.dev"
}

# plan


tofu apply -target=module.talos.talos_image_factory_schematic.this -target=module.talos.talos_image_factory_schematic.updated

tofu apply

