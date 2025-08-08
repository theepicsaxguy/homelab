---
title: Mastodon Search Configuration
---

Enabling full-text search requires a running Elasticsearch instance and the appropriate Mastodon environment variables.

### Environment Variables

Set the following values in the Mastodon configuration:

```yaml
ES_ENABLED: true
ES_HOST: es.goingdark.social
ES_PORT: 9200
ES_PRESET: single_node_cluster
```

Credentials for Elasticsearch are sourced from the application secret:

```yaml
ES_USER
ES_PASS
```

### Elasticsearch Security

The bundled Elasticsearch chart enables X-Pack security and runs as a single-node cluster. Ensure credentials are created with limited permissions for Mastodon.

### Index Deployment

After configuration, deploy the search indexes:

```bash
RAILS_ENV=production bin/tootctl search deploy
```

### Checking Your Work

To validate your changes, run the following commands:

```bash
kustomize build applications/web/mastodon/
cd website/
npm run build
pre-commit run vale --all-files
```

### See also

* [Mastodon Kustomization](http://github.com/theepicsaxguy/homelab/blob/main/k8s/applications/web/mastodon/base/kustomization.yaml)
* [Elasticsearch Values](https://github.com/theepicsaxguy/homelab/blob/main/k8s/applications/web/mastodon/elasticsearch/values.yaml)
