---
title: Zigbee2MQTT
---

This document outlines the conceptual and procedural approach for managing the `zigbee2mqtt` application. The deployment is fully declarative and GitOps-managed.

## Overview of Zigbee2MQTT in this cluster

The `zigbee2mqtt` setup is designed for stability and ease of maintenance. The configuration is templated and seeded into the application's data volume, which allows for version control of the configuration while still allowing the application to write to its data directory.

## Important considerations

### Configuration management

The `zigbee2mqtt` configuration is managed via a `ConfigMap` that contains the `configuration.yaml`, `devices.yaml`, and `groups.yaml` files. An init container copies these files to a persistent volume on startup.

*   **Why:** This approach ensures that the application always starts with a known good configuration from Git, while still allowing `zigbee2mqtt` to write its own files to the data directory.

### External converters

To support Zigbee devices that are not natively supported by `zigbee2mqtt`, external converters can be used. These are JavaScript files that define how to interpret the messages from a specific device. These converters are also managed in a `ConfigMap` and copied to the data volume by the init container.

*   **Why:** This allows for supporting a wider range of devices and keeps the device-specific logic version-controlled.

:::info
If Zigbee2MQTT renames a converter file to `.invalid`, the most common cause is an API change in `zigbee-herdsman-converters`; remove unsupported helpers such as `linkquality()`.
:::

### Secret management

Sensitive information, such as the Zigbee network key and PAN ID, are managed by `ExternalSecrets`. These secrets are injected into the `zigbee2mqtt` container as environment variables, which `zigbee2mqtt` then uses to configure itself. The following environment variables are used:

*   `ZIGBEE2MQTT_CONFIG_ADVANCED_NETWORK_KEY`
*   `ZIGBEE2MQTT_CONFIG_ADVANCED_PAN_ID`
*   `ZIGBEE2MQTT_CONFIG_ADVANCED_EXTENDED_PAN_ID`

*   **Why:** This avoids storing sensitive information in the Git repository and allows for a single source of truth for secrets. See the [Zigbee2MQTT documentation](https://www.zigbee2mqtt.io/guide/configuration/via-environment-variables.html) for the current list of environment variables.

### Storage

The `zigbee2mqtt` application requires a persistent volume to store its data, including the configuration files and the Zigbee network database. The persistent volume claim (PVC) is configured with `ReadWriteMany` access mode.

*   **Why:** `ReadWriteMany` supports potential future scaling scenarios, although it is currently used by a single replica.

## Procedural guide

### Adding a new external converter

1.  Create a new JavaScript file for the external converter in `k8s/applications/automation/zigbee2mqtt/config/`.
2.  Add the new file to the `configMapGenerator` in `k8s/applications/automation/zigbee2mqtt/kustomization.yaml`.
3.  Update the `initContainers` section in `k8s/applications/automation/zigbee2mqtt/deployment.yaml` to copy the new converter to the `external_converters` directory in the data volume.
4.  Reference the new converter in the `external_converters` section of `k8s/applications/automation/zigbee2mqtt/config/configuration.yaml`.

### Updating the configuration

1.  Modify the relevant configuration file in `k8s/applications/automation/zigbee2mqtt/config/`.
2.  The changes will be automatically applied during the next GitOps sync.

