---
sidebar_position: 2
title: CloudNativePG Operator
description: PostgreSQL operator managed through Helm with Barman integration and monitoring alerts
---

# CloudNativePG Operator deployment

The CloudNativePG operator lives in `k8s/infrastructure/database/cloudnative-pg/`. Argo CD pulls in the Helm chart with Kustomize's `helmCharts` integration, so the operator stays fully GitOps managed.

## Deployment settings

- **Namespace**: `cnpg-system`, created through `namespace.yaml`
- **Chart**: `cloudnative-pg` version `0.26.0` from `https://cloudnative-pg.github.io/charts`
- **Replica count**: set to `2` controllers for availability
- **Barman support**: the `kustomization.yaml` references the Barman cloud plugin manifest so WAL archiving works out of the box
- **In-place updates**: the `ENABLE_INSTANCE_MANAGER_INPLACE_UPDATES` environment variable is enabled for smoother rolling upgrades

## Monitoring

Prometheus rules in `rules.yaml` raise warnings for long transactions, replication lag, archiving failures, deadlocks, and other health issues. The Helm values also turn on the Grafana dashboard and PodMonitor to expose metrics automatically.

## Troubleshooting

For common issues and solutions, see the [CNPG Troubleshooting Guide](./cnpg-troubleshooting.md).
