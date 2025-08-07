---
title: 'Mastodon Deployment Notes'
---

This note summarizes the Mastodon configuration relevant for the Kubernetes manifests in `/k8s/applications/web/mastodon`.

## Database Connection

Rails connects to PgBouncer over TLS and validates the certificate. The CA comes from the `mastodon-postgresql-server` secret and is mounted into each pod:

```yaml
# k8s/applications/web/mastodon/base/kustomization.yaml
configMapGenerator:
  - name: mastodon-env
    literals:
      - DB_HOST=mastodon-postgresql-pooler
      - DB_SSLMODE=verify-ca
      - DB_SSLROOTCERT=/etc/ssl/certs/pgbouncer-ca.crt
```

## Database Migrations

The web pods no longer run migrations. A pre-install and pre-upgrade Job performs them once per rollout:

```yaml
# k8s/applications/web/mastodon/web/migrate-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  annotations:
    helm.sh/hook: pre-install,pre-upgrade
spec:
  template:
    spec:
      containers:
        - name: migrate
          image: ghcr.io/glitch-soc/mastodon:v4.4.3
          command:
            - /bin/bash
            - -c
            - bundle exec rails db:migrate
      restartPolicy: OnFailure
```

## Connection Pooling

The Postgres operator pools connections for both the primary and replica. Rails targets the pooler service, disables prepared statements, and sets the pool size to match the total Puma threads.

```yaml
# k8s/applications/web/mastodon/postgres/database.yaml
spec:
  enableConnectionPooler: true
  enableReplicaConnectionPooler: true

# k8s/applications/web/mastodon/base/kustomization.yaml
configMapGenerator:
  - name: mastodon-env
    literals:
      - PREPARED_STATEMENTS=false
      - DB_POOL=10
```

## Elasticsearch

Full-text search and hashtag discovery rely on Elasticsearch. The deployment enables it and points Rails at the internal service:

```yaml
# k8s/applications/web/mastodon/base/kustomization.yaml
configMapGenerator:
  - name: mastodon-env
    literals:
      - ES_ENABLED=true
      - ES_HOST=http://mastodon-es:9200
      - ES_PORT=9200
      - ES_PRESET=single_node_cluster
```

The pod raises `vm.max_map_count` to `262144`. Kubernetes blocks that sysctl under the `restricted` PodSecurity profile, so the namespace uses the `baseline` policy instead:

```yaml
# k8s/applications/web/mastodon/base/namespace.yaml
metadata:
  name: mastodon
  labels:
    podsecurity.kubernetes.io/enforce: baseline
    podsecurity.kubernetes.io/enforce-version: latest
```

## Read replica

Rails sends read-only queries to the standby database when these variables are present:

```yaml
# k8s/applications/web/mastodon/base/kustomization.yaml
configMapGenerator:
  - name: mastodon-env
    literals:
      - REPLICA_DB_HOST=mastodon-postgresql-repl
      - REPLICA_DB_PORT=5432
      - REPLICA_DB_NAME=mastodon
      - REPLICA_PREPARED_STATEMENTS=false
      - REPLICA_DB_TASKS=false
```

## Metrics

Prometheus metrics expose runtime information for scraping:

```yaml
# k8s/applications/web/mastodon/base/kustomization.yaml
configMapGenerator:
  - name: mastodon-env
    literals:
      - MASTODON_PROMETHEUS_EXPORTER_ENABLED=true
      - MASTODON_PROMETHEUS_EXPORTER_LOCAL=true
```

## Redis

Sidekiq queues and application cache use separate Redis databases.

```yaml
# k8s/applications/web/mastodon/base/kustomization.yaml
configMapGenerator:
  - name: mastodon-env
    literals:
      - SIDEKIQ_REDIS_URL=redis://mastodon-redis-master:6379/1
      - CACHE_REDIS_URL=redis://mastodon-redis-master:6379/2
```

## Email Configuration

