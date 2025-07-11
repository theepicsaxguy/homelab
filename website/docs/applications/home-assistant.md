---
title: 'Home Assistant'

---

Home Assistant is an open-source home automation platform that focuses on local control and privacy.

## Important considerations

- **Pod Security Context:** The container now adds `NET_ADMIN`, `NET_RAW`, and `NET_BROADCAST` so Home Assistant can discover devices on the local network.

## Authentication

Home Assistant authenticates via Authentik using OpenID Connect. Credentials are
pulled from Bitwarden and a provider is defined in the Authentik blueprints. The
login page now shows a "Login with OpenID / OAuth2" option.
