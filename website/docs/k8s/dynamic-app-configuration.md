---
title: Declarative configuration for dynamic applications
---

Some applications manage their own configuration files and are unaware of GitOps workflows. This guide explains how initContainers and shared volumes let you enforce a declarative setup anyway.

:::info
This approach is handy for tools like Home Assistant or Zigbee2MQTT, but it can be applied to any app that writes to its config directory at runtime.
:::

## Common use cases

- **Seeding a default configuration:** Provide a known-good baseline before the app starts.
- **Merging secrets at startup:** Inject credentials without committing them to Git.

## Overview of the initContainer workflow

1. **Store base files in a ConfigMap.** Version-control the default configuration in your repo.
2. **Keep secrets in Bitwarden.** Use ExternalSecrets so Kubernetes injects them as standard Secrets.
3. **Share a volume between containers.** Both the initContainer and the main container mount the same path.
4. **Run the initContainer first.** It copies or merges the ConfigMap files into the shared volume and substitutes secret values.
5. **Start the main container.** The application reads its configuration from the volume and runs as if it were preconfigured.

This method keeps container images generic while still letting you define configuration in Git. It also preserves runtime-generated files, because the main container has write access to the shared volume.

**Example implementations**

- *Home Assistant* merges a templated configuration with any existing files. The initContainer uses `yq` to combine settings from a ConfigMap with the persistent data volume.
- *Zigbee2MQTT* seeds its directory on first run. If the files already exist, the initContainer simply exits.

## Important considerations

- **Idempotent scripts:** Make the init script safe to rerun. Check if files exist before overwriting them.
- **Volume permissions:** Ensure both containers can write to the shared volume without running as root.
- **Debugging:** If the main container fails, inspect the initContainer logs first—they often reveal configuration issues.