Mastodon sends emails through an SMTP server. The credentials and settings come from the `mastodon-app-secrets` ExternalSecret:

```yaml
# k8s/applications/web/mastodon/externalsecret.yaml
data:
  - secretKey: SMTP_SERVER
    remoteRef: { key: app-mastodon-smtp-server }
  - secretKey: SMTP_PORT
    remoteRef: { key: app-mastodon-smtp-port }
  - secretKey: SMTP_LOGIN
    remoteRef: { key: app-mastodon-smtp-login }
  - secretKey: SMTP_PASSWORD
    remoteRef: { key: app-mastodon-smtp-password }
  - secretKey: SMTP_FROM_ADDRESS
    remoteRef: { key: app-mastodon-smtp-from-address }
```

Rails is configured to use implicit TLS on port 465 and to avoid STARTTLS:

```yaml
# k8s/applications/web/mastodon/kustomization.yaml
configMapGenerator:
  - name: mastodon-common-env
    literals:
      - SMTP_DELIVERY_METHOD=smtp
      - SMTP_AUTH_METHOD=login
      - SMTP_SSL=true
      - SMTP_TLS=false
      - SMTP_ENABLE_STARTTLS_AUTO=false
  - SMTP_ENABLE_STARTTLS=never
```

## Captcha

New accounts must solve an hCaptcha challenge. The site and secret keys come from the same `mastodon-app-secrets` ExternalSecret:

```yaml
# k8s/applications/web/mastodon/base/externalsecret.yaml
data:
  - secretKey: HCAPTCHA_SITE_KEY
    remoteRef: { key: app-mastodon-hcaptcha-site-key }
  - secretKey: HCAPTCHA_SECRET_KEY
    remoteRef: { key: app-mastodon-hcaptcha-secret-key }
```

## Media Storage

Attachments are stored on a Persistent Volume Claim named `mastodon-public-pvc`.
The claim now requests 50Gi from Longhorn:

```yaml
# k8s/applications/web/mastodon/pvc-public.yaml
spec:
  accessModes: [ "ReadWriteMany" ]
  resources:
    requests:
      storage: 50Gi
  storageClassName: longhorn
```

## Content Delivery

Media and static assets are served from `cdn.goingdark.social` through an internal Nginx proxy backed by MinIO. Mastodon trusts this host via the `EXTRA_MEDIA_HOSTS` variable; `CDN_HOST` stays unset so Rails keeps serving its own compiled assets:

```yaml
# k8s/applications/web/mastodon/base/kustomization.yaml
configMapGenerator:
  - name: mastodon-env
    literals:
      - EXTRA_MEDIA_HOSTS=https://cdn.goingdark.social
```

## Sidekiq Resources

Sidekiq processes background jobs. A larger instance benefits from more
CPU and memory:

```yaml
# k8s/applications/web/mastodon/sidekiq-deployment.yaml
resources:
  requests:
    cpu: "200m"
    memory: "512Mi"
  limits:
      cpu: "1000m"
      memory: "2Gi"
```

## Scaling

Two replicas run for web, streaming, and Sidekiq deployments.

```yaml
# k8s/applications/web/mastodon/web/web-deployment.yaml
spec:
  replicas: 2

# k8s/applications/web/mastodon/streaming/streaming-deployment.yaml
spec:
  replicas: 2

# k8s/applications/web/mastodon/sidekiq/sidekiq-deployment.yaml
spec:
  replicas: 2
```

## Container Images

This deployment uses the Glitch-soc variant of Mastodon for additional features.
All components reference the `v4.4.3` tag:

```yaml
# k8s/applications/web/mastodon/web-deployment.yaml
image: ghcr.io/glitch-soc/mastodon:v4.4.3

# k8s/applications/web/mastodon/sidekiq-deployment.yaml
image: ghcr.io/glitch-soc/mastodon:v4.4.3

# k8s/applications/web/mastodon/streaming-deployment.yaml
image: ghcr.io/glitch-soc/mastodon-streaming:v4.4.3
```

