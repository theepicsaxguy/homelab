---
title: 'Home Assistant'

---

Home Assistant is an open-source home automation platform that focuses on local control and privacy.

## Important considerations

- **Pod Security Context:** The Home Assistant pod's security context has been configured to drop all capabilities and does not include `NET_RAW`. This adheres to the `baseline:latest` PodSecurity policy.
