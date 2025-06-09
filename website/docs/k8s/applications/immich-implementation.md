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

### Templated DB_URL

The application expects a single `DB_URL`. Use ExternalSecrets to assemble the connection string:

```yaml
# k8s/applications/media/immich/externalsecret.yaml
template:
  data:
    DB_URL: >-
      postgres://immich:{{ .password }}@immich-postgresql:5432/immich?sslmode=require&sslmode=no-verify
```

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
