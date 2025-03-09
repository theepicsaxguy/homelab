# Internal Reference: Kustomize Integration in ArgoCD

This document consolidates all information regarding Kustomize support in ArgoCD. It is intended for internal use by our
teams to guide how we structure our GitOps manifests and troubleshoot issues related to Kustomize rendering in ArgoCD.

---

## 1. Overview

ArgoCD natively detects and processes a `kustomization.yaml` file if found at the specified repository path. When
present, ArgoCD runs a Kustomize build (using the bundled version or a custom one as configured) to generate the
Kubernetes manifests before syncing them to the cluster. This integration allows us to use Kustomize’s full power for
overlays, patches, and metadata transformations in a GitOps workflow.

---

## 2. Supported Kustomize Features in ArgoCD

ArgoCD supports nearly all core Kustomize options. Below are the supported configuration options and features:

### 2.1 Declarative GitOps with Kustomize

- **Base and Overlay Management:**
  - Structure your repository with a base and one or more overlays. Point the ArgoCD Application’s `source.path` to the
    overlay you want to deploy.
  - When the referenced directory contains a `kustomization.yaml`, ArgoCD uses Kustomize to render all resources.

### 2.2 Kustomize Configuration Options

Within an ArgoCD Application manifest, under the `spec.source.kustomize` section, you can set:

- **namePrefix & nameSuffix:**

  - `namePrefix` adds a prefix to all resource names.
  - `nameSuffix` appends a suffix.

- **images:**

  - A list for image overrides (format: either `old=new:tag` or `image:tag`).

- **replicas:**

  - A list of replica count overrides. Each entry should specify the target resource name and the new count.

- **commonLabels:**

  - A key/value map that adds extra labels to every resource generated.

- **labelWithoutSelector (boolean):**

  - If set to `true`, common labels are applied to resource templates and selectors.
  - _Note:_ Use this when you want the same labels to be present on both the metadata and the selector fields.

- **forceCommonLabels (boolean):**

  - When enabled, ArgoCD will override any pre-existing labels with those specified in `commonLabels`.

- **commonAnnotations:**

  - A map of annotations to add to all generated resources.

- **namespace:**

  - Specifies a Kubernetes namespace. When set in the Kustomize block, it instructs Kustomize to embed this namespace
    into all rendered manifests.
  - **Important:** If both the Application’s destination namespace and `spec.source.kustomize.namespace` are provided,
    ArgoCD defers to the Kustomize namespace value.

- **forceCommonAnnotations (boolean):**

  - Similar to `forceCommonLabels`, forces the specified common annotations even if resources already have annotations.

- **commonAnnotationsEnvsubst (boolean):**

  - When enabled, performs environment variable substitution in values within `commonAnnotations`. This is useful for
    dynamic annotation values (e.g., setting the application name via `${ARGOCD_APP_NAME}`).

- **patches:**

  - A list of inline patches (JSON patch or strategic merge patch) that are merged with any patches present in the
    existing kustomization file.
  - Useful for modifying specific resource fields (e.g., changing a container port).

- **components:**

  - A list of Kustomize components that encapsulate both resources and patches. With v2.10.0 and later, components can
    be referenced directly in the Application manifest.

- **version:**
  - Optionally specify a custom Kustomize version (if additional versions are configured via the ConfigMap).

### 2.3 Build Options and Custom Kustomize Versions

- **Global Build Options:**

  - You can pass global flags to the Kustomize build command by editing the `argocd-cm` ConfigMap.
  - Example:

    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: argocd-cm
      namespace: argocd
    data:
      kustomize.buildOptions: --load-restrictor LoadRestrictionsNone
      kustomize.buildOptions.v4.4.0: --output /tmp
    ```

  - _Note:_ Changing these options might require restarting ArgoCD.

- **Custom Kustomize Versions:**

  - ArgoCD supports running multiple versions simultaneously. Bundle additional Kustomize binaries and register them by
    adding entries like:

    ```yaml
    data:
      kustomize.path.v3.5.1: /custom-tools/kustomize_3_5_1
      kustomize.path.v3.5.4: /custom-tools/kustomize_3_5_4
    ```

  - Reference the version in your Application:

    ```yaml
    kustomize:
      version: v3.5.4
    ```

  - Alternatively, the version can also be set via the ArgoCD UI (Parameters tab) or CLI.

### 2.4 Build Environment Variables

- **Standard Build Environment:**

  - Kustomize apps in ArgoCD have access to environment variables.
  - Enable variable substitution in annotations (or other fields) by setting `commonAnnotationsEnvsubst` to `true` in
    your Application manifest.
  - For example, to inject the application’s name into an annotation:

    ```yaml
    kustomize:
      commonAnnotationsEnvsubst: true
      commonAnnotations:
        app-source: ${ARGOCD_APP_NAME}
    ```

### 2.5 Kustomizing Helm Charts

- **Rendering Helm Charts with Kustomize:**
  - Kustomize supports rendering Helm charts if the `--enable-helm` flag is provided.
  - **Limitation:** This flag is not available as a per-application option in ArgoCD’s Kustomize configuration.
  - **Workarounds:**
    - **Option 1:** Create a custom Config Management Plugin for your application.
    - **Option 2:** Modify the `argocd-cm` ConfigMap globally to include `--enable-helm` in `kustomize.buildOptions`.

---

## 3. Remote Bases and Private Repositories

- **Remote Bases:**
  - If your kustomization uses a remote base (an HTTPS URL or an SSH URL), ArgoCD will use the same credentials
    configured for the Application’s repository.
  - **Limitation:** If the remote base requires different credentials, ArgoCD cannot access it because, for security,
    the Application only “knows” about its own repository.

---

## 4. Examples

Below are several examples to illustrate how to use these features within ArgoCD.

### 4.1 Basic Kustomize Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kustomize-example
spec:
  project: default
  source:
    repoURL: 'https://github.com/kubernetes-sigs/kustomize'
    targetRevision: HEAD
    path: examples/helloWorld
  destination:
    namespace: default
    server: 'https://kubernetes.default.svc'
```

