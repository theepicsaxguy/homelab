---
title: 'Additional Documentation: Immich GitOps Issue Fixes'
---

A concise guide to the principal deployment problems we encountered when rolling out Immich with GitOps—what failed, why it failed, and exactly how we remedied each case.

## About This Guide

This document highlights the four critical issues that blocked a smooth Immich deployment: missing vector extensions, improper `DB_URL` assembly, ExternalSecrets authentication errors, and resource grouping. For each, it explains the root cause and the minimal changes required.

## Prerequisites

* Kubernetes cluster with the Zalando Postgres Operator (`acid.zalan.do/v1`) installed
* `immich` namespace already created
* External Secrets Operator deployed and ready
* Helm CLI and `kubectl` configured

## Overview of Issues & Resolutions

1. **PostgreSQL Extensions Missing** → Operator CRD misconfigured (pgvector & vectorchord)
2. **DB\_URL Secret Fragmentation** → Immich requires a single URI
3. **ExternalSecret Authentication Failures** → Missing CA & RBAC
4. **Resource Organization** → Inconsistent manifests

---

## 1. PostgreSQL: Vector Extensions Not Loaded

**Why it failed:**
By default, the Zalando operator won't install `pgvector` and `vectorchord` unless they're explicitly declared in the CRD's `preparedDatabases` block.

**How we fixed it:**
In `database.yaml`, specify each extension under `spec.preparedDatabases` so the operator creates them at startup:

```yaml
# k8s/applications/media/immich/immich-server/database.yaml
spec:
  numberOfInstances: 2
  preparedDatabases:
    immich:
      extensions:
        pgvector: public
        vectorchord: public
```

This setup runs two database pods for basic failover. It still relies on shared storage and isn't a multi-region solution, but it avoids a single point of failure in normal operations.

---

## 2. Templating a Single DB\_URL Secret

**Why it failed:**
Zalando splits credentials into separate secrets (`username`, `password`, etc.), but Immich only reads a single `DB_URL`.

**How we fixed it:**
Use ExternalSecrets to stitch the parts into one line in `externalsecret.yaml`:

```yaml
# k8s/applications/media/immich/externalsecret.yaml
template:
  data:
    DB_URL: >-
      postgres://immich:{{ .password }}@immich-postgresql:5432/immich?sslmode=require&sslmode=no-verify
```

---

## 3. SecretStore: CA Bundle & RBAC

**Why it failed:**
ESO couldn’t validate the Kubernetes API server’s certificate (no CA) and lacked permission to read the Zalando secret.

**How we fixed it:**

1. **SecretStore** (`zalando-k8s-store.yaml`): reference the cluster CA from the `kube-root-ca.crt` ConfigMap.
2. **ServiceAccount & RBAC** (`serviceaccount.yaml`): grant `get`, `list`, `watch` on `secrets` plus `selfsubjectrulesreviews`.

---

## 4. Consolidating Manifests with Kustomize

**Why it failed:**
Resources were scattered, making it hard to apply a single GitOps commit.

**How we fixed it:**
Use a top-level `kustomization.yaml` to list:

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
