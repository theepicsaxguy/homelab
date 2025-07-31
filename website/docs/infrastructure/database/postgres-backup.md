---
sidebar_position: 1
title: PostgreSQL Backups
description: Logical backups using the Zalando operator and Minio storage
---

# PostgreSQL Operator Backup Configuration

The Zalando Postgres operator schedules `pg_dumpall` to run via a Kubernetes CronJob. Backups write to the `postgres` bucket on the cluster's Minio instance.

Credentials come from the `ExternalSecret` named `longhorn-minio-credentials`. This secret is shared with Longhorn so the same Minio user manages all backups.

The default schedule stores a dump every night at 03:00 UTC. Adjust `logical_backup_schedule` in `values.yaml` if needed.
