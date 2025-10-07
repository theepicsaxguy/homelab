---
title: 'Immich Deployment Notes'
---

This guide summarizes key configuration details for running Immich with GitOps.

## Prerequisites

* Kubernetes cluster with the Zalando Postgres Operator (`acid.zalan.do/v1`) installed
* `immich` namespace created
* External Secrets Operator available
* Helm CLI and `kubectl` configured

## Configuration Overview

### PostgreSQL Extensions

Ensure the Immich database includes the `pgvector` and `vectorchord` extensions:

```yaml
# k8s/applications/media/immich/database.yaml
spec:
  preparedDatabases:
    immich:
      extensions:
        pgvector: public
        vectorchord: public
```

<!-- vale off -->
### Templated DB_URL
The application expects a single `DB_URL`. Use ExternalSecrets to assemble the connection string:

```yaml
# k8s/applications/media/immich/externalsecret.yaml
template:
  data:
    DB_URL: >-
      postgres://immich:{{ .password }}@immich-postgresql:5432/immich?sslmode=require&sslmode=no-verify
```

<!-- vale on -->

### External Secrets Permissions

Reference the cluster CA and grant read access to the Zalando secret:

1. `zalando-k8s-store.yaml` references `kube-root-ca.crt`.
2. `serviceaccount.yaml` grants `get`, `list`, and `watch` on secrets as well as `selfsubjectrulesreviews`.

### Kustomization Layout

Use a root `kustomization.yaml` to track all resources:

```yaml
resources:
  - namespace.yaml
  - http-route.yaml
  - externalsecret.yaml
  - database.yaml
  - pvc.yaml
  - zalando-k8s-store.yaml
  - serviceaccount.yaml
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
      storageClassName: longhorn
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 50Gi
```

### Backups

Database backups use MinIO credentials from an ExternalSecret:

```yaml
# k8s/applications/media/immich/immich-server/minio-externalsecret.yaml
spec:
  target:
    name: longhorn-minio-credentials
```
