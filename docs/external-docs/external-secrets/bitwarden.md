# Bitwarden Secrets Manager Documentation

This documentation explains how to set up and use the **Bitwarden Secrets Manager Provider** with the **External Secrets
Operator (ESO)** to securely manage and fetch secrets at scale.

## Overview

Bitwarden Secrets Manager allows developers, DevOps, and cybersecurity teams to centrally store, manage, and deploy
secrets securely. This is different from the **Bitwarden Password Manager**. This guide focuses on the integration with
**Bitwarden Secrets Manager** using the **External Secrets Operator (ESO)**, which facilitates retrieving and managing
secrets within a Kubernetes environment.

### Prerequisites

To use the Bitwarden Secrets Manager provider with ESO, you need a separate service called the **Bitwarden SDK Server**.
The Bitwarden SDK is written in Rust and requires CGO to be enabled. A wrapper around the SDK has been created to run as
a separate service, providing ESO with a REST API to fetch secrets.

### Bitwarden SDK Server Installation

The **Bitwarden SDK Server** must be installed and run as an HTTPS service to facilitate communication with ESO.

To install the SDK server along with ESO, use the following Helm command:

```bash
helm install external-secrets \
   external-secrets/external-secrets \
   -n external-secrets \
   --create-namespace \
   --set bitwarden-sdk-server.enabled=true
```

### Certificate Setup

As the Bitwarden SDK Server needs to be accessed over HTTPS, you must configure a certificate for secure communication.
The recommended approach is to use **cert-manager** to generate the required certificate. A sample setup can be found in
the Bitwarden SDK server's test setup, which includes a self-signed certificate issuer for cert-manager.

## Secret Store Setup

Once the Bitwarden SDK Server is running, you can configure the **SecretStore** resource in Kubernetes to store secrets
securely. Below is an example of the configuration for the **SecretStore** resource.

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: bitwarden-secretsmanager
spec:
  provider:
    bitwardensecretsmanager:
      apiURL: https://api.bitwarden.com
      identityURL: https://identity.bitwarden.com
      auth:
        secretRef:
          credentials:
            key: token
            name: bitwarden-access-token
      bitwardenServerSDKURL: https://bitwarden-sdk-server.external-secrets.svc.kube.pc-tips.se:9998
      caBundle: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t...
      organizationID: 7c0d21ec-10d9-4972-bdf8-ec52df99cc86
      projectID: 9c713cd6-728c-437a-a783-252b0773a0bb
```

### Important Notes:

- The **organizationID** and **projectID** are required to scope the secrets to a specific project and organization.
- Ensure that the machine account has **Read-Write** access to the project containing the secrets.
- The **SecretStore** resource is organization and project-dependent, meaning each store is tied to a single
  organization/project.

## External Secret Retrieval Methods

You can fetch secrets from Bitwarden using two methods: **by UUID** or **by Name**.

### Fetch Secret by UUID

To retrieve a secret by its UUID, you simply provide the UUID as the remote key in the `ExternalSecret` resource:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: bitwarden
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: bitwarden-secretsmanager
    kind: SecretStore
  data:
    - secretKey: test
      remoteRef:
        key: '339062b8-a5a1-4303-bf1d-b1920146a622'
```

### Fetch Secret by Name

When retrieving a secret by its name, additional information is required, including the **projectID** and
**organizationID** to properly scope the secret lookup. The rules for finding a secret by name are as follows:

1. If the name is a UUID, the secret is returned.
2. If the name is not a UUID, the **projectID** and **organizationID** must be provided.
3. If more than one secret exists for the same projectID within the same organization, an error will be thrown.

Here is an example of how to fetch a secret by name:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: bitwarden
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: bitwarden-secretsmanager
    kind: SecretStore
  data:
    - secretKey: test
      remoteRef:
        key: 'secret-name'
```

## Pushing Secrets to Bitwarden

You can also push secrets to Bitwarden using the **PushSecret** resource. This allows you to create or update secrets in
Bitwarden. When pushing a secret, the following rules apply to prevent accidental overwriting:

1. If the **name**, **projectID**, **organizationID**, and **value (including the note)** match, the secret will not be
   pushed again.
2. If only the **value** (including the note) differs, the secret will be updated.
3. If any other fields differ, a new secret will be created, possibly in a different project.

Below is an example of how to push a secret:

```yaml
apiVersion: external-secrets.io/v1alpha1
kind: PushSecret
metadata:
  name: pushsecret-bitwarden
spec:
  refreshInterval: 1h
  secretStoreRefs:
    - name: bitwarden-secretsmanager
      kind: SecretStore
  selector:
    secret:
      name: my-secret
  data:
    - match:
        secretKey: key
        remoteRef:
          remoteKey: remote-key-name
      metadata:
        note: 'Note of the secret to add.'
```

### Important Notes:

- Ensure that the **name**, **projectID**, **organizationID**, and **value** are properly scoped to prevent conflicts or
  overwriting.
- Use the **PushSecret** resource to manage secrets that need to be created, updated, or pushed to Bitwarden.

## Conclusion

This guide covers the integration of Bitwarden Secrets Manager with the **External Secrets Operator (ESO)** to securely
manage and fetch secrets in Kubernetes. By following the provided examples, you can configure the **Bitwarden Secrets
Manager** provider, set up secret stores, retrieve secrets by UUID or name, and push secrets to Bitwarden with proper
access control.
