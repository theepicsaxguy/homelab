# 🔐 ExternalSecret Wiring Plan

Use this self‑contained template to add a new ExternalSecret and wire it into a Deployment. Just replace the placeholder
variables and hand it off to your agent—no extra context needed.

---

## 1. Define Variables

- **APP**: Short app name (e.g. `openwebui`)
- **NAMESPACE**: Kubernetes namespace (e.g. `open‑webui`)
- **SECRET_NAME**: Base name for the K8s Secret (e.g. `openwebui-secret`)
- **STORE_NAME**: ClusterSecretStore name (e.g. `bitwarden-backend`)
- **REMOTE_KEY**: Remote vault key/ID (e.g. `5885ea99-3aaf-4bf7-b121-b2c40096cdcc`)
- **ENV_VAR_NAME**: Environment variable in your container (e.g. `WEBUI_SECRET_KEY`)

---

## 2. Create ExternalSecret

**File:** `k8s/applications/ai/$(APP)/$(APP)-external-secret.yaml`

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: $(SECRET_NAME)
  namespace: $(NAMESPACE)
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: $(STORE_NAME)
    kind: ClusterSecretStore
  target:
    name: $(SECRET_NAME)
    creationPolicy: Owner
  data:
    - secretKey: $(ENV_VAR_NAME) # becomes the data key in the K8s Secret
      remoteRef:
        key: $(REMOTE_KEY) # your vault’s secret identifier
```

---

## 3. Add to Kustomization

**File:** `k8s/applications/ai/$(APP)/kustomization.yaml`

```diff
 resources:
   - namespace.yaml
   - …
   - webui-pvc.yaml
+  - $(APP)-external-secret.yaml
```

---

## 4. Patch Your Deployment

**File:** `k8s/applications/ai/$(APP)/deployment.yaml`

```diff
         env:
         - name: $(ENV_VAR_NAME)
           valueFrom:
             secretKeyRef:
               name: $(SECRET_NAME)
-              key: some-other-key
+              key: $(ENV_VAR_NAME)
```

---

## 5. Verify Deployment

```bash
kubectl apply -k k8s/applications/ai/$(APP)
kubectl get secret $(SECRET_NAME) -n $(NAMESPACE) -o yaml
kubectl rollout status deployment/$(APP) -n $(NAMESPACE)
```
