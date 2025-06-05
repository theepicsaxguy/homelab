---
sidebar_position: 5
title: Domain Management
description: Centralizing domain values for cluster resources
---

Managing domain names across the cluster can be challenging when values are hardcoded in many manifests. This project
uses a **cluster-domains** ConfigMap under `k8s/components/cluster-domains` to define the base domain, cluster domain,
and common FQDNs. Gateway manifests contain placeholder values (`placeholder-wildcard`, `placeholder-base`, and
`placeholder-cluster`) for hostnames and certificate SANs. Other services like **cloudflared** and the TLS passthrough
gateway reference additional placeholders (`$(ittoolsDomain)`, `$(proxmoxDomain)`, `$(truenasDomain)`, and
`$(omadaDomain)`), which are substituted from the same ConfigMap. Kustomize replacements or variable substitution inject
the final domain names during a build.

Include the component in any kustomization that needs these domains:

```yaml
components:
  - ../../components/cluster-domains
```

To locate other hard-coded domain references, search the repository for your base domain:

```bash
grep -R "pc-tips.se" -n
```

Replace `pc-tips.se` with your actual domain as needed. Update any newly discovered references to pull from the
ConfigMap or parameterize them appropriately.
