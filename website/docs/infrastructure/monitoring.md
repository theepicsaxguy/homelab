---
sidebar_position: 3
title: Monitoring Stack
description: Deploying kube-prometheus-stack with CRDs managed via server-side apply
---

# Monitoring Stack

The observability stack relies on the kube-prometheus-stack Helm chart. This chart ships large CRD definitions which can
exceed Kubernetes' 256 KB annotation limit when applied with the default client-side method.

To avoid sync errors in Argo CD:

1. The CRDs are installed through a dedicated `crds` kustomization that references the upstream YAML files.
2. The Helm release is configured with `includeCRDs: false` and the Argo CD Application sets `skipCrds: true`.
3. The Application uses `ServerSideApply` so Argo CD no longer adds the `last-applied-configuration` annotation.

This approach keeps the deployment idempotent and avoids manual patching of CRDs.
