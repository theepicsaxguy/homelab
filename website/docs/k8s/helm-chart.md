---
title: helmchart Application Deployment
---

This document provides a standardized reference for deploying applications in my Kubernetes cluster. It outlines the essential file structure, configuration parameters, and optional components needed for consistent application deployment.

:::info
All applications should follow this base template. Optional components can be added based on specific application requirements such as database integration, authentication, or custom configurations.
:::

## Directory Structure
The following directory structure represents the standard layout for application deployment:

```
<application-name>/
├── externalsecret.yaml    # If secrets are needed
├── http-route.yaml        # Gateway API routing
├── kustomization.yaml     # Required
└── values.yaml           # If using Helm
```

## Core Components

### `kustomization.yaml`
*   **Description:** Main configuration file that defines how the application should be deployed and customized

*   **Type:** `yaml`

*   **Required:** Yes

*   **Example:**
    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    namespace: <app-name>

    resources:
      - http-route.yaml
      # Add other resources as needed

    generatorOptions:
      disableNameSuffixHash: true

    helmCharts:
      - name: <chart-name>
        repo: <helm-repo-url>
        version: <version>
        releaseName: <app-name>
        namespace: <app-name>
        valuesFile: values.yaml
    ```

### `http-route.yaml`
*   **Description:** Defines how traffic should be routed to the application

*   **Type:** `yaml`

*   **Required:** Yes

*   **Example:**
    ```yaml
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: <app-name>
      namespace: <app-name>
    spec:
      parentRefs:
        - name: external
          namespace: gateway
      hostnames:
        - "<app-name>.your.domain.tld"
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          backendRefs:
            - name: <app-name>
              port: <port>
    ```

### `externalsecret.yaml`
<!-- vale off -->
*   **Description:** Configuration for external secrets management using Bitwarden backend
<!-- vale on -->

*   **Type:** `yaml`

*   **Required:** No

*   **Example:**
    ```yaml
    apiVersion: external-secrets.io/v1
    kind: ExternalSecret
    metadata:
      name: <app-name>-credentials
      namespace: <app-name>
    spec:
      refreshInterval: 1h
      secretStoreRef:
        name: bitwarden-backend
        kind: ClusterSecretStore
      target:
        name: <app-name>-credentials
        creationPolicy: Owner
      data:
        - secretKey: <key-name>
          remoteRef:
            key: <bitwarden-secret-name>
    ```

<!-- vale off -->
Use the Bitwarden secret name rather than its ID. Names follow the `{scope}-{service-or-app}-{description}` pattern described in [Secret Management](secret-management).
<!-- vale on -->

## Optional Components

### Authentication Integration
*   **Description:** Configuration for integrating with Authentik authentication proxy

*   **Type:** `yaml`

*   **Required:** No

*   **Example:**
    ```yaml
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: <app-name>-auth
      namespace: <app-name>
    spec:
      parentRefs:
        - name: external
          namespace: gateway
      rules:
        - backendRefs:
            - name: ak-outpost-authentik-embedded-outpost
              namespace: auth
              port: 9000
    ```

### Reference Grant
*   **Description:** Enables cross-namespace routing capabilities

*   **Type:** `yaml`

*   **Required:** No (Only when cross-namespace communication is needed)

*   **Example:**
    ```yaml
    apiVersion: gateway.networking.k8s.io/v1beta1
    kind: ReferenceGrant
    metadata:
      name: allow-<source>-to-<target>
      namespace: <target-namespace>
    spec:
      from:
        - group: gateway.networking.k8s.io
          kind: HTTPRoute
          namespace: <source-namespace>
      to:
        - group: ""
          kind: Service
          name: <target-service>
    ```

### Database Integration
*   **Description:** PostgreSQL database configuration using CloudNativePG operator

*   **Type:** `yaml`

*   **Required:** No

*   **Example:**
    ```yaml
    apiVersion: postgresql.cnpg.io/v1
    kind: Cluster
    metadata:
      name: <app-name>-db
      namespace: <app-name>
      labels:
        recurring-job.longhorn.io/source: enabled
        recurring-job-group.longhorn.io/gfs: enabled
    spec:
      instances: 1
      imageName: ghcr.io/cloudnative-pg/postgresql:18
      storage:
        size: 10Gi
        storageClass: proxmox-csi
      bootstrap:
        initdb:
          database: <database-name>
          owner: <owner>
      resources:
        requests:
          cpu: 200m
          memory: 256Mi
        limits:
          cpu: 500m
          memory: 512Mi
    ```

CloudNativePG automatically creates a secret named `<cluster-name>-app` containing connection credentials. Applications should reference this secret directly for database credentials.

### ConfigMap Generator
*   **Description:** Generates ConfigMaps for application configuration

*   **Type:** `yaml`

*   **Required:** No

*   **Example:**
    ```yaml
    configMapGenerator:
      - name: <app-name>-config
        literals:
          - TZ=Europe/Stockholm
          # Add other configuration
    ```
