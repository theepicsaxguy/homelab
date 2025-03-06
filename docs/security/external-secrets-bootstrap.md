# External Secrets Operator Bootstrap

## Overview

This document describes the bootstrap process for External Secrets Operator (ESO) with Bitwarden Secrets Manager integration. ESO is deployed via ArgoCD following GitOps principles, but the initial bootstrap requires some specific steps to handle certificate dependencies correctly.

## Prerequisites

- ArgoCD is deployed and functioning
- cert-manager is installed and running properly
- Bitwarden Secrets Manager account with proper access

## Bootstrap Process

### 1. Setting up the Certificate Resources

The Bitwarden SDK Server requires TLS certificates to operate securely. These certificates must be provided in a specific format with three components:

- `tls.crt` - The server certificate
- `tls.key` - The private key
- `ca.crt` - The CA certificate

The certificate is defined in `k8s/infrastructure/base/controllers/external-secrets/bitwarden-cert.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: bitwarden-sdk-cert
  namespace: external-secrets
spec:
  secretName: bitwarden-tls-certs
  duration: 8760h # 1 year
  renewBefore: 720h # 30 days
  subject:
    organizations:
      - homelab
  isCA: false
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  usages:
    - server auth
    - client auth
  dnsNames:
    - bitwarden-sdk-server.external-secrets.svc.cluster.local
  issuerRef:
    name: selfsigned-issuer
    kind: Issuer
```

### 2. Setting up the Self-Signed Issuer

The `selfsigned-issuer` is defined in `k8s/infrastructure/base/controllers/external-secrets/internal-issuer.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned-issuer
  namespace: external-secrets
spec:
  selfSigned: {}
```

### 3. Bootstrap Order

To avoid the "chicken and egg" problem with certificates, ensure components are installed in this order:

1. Deploy cert-manager (usually an early infrastructure component)
2. Deploy the self-signed issuer
3. Deploy the certificate resource
4. Deploy the External Secrets Operator with Bitwarden SDK Server

### 4. Troubleshooting Certificate Issues

If the bootstrap fails with error `MountVolume.SetUp failed for volume "bitwarden-tls-certs"`, check:

1. Verify the cert-manager components are running correctly:
   ```bash
   kubectl get pods -n cert-manager
   ```

2. Check if the Certificate resource is properly configured:
   ```bash
   kubectl describe certificate bitwarden-sdk-cert -n external-secrets
   ```

3. Verify if the certificate issuer is ready:
   ```bash
   kubectl get issuer -n external-secrets selfsigned-issuer -o yaml
   ```

4. Check certificate requests status:
   ```bash
   kubectl get certificaterequests -n external-secrets
   ```

5. If cert-manager is having webhook certificate verification issues, restart the webhook pod:
   ```bash
   kubectl -n cert-manager delete pod -l app=webhook
   ```

### 5. Configuring Bitwarden Secret Store

After certificates are properly issued, configure the SecretStore to connect to Bitwarden:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: bitwarden-secretsmanager
  namespace: external-secrets
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
      bitwardenServerSDKURL: https://bitwarden-sdk-server.external-secrets.svc.cluster.local:9998
      caProvider:
        type: Secret
        name: bitwarden-sdk-ca
        key: tls.crt
      organizationID: YOUR_ORGANIZATION_ID
      projectID: YOUR_PROJECT_ID
```

### 6. Verifying the Setup

Once all components are deployed, verify that the Bitwarden SDK Server is running:

```bash
kubectl get pods -n external-secrets -l app.kubernetes.io/name=bitwarden-sdk-server
```

And test that External Secrets can access Bitwarden:

```bash
kubectl create -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: test-external-secret
  namespace: external-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: bitwarden-secretsmanager
    kind: SecretStore
  target:
    name: test-secret
    creationPolicy: Owner
  data:
    - secretKey: test-key
      remoteRef:
        key: YOUR_TEST_SECRET_UUID
EOF
```

## Important Notes

- Never manually create secrets or bypass ArgoCD for production deployments
- Always ensure certificate resources are properly defined in Git
- This bootstrap process is only needed for initial setup; ArgoCD will manage all subsequent updates
- If cert-manager has issues with webhook TLS verification, restarting the webhook pod may help resolve them

## Related Documentation

- [Bitwarden Secrets Manager Documentation](../external-docs/external-secrets/bitwarden.md)
- [Secrets Management](./secrets-management.md)