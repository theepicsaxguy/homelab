---
title: 'Home Assistant'

---

Home Assistant provides local control and privacy. This open source home automation platform runs on your own hardware.

## Important considerations

- **Pod Security Context:** The container now uses `NET_ADMIN`, `NET_RAW`, and `NET_BROADCAST` capabilities so Home Assistant can discover devices on the local network.

## Authentication

Home Assistant authenticates through Authentik with OpenID Connect. Bitwarden supplies credentials, and the Authentik blueprint defines the provider. The login page now displays a "Login with OpenID / OAuth 2.0" option.
