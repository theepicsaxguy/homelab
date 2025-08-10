---
title: 'Elasticsearch resources'
---

The search cluster needs more memory than the chart's preset. The master node requests 768Mi, caps at 1.5 GiB, and uses a 512m heap.

```yaml
# k8s/applications/web/mastodon/elasticsearch/values.yaml
master:
  resources:
    requests:
      memory: 768Mi
    limits:
      memory: 1.5Gi
  heapSize: 512m
  resourcesPreset: none
```
