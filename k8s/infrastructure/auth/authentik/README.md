# Authentik Proxy Outpost for Kubernetes

## Why this setup?

- **Single point of authentication**: One Outpost handles auth for multiple internal apps.
- **Simplified management**: Add new protected apps without deploying additional components.
- **Consistent security**: All apps use the same authentication flow and policies.

## What this does

This deploys an Authentik Proxy Outpost as a central authentication proxy for our Kubernetes cluster. It:

1. Runs as a Deployment with an associated Service.
2. Integrates with our Gateway API setup for routing.
3. Authenticates users before allowing access to protected apps.

## Adding a new protected app

1. **In Authentik UI**:
   - Create a new Proxy Provider
   - Set External Host (e.g., `app.domain.com`)
   - Set internal Upstream URL (e.g., `http://internal-service:8080`)
   - Create an Application using this Provider

2. **Add an HTTPRoute**:
   ```yaml
   apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: my-new-app
     namespace: apps
   spec:
     parentRefs:
       - name: internal
         namespace: gateway
     hostnames:
       - "app.domain.com"
     rules:
       - matches:
           - path:
               type: PathPrefix
               value: /
         backendRefs:
           - name: authentik-outpost
             port: 9000
   ```

3. **Ensure internal app isn't directly exposed**:
   - Remove any existing Ingress/HTTPRoute for the app
   - Keep the app's Service internal (ClusterIP)

## Why this works

- All external traffic to `app.domain.com` goes through the Outpost
- Outpost handles auth, then proxies to the internal service
- Internal services remain unexposed, adding security

## Maintenance notes

- Update the Outpost image version periodically
- Token in `authentik-outpost-api` Secret may need rotation (check Authentik docs for best practices)
