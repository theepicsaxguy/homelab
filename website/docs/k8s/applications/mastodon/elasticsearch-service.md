---
title: 'Elasticsearch service'
---

The headless Service provides a stable Domain Name System (DNS) name for the search cluster. The `elasticsearch-master` Service listens on port 9200 for the Representational State Transfer (REST) API.

```yaml
# k8s/applications/web/mastodon/elasticsearch/service.yaml
metadata:
  name: elasticsearch-master
spec:
  ports:
    - port: 9200
```
