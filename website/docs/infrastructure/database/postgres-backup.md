---
sidebar_position: 1
title: PostgreSQL Backups
description: Logical backups using the Zalando operator and Minio storage
---

# Postgres operator backup configuration

The Zalando Postgres operator schedules `pg_dumpall` with a Kubernetes CronJob. Backups write to the `postgres` bucket on the cluster's Minio instance.

The `longhorn-minio-credentials` ExternalSecret supplies credentials. Longhorn uses this secret too, so one Minio user handles every backup. It must also expose `LOGICAL_BACKUP_S3_ENDPOINT` so the job points at Minio.

Set `logical_backup_s3_endpoint` in `values.yaml` to the Minio S3 endpoint URL (the value of `LOGICAL_BACKUP_S3_ENDPOINT` exposed by the `longhorn-minio-credentials` secret). The default schedule stores a dump every night at 03:00 Coordinated Universal Time. Adjust `logical_backup_schedule` if needed.