_Explanation:_ If the `examples/helloWorld` directory contains a `kustomization.yaml`, ArgoCD renders the manifests
using Kustomize.

### 4.2 Application with Kustomize Overrides and Patches

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kustomize-inline-guestbook
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  destination:
    namespace: test1
    server: https://kubernetes.default.svc
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: master
    path: kustomize-guestbook
    kustomize:
      patches:
        - target:
            kind: Deployment
            name: guestbook-ui
          patch: |-
            - op: replace
              path: /spec/template/spec/containers/0/ports/0/containerPort
              value: 443
```

_Explanation:_ This Application uses inline patches via the `kustomize.patches` option. It patches the `guestbook-ui`
Deployment to use port 443.

### 4.3 Application Using Kustomize Components

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: application-kustomize-components
spec:
  project: default
  source:
    repoURL: https://github.com/my-user/my-repo
    targetRevision: main
    path: examples/application-kustomize-components/base
    kustomize:
      components:
        - ../component # Path is relative to the kustomization.yaml in source.path
  destination:
    namespace: prod
    server: 'https://kubernetes.default.svc'
```

_Explanation:_ This Application references a Kustomize component that encapsulates reusable resources and patches.

### 4.4 Specifying Namespace via Kustomize

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook-app
  namespace: argocd
spec:
  project: default
  destination:
    namespace: demo
    server: https://kubernetes.default.svc
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps
    targetRevision: HEAD
    path: kustomize-guestbook
    kustomize:
      namespace: demo # This ensures resources get the demo namespace, even if not set in the manifests.
      commonAnnotationsEnvsubst: true
      commonAnnotations:
        app-source: ${ARGOCD_APP_NAME}
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
```

_Explanation:_ Setting `kustomize.namespace` forces Kustomize to set the namespace for all resources. If both the
Application’s destination and the kustomize namespace are set, ArgoCD uses the latter.

### 4.5 Configuring Global Build Options and Custom Versions

_Global Build Options in argocd-cm:_

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  kustomize.buildOptions: --load-restrictor LoadRestrictionsNone
  kustomize.buildOptions.v4.4.0: --output /tmp
```

_Registering Custom Kustomize Versions:_

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  kustomize.path.v3.5.1: /custom-tools/kustomize_3_5_1
  kustomize.path.v3.5.4: /custom-tools/kustomize_3_5_4
```

_Referencing a Custom Version in an Application:_

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: kustomize-guestbook
    kustomize:
      version: v3.5.4
  destination:
    namespace: default
    server: 'https://kubernetes.default.svc'
```

_Explanation:_ These examples show how to set global build options and register custom Kustomize versions so you can
reference them on a per-application basis.

### 4.6 Kustomizing Helm Charts with Kustomize

Since rendering Helm charts with Kustomize requires the `--enable-helm` flag:

_Global Option to Enable Helm Rendering:_

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  kustomize.buildOptions: --enable-helm
```

_Explanation:_ After updating the ConfigMap, restart ArgoCD so that all Kustomize applications will render Helm charts
using Kustomize. Alternatively, consider a custom plugin if you require per-app control.

---

## 5. Limitations and Workarounds

- **Helm Rendering Flag:** The `--enable-helm` flag cannot be set per-application—it must be configured globally in the
  `argocd-cm` ConfigMap. _Workaround:_ Use a custom plugin if per-app customization is needed.

- **Custom Kustomize Plugins:** Arbitrary custom Kustomize plugins are not supported within ArgoCD. _Recommendation:_
  Use a Config Management Plugin (CMP) if extended functionality is required.

- **Remote Bases with Different Credentials:** ArgoCD uses the Application’s repository credentials for remote bases. If
  your remote base requires different credentials, it will not be accessible. _Recommendation:_ Consolidate your
  credentials or rework the repository structure so that all bases share the same authentication.

- **Per-Application Build Options:** Custom build flags cannot be passed on a per-Application basis; they are global via
  the ConfigMap.

---

## 6. Tips and Best Practices

- **Centralize Shared Metadata:** Consider creating a common overlay that holds shared labels and annotations. Reference
  this overlay from your environment-specific overlays to avoid duplication.

- **Ignore Extraneous Resources:** When generating resources (e.g., with plugins or automated generators), learn how to
  use the IgnoreExtraneous compare option to prevent spurious diffs.

- **Validate Locally:** Before syncing to your cluster, use `kustomize build` locally (with the same flags as ArgoCD) to
  validate your changes.

- **Document Overrides:** When using inline patches or component-based configurations, document the intended changes in
  your repository to simplify troubleshooting.

- **Monitor ConfigMap Changes:** Remember that modifications to the `argocd-cm` ConfigMap (such as adding new build
  options or custom Kustomize versions) may require an ArgoCD restart.

---

## 7. Conclusion

ArgoCD’s built-in support for Kustomize allows us to leverage advanced declarative configuration techniques—from
overlays and metadata injections to inline patches and custom build options. Understanding both the full range of
supported options and the current limitations ensures that our GitOps workflows remain robust, secure, and easy to
maintain.

For any further clarifications or updates, refer to the official ArgoCD documentation or consult the internal GitOps
team.
