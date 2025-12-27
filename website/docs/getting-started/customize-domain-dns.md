---
sidebar_position: 3
title: Customize Domain and Configure DNS
description:
  This task guides you through configuring your custom domain and setting up necessary DNS prerequisites for your
  homelab cluster, which uses Cloudflare for automated DNS record management via Crossplane.
---

This task explains how to customize your homelab cluster to use your own domain name instead of the default
`peekoff.com` and how to configure your Domain Name System (DNS) provider. This setup requires Cloudflare for automated
DNS record provisioning.

**Audience:** Users deploying a new homelab cluster from this repository.

**Prerequisites:**

- A command-line environment with `rg` (ripgrep) and `sed` installed.
- An active Cloudflare account with a registered domain.
- A [Cloudflare API Token](https://developers.cloudflare.com/api/tokens/create/) with permissions to edit DNS records
  for your zone.
- Your Cloudflare DNS Zone ID, which is available on your domain's overview page in the Cloudflare dashboard.

### Replace Hard-Coded Domain References

The repository uses the placeholder domain `peekoff.com` throughout its configuration files. This project uses
hard-coded domain references to simplify initial setup and avoid complex templating engines for this homelab context.
You must replace all instances with your custom domain.

To replace all occurrences of `peekoff.com` with your domain, navigate to the root of your local repository and execute
the following command. Replace `your-domain.com` with your actual domain name.

```shell
rg -l "peekoff.com" | xargs sed -i 's/peekoff\.se/your-domain.com/g'
```

This command uses ripgrep (`rg`) to locate files containing the string `peekoff.com` and then uses `sed` to perform an
in-place replacement.

:::warning Failing to perform this step will result in drift, where your Kubernetes services are configured with a
domain you don't control, preventing them from functioning correctly. :::

### Configure Cloudflare DNS

This homelab cluster uses Crossplane to automatically provision DNS records in Cloudflare based on Kubernetes manifests.
For this reason, Cloudflare is a mandatory dependency.

:::note This project uses the External Secrets operator to fetch the Cloudflare API token from a Bitwarden instance.
This approach avoids storing secrets directly in Git repositories. :::

While Crossplane will manage most DNS records automatically, **you must manually create an `A` record** to point your
domain to the cluster's external IP address.

**Steps to configure the initial DNS record:**

1.  **Obtain your cluster's external IP address.** This is the public IP address assigned to the
    `cilium-gateway-external` service in the `gateway` namespace. After running `tofu apply`, you can find it by
    running:

    ```shell
    kubectl get svc -n gateway cilium-gateway-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    ```

2.  **Create an `A` record in Cloudflare.** In your Cloudflare DNS dashboard, create an `A` record for your root domain
    (`@`) and/or a wildcard `A` record (`*`) pointing to the external IP address from the previous step. This ensures
    that all subdomains managed by Crossplane will resolve correctly.

### Understand Tool Responsibilities

:::important It's crucial to understand the distinct roles of the primary tools in this homelab to avoid configuration
issues:

- **OpenTofu**: Provisions the virtual machines and installs the base Talos Kubernetes cluster. It doesn't manage the
  applications running inside the cluster.
- **ArgoCD**: Deploys and manages all Kubernetes applications using the YAML manifests stored in the `k8s/` directory of
  this Git repository.

If you omit the domain replacement step before committing your changes, ArgoCD will deploy applications configured with
the default `peekoff.com` domain. This creates a state of drift, where the infrastructure provisioned by OpenTofu can
use your new domain, but the Kubernetes services will be unreachable because they're pointing to a domain you don't
control. :::

### Example: Domain Change in a Kubernetes Manifest

To illustrate the effect of the domain replacement, observe the following change in the
`k8s/applications/media/jellyfin/http-route.yaml` file.

**Before:**

```yaml
[...]
  hostnames:
    - 'film.peekoff.com'
[...]
```

**After** (with `your-domain.com` applied):

```yaml
[...]
  hostnames:
    - 'film.your-domain.com'
[...]
```
