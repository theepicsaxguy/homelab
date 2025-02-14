# Kubernetes Tofu

```shell
tofu output -raw kube_config 
tofu output -raw talos_config
```

tofu output -raw talos_config > ~/.talos/config
chmod 600 ~/.talos/config
