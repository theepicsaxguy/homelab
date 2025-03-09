**# Namespace Management in Kustomize Using a Component**

## Overview

This documentation outlines an efficient way to manage Kubernetes namespaces dynamically in Kustomize using a
centralized component (`namespace-manager`). This approach eliminates the need to hardcode namespaces in application
configurations while allowing environment-specific overrides.

## Folder Structure

```
common/
  └── components/
      └── namespace-manager/
          ├── kustomization.yaml
          └── namespace.yaml

apps/
  ├── app1/
  │   ├── kustomization.yaml
  │   ├── deployment.yaml
  │   ├── service.yaml

overlays/
  ├── dev/
  │   ├── kustomization.yaml
  ├── prod/
      ├── kustomization.yaml
```

## Creating the Namespace Component

### **1. Define the Namespace Resource**

Create a **namespace.yaml** file under `common/components/namespace-manager/`.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: placeholder-namespace
```

### **2. Define the Kustomization File for the Component**

Create `kustomization.yaml` under `common/components/namespace-manager/`.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
```

## Referencing the Namespace Component in Overlays

Each overlay (`dev`, `prod`) should reference the `namespace-manager` component and specify its namespace dynamically.

### **Example: `overlays/dev/kustomization.yaml`**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
components:
  - ../../common/components/namespace-manager
namespace: dev-namespace
resources:
  - ../../apps/app1
```

### **Example: `overlays/prod/kustomization.yaml`**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
components:
  - ../../common/components/namespace-manager
namespace: prod-namespace
resources:
  - ../../apps/app1
```

## Application Configuration Without Hardcoded Namespace

Ensure application manifests do **not** define a namespace, allowing overlays to assign them dynamically.

### **Example: `apps/app1/deployment.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
  labels:
    app: app1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
        - name: app1-container
          image: app1-image:latest
```

## Benefits

✅ **No hardcoded namespaces** – Apps remain portable across environments. ✅ **Fully dynamic** – Overlays set the
namespace without modifying application manifests. ✅ **Simplifies management** – The `namespace-manager` component
centralizes namespace handling. ✅ **GitOps-friendly** – Works seamlessly with ArgoCD and other GitOps workflows.

## Notes

- Ensure that the `namespace-manager` component is applied first, so the namespace exists before deploying resources
  into it.
- This approach works well for multiple applications and scales efficiently across environments.
