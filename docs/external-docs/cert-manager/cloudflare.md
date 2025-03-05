# Cloudflare Cert Manager Issuer Documentation

This document explains how to configure Cert-Manager with Cloudflare as the DNS provider for ACME DNS-01 challenges
using Cloudflare's API Tokens or API Keys.

## Overview

Cert-Manager supports integration with Cloudflare for automatic DNS management, enabling you to use Cloudflare to solve
ACME DNS-01 challenges. You can authenticate Cert-Manager to Cloudflare using either **API Tokens** (recommended for
higher security) or **API Keys**.

### Security Recommendation

- **API Tokens**: More secure, as they provide application-scoped keys bound to specific zones and permissions. They are
  also easily revocable.
- **API Keys**: Globally-scoped keys that carry the same permissions as your Cloudflare account.

**API Tokens** are recommended for higher security.

## Using API Tokens

### Creating an API Token

1. Navigate to **User Profile > API Tokens > API Tokens** in the Cloudflare dashboard.
2. Click on **Create Token** and configure the following settings:
   - **Permissions**:
     - Zone - DNS - Edit
     - Zone - Zone - Read
   - **Zone Resources**: Include **All Zones**

### Creating the Kubernetes Secret

After creating your API Token, you will need to store it securely in Kubernetes as a secret.

Create a secret with the following manifest:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token-secret
type: Opaque
stringData:
  api-token: <API Token>
```

### Issuer Manifest

Next, create an Issuer using the stored API Token in the secret. The Issuer manifest should look like this:

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: example-issuer
spec:
  acme:
    ...
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token
```

## Using API Keys

### Retrieving the API Key

1. Navigate to **User Profile > API Tokens > API Keys > Global API Key > View** in the Cloudflare dashboard.

### Creating the Kubernetes Secret

Store your API Key in Kubernetes as a secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-key-secret
type: Opaque
stringData:
  api-key: <API Key>
```

### Issuer Manifest

Create the Issuer using the stored API Key in the secret. The Issuer manifest should look like this:

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: example-issuer
spec:
  acme:
    ...
    solvers:
    - dns01:
        cloudflare:
          email: my-cloudflare-acc@example.com
          apiKeySecretRef:
            name: cloudflare-api-key-secret
            key: api-key
```

## Troubleshooting

### Error: **Actor com.cloudflare.api.token.xxxx requires permission com.cloudflare.api.account.zone.list to list zones**

This error occurs if the token lacks the **Zone - Zone - Read** permission, or if there is an issue with DNS resolution
that causes Cert-Manager to identify the wrong zone.

#### Solution

1. Ensure your token includes the **Zone - Zone - Read** permission.
2. Check for DNS issues that might cause Cert-Manager to misidentify the zone.

If the second issue occurs, you may see an error like this:

```
Events:
  Type     Reason        Age              From          Message
  ----     ------        ----             ----          -------
  Normal   Started       6s               cert-manager  Challenge scheduled for processing
  Warning  PresentError  3s (x2 over 3s)  cert-manager  Error presenting challenge: Cloudflare API Error for GET "/zones?name=<TLD>"
            Error: 0: Actor 'com.cloudflare.api.token.xxxx' requires permission 'com.cloudflare.api.account.zone.list' to list zones
```

**Recommendation**: Change your DNS01 self-check nameservers.

### Error: **Cloudflare API error for POST "/zones/<id>/dns_records" - generic error**

This error may occur when Cloudflare blocks DNS record updates for certain top-level domains (TLDs), including `.cf`,
`.ga`, `.gq`, `.ml`, and `.tk`.

#### Solution

Cloudflare restricts API updates for these TLDs. We recommend using an alternative DNS provider for these domains.

## Conclusion

This guide provided step-by-step instructions on how to configure Cloudflare as a DNS provider for Cert-Manager, using
either API Tokens or API Keys. Make sure to follow the security recommendations and troubleshoot any issues following
the provided solutions.
