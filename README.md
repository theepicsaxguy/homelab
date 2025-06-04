# Homelab

A GitOps-managed Kubernetes lab built for minimal maintenance and fast recovery—because I'd rather chase my kid than endless VMs.

## Features

- Talos Linux nodes provisioned on Proxmox with OpenTofu
- GitOps workflow via ArgoCD and Kustomize
- Cilium networking with Gateway API
- Central authentication using Authentik
- Disaster recovery in only a few commands

_Built with love, caffeine, and a whole lot of "not again!" moments._

For the story behind this setup, see the [Project Overview](https://homelab.orkestack.com/docs/project-overview).

## Quick start

```bash
# clone the repo
git clone https://github.com/theepicsaxguy/homelab.git
cd homelab/tofu

tofu init && tofu apply       # provision infrastructure
cd ../k8s
tofu init && tofu apply       # deploy workloads
```

For a detailed walkthrough see the [Quick Start guide](https://homelab.orkestack.com/docs/quick-start).

## Documentation

Additional documentation is available online at [homelab.orkestack.com/docs](https://homelab.orkestack.com/docs/).

## Contributing

Issues and pull requests are welcome.

## License

This project is licensed under the [MIT License](LICENSE).

## Credits

Special thanks to the inspiration and work behind [Vehagn's Homelab](https://github.com/vehagn/homelab).
