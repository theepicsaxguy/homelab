---
title: 'Immich Deployment Notes'
---

This guide summarizes key configuration details for running Immich with GitOps.

## Prerequisites

* Kubernetes cluster with the CloudNativePG operator (`postgresql.cnpg.io/v1`) installed
* `immich` namespace created
* External Secrets Operator available
* Helm CLI and `kubectl` configured

## Configuration Overview

### PostgreSQL with VectorChord Extension

The Immich database uses CloudNativePG with a custom image that includes vector extensions:

```yaml
# k8s/applications/media/immich/immich-server/database.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: immich-postgresql
  namespace: immich
spec:
  instances: 2
  imageName: ghcr.io/tensorchord/cloudnative-vectorchord:17.7
  bootstrap:
    initdb:
      database: immich
      owner: immich
      postInitApplicationSQL:
        - CREATE EXTENSION IF NOT EXISTS "vector";
        - CREATE EXTENSION IF NOT EXISTS "earthdistance" CASCADE;
```

### Database Connection

<!-- vale off -->
CloudNativePG automatically generates the `immich-postgresql-app` secret containing all connection details. The StatefulSet references this secret directly:

```yaml
# k8s/applications/media/immich/immich-server/statefulset.yaml
env:
  - name: DB_DATABASE_NAME
    value: immich
  - name: DB_HOSTNAME
    value: immich-postgresql-rw
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        key: password
        name: immich-postgresql-app
  - name: DB_URL
    valueFrom:
      secretKeyRef:
        key: uri
        name: immich-postgresql-app
  - name: DB_USERNAME
    valueFrom:
      secretKeyRef:
        key: username
        name: immich-postgresql-app
```
<!-- vale on -->

### Kustomization Layout

Use a root `kustomization.yaml` to track all resources:

```yaml
resources:
  - immich-config-external-secret.yaml
  - minio-externalsecret.yaml
  - database.yaml
  - database-scheduled-backup.yaml
  - podmonitor.yaml
  - serviceaccount.yaml
  - service.yaml
  - servicemonitor.yaml
  - statefulset.yaml
```

### OAuth Configuration via ExternalSecret

Immich expects the OAuth client details inside its config file. The `immich-config-external-secret.yaml` resource pulls these values from Bitwarden and renders the full configuration as a Secret:

```yaml
# k8s/applications/media/immich/immich-server/immich-config-external-secret.yaml
spec:
  template:
    data:
        immich-config.yaml: |
          ...
          server:
            externalDomain: https://photo.pc-tips.se
          oauth:
            enabled: true
            issuerUrl: "https://sso.pc-tips.se/application/o/immich/"
            scope: "openid email profile"
            autoLaunch: true
            autoRegister: true
            buttonText: "Login with SSO"
            clientId: "{{ .clientId }}"
            clientSecret: "{{ .clientSecret }}"
          passwordLogin:
            enabled: false
```

This Secret is mounted by the StatefulSet at `/config/immich-config.yaml`, allowing the application to start without additional environment variables.
The machine learning deployment mounts the same Secret so both components read identical settings.

### Resource Requests

Both pods need enough memory to process photos without crashing. A good starting point is:

| Component | CPU Request | Memory Request | CPU Limit | Memory Limit |
| --------- | ----------- | -------------- | --------- | ------------ |
| immich-server | 500m | 512Mi | 2000m | 2Gi |
| immich-machine-learning | 200m | 1Gi | 1000m | 4Gi |

### Library Storage

Immich stores uploaded files on a Persistent Volume Claim named `library`. The claim
requests 50Gi from Longhorn:

```yaml
# k8s/applications/media/immich/immich-server/statefulset.yaml
spec:
  volumeClaimTemplates:
  - metadata:
      name: library
    spec:
      storageClassName: proxmox-csi
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 50Gi
```

### Backups

Database backups use MinIO credentials from an ExternalSecret and are configured through CloudNativePG's native backup integration:

```yaml
# k8s/applications/media/immich/immich-server/database.yaml
plugins:
- name: barman-cloud.cloudnative-pg.io
  isWALArchiver: true
  parameters:
    barmanObjectName: immich-minio-store
```

Scheduled backups are configured via `database-scheduled-backup.yaml` using the ScheduledBackup CRD.
