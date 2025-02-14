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
}
