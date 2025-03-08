# Kustomize Documentation

This documentation covers two primary areas:

1. **Kustomize in Argo CD** – How to use Kustomize declaratively with Argo CD, including inline patches, components,
   build options, custom versions, build environment, Helm charts, and namespace settings.
2. **Declarative Management of Kubernetes Objects Using Kustomize** – How to use Kustomize directly with Kubernetes (via
   kubectl) to generate, customize, and compose resources.

---

## 1. Kustomize in Argo CD

### Declarative GitOps Application Manifest

Define a Kustomize application in a declarative GitOps way using an Argo CD Application manifest. For example:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kustomize-example
spec:
  project: default
  source:
    path: examples/helloWorld
    repoURL: 'https://github.com/kubernetes-sigs/kustomize'
    targetRevision: HEAD
  destination:
    namespace: default
    server: 'https://kubernetes.default.svc'
```

If a `kustomization.yaml` file exists at the location defined by `repoURL` and `path`, Argo CD renders the manifests
using Kustomize.

#### Configuration Options for Kustomize

- **namePrefix:** Prefix appended to resources for Kustomize apps
- **nameSuffix:** Suffix appended to resources for Kustomize apps
- **images:** List of Kustomize image overrides
- **replicas:** List of Kustomize replica overrides
- **commonLabels:** A string map of additional labels
- **labelWithoutSelector:** Boolean to decide if the common labels should be applied to resource selectors and templates
- **forceCommonLabels:** Boolean to allow overriding existing labels
- **commonAnnotations:** A string map of additional annotations
- **namespace:** Kubernetes resource namespace
- **forceCommonAnnotations:** Boolean to allow overriding existing annotations
- **commonAnnotationsEnvsubst:** Boolean to enable environment variable substitution in annotation values
- **patches:** List of Kustomize patches supporting inline updates
- **components:** List of Kustomize components

_Tip:_ When generating resources, review the IgnoreExtraneous compare option to avoid including generated resources.

---

### Patches

Patches allow inline updates to resources in Argo CD applications. They follow the same logic as patches in a
`Kustomization` file.

#### Inline Patch Example with Kustomize

This example sources manifests from the `/kustomize-guestbook` folder and patches the Deployment to use port 443 on the
container:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
metadata:
  name: kustomize-inline-example
namespace: test1
resources:
  - https://github.com/argoproj/argocd-example-apps//kustomize-guestbook/
patches:
  - target:
      kind: Deployment
      name: guestbook-ui
    patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/ports/0/containerPort
        value: 443
```

The equivalent inline patch in an Argo CD Application manifest is:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kustomize-inline-guestbook
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    namespace: test1
    server: https://kubernetes.default.svc
  project: default
  source:
    path: kustomize-guestbook
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: master
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

#### Inline Patches with ApplicationSets

Inline patches can be used with ApplicationSets. For example, with external-dns to set the `txt-owner-id` to the cluster
name:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: external-dns
spec:
  goTemplate: true
  goTemplateOptions: ['missingkey=error']
  generators:
    - clusters: {}
  template:
    metadata:
      name: 'external-dns'
    spec:
      project: default
      source:
        repoURL: https://github.com/kubernetes-sigs/external-dns/
        targetRevision: v0.14.0
        path: kustomize
        kustomize:
          patches:
            - target:
                kind: Deployment
                name: external-dns
              patch: |-
                - op: add
                  path: /spec/template/spec/containers/0/args/3
                  value: --txt-owner-id={{.name}}   # patch using attribute from generator
      destination:
        name: 'in-cluster'
        namespace: default
```

---

### Components

Kustomize components encapsulate both resources and patches. They help modularize and reuse configuration.

Outside of Argo CD, reference a component by adding the following to the `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
---
components:
  - ../component
```

In Argo CD (v2.10.0 and later), you can reference a component directly:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: application-kustomize-components
spec:
  ...
  source:
    path: examples/application-kustomize-components/base
    repoURL: https://github.com/my-user/my-repo
    targetRevision: main
    kustomize:
      components:
        - ../component  # relative to the kustomization.yaml (source.path)
```

---

### Private Remote Bases

For remote bases that are HTTPS (with username/password) or SSH (with an SSH private key), the credentials are inherited
from the application’s repository. _Note:_ This only works if the remote base uses the same credentials; different
credentials are not supported for security reasons.

---

### kustomize.buildOptions

To provide build options to the `kustomize build` command, use the `kustomize.buildOptions` field in the `argocd-cm`
ConfigMap. Use version-specific options with `kustomize.buildOptions.<version>`.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-cm
    app.kubernetes.io/part-of: argocd
data:
  kustomize.buildOptions: --load-restrictor LoadRestrictionsNone
  kustomize.buildOptions.v4.4.0: --output /tmp
```

_After modifying `kustomize.buildOptions`, restart Argo CD for changes to take effect._

---

### Custom Kustomize Versions

Argo CD supports multiple Kustomize versions. To add additional versions, bundle the required versions and register them
using the `kustomize.path.<version>` field in the `argocd-cm` ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-cm
    app.kubernetes.io/part-of: argocd
data:
  kustomize.path.v3.5.1: /custom-tools/kustomize_3_5_1
  kustomize.path.v3.5.4: /custom-tools/kustomize_3_5_4
```

Then reference the desired version in your Application spec:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
spec:
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: kustomize-guestbook
    kustomize:
      version: v3.5.4
```

Or set it via the CLI:

```bash
argocd app set <appName> --kustomize-version v3.5.4
```

---

### Build Environment

Kustomize applications have access to a standard build environment that can be used with a config management plugin to
alter rendered manifests. Enable environment variable substitution by setting
`.spec.source.kustomize.commonAnnotationsEnvsubst` to `true`.

For example, this Application manifest sets the `app-source` annotation to the Application’s name:

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
    path: kustomize-guestbook
    repoURL: https://github.com/argoproj/argocd-example-apps
    targetRevision: HEAD
    kustomize:
      commonAnnotationsEnvsubst: true
      commonAnnotations:
        app-source: ${ARGOCD_APP_NAME}
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
```

---

### Kustomizing Helm Charts

Helm charts can be rendered with Kustomize by passing the `--enable-helm` flag to the `kustomize build` command. This
flag is not available as a Kustomize option in Argo CD. You have two options:

1. Create a custom plugin.
2. Modify the `argocd-cm` ConfigMap to include the flag globally:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: argocd-cm
     namespace: argocd
   data:
     kustomize.buildOptions: --enable-helm
   ```

---

### Setting the Manifests' Namespace

The `spec.destination.namespace` field adds a namespace only when it is missing from Kustomize-generated manifests.
However, it uses kubectl to set the namespace, which may miss some fields (e.g., custom resources). To resolve this, use
`spec.source.kustomize.namespace` to instruct Kustomize to set the namespace.

_Note:_ If both `spec.destination.namespace` and `spec.source.kustomize.namespace` are set, the latter takes precedence.

---

## 2. Declarative Management of Kubernetes Objects Using Kustomize

Kustomize is a tool to customize Kubernetes objects through a `kustomization.yaml` file. Since Kubernetes 1.14,
`kubectl` also supports managing objects declaratively with Kustomize.

### Using kubectl with Kustomize

- **View resources:**

  ```bash
  kubectl kustomize <kustomization_directory>
  ```

- **Apply resources:**

  ```bash
  kubectl apply -k <kustomization_directory>
  ```

### Before You Begin

- Install **kubectl**.
- Have access to a Kubernetes cluster with at least two worker nodes (non-control plane).
- Use tools like **minikube**, **Killercoda**, or **Play with Kubernetes** if you need a cluster.
- Check your version with `kubectl version`.

---

### Overview of Kustomize Features

- **Generating Resources:** Create ConfigMaps and Secrets from files, env files, or literals.
- **Setting Cross-Cutting Fields:** Apply common namespaces, prefixes/suffixes, labels, or annotations.
- **Composing and Customizing Resources:** Combine multiple resources and apply patches.

---

### Generating Resources

#### ConfigMap Generation

**From a File:**

```bash
# Create application.properties
cat <<EOF >application.properties
FOO=Bar
EOF

cat <<EOF >./kustomization.yaml
configMapGenerator:
- name: example-configmap-1
  files:
  - application.properties
EOF
```

_Generated ConfigMap:_

```yaml
apiVersion: v1
data:
  application.properties: |
    FOO=Bar
kind: ConfigMap
metadata:
  name: example-configmap-1-8mbdf7882g
```

**From an Env File:**

```bash
# Create a .env file
cat <<EOF >.env
FOO=Bar
EOF

cat <<EOF >./kustomization.yaml
configMapGenerator:
- name: example-configmap-1
  envs:
  - .env
EOF
```

_Generated ConfigMap:_

```yaml
apiVersion: v1
data:
  FOO: Bar
kind: ConfigMap
metadata:
  name: example-configmap-1-42cfbf598f
```

**From Literal Key-Value Pairs:**

```bash
cat <<EOF >./kustomization.yaml
configMapGenerator:
- name: example-configmap-2
  literals:
  - FOO=Bar
EOF
```

_Generated ConfigMap:_

```yaml
apiVersion: v1
data:
  FOO: Bar
kind: ConfigMap
metadata:
  name: example-configmap-2-g2hdhfc6tk
```

_Usage in a Deployment:_

```bash
# Create application.properties
cat <<EOF >application.properties
FOO=Bar
EOF

cat <<EOF >deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: my-app
        volumeMounts:
        - name: config
          mountPath: /config
      volumes:
      - name: config
        configMap:
          name: example-configmap-1
EOF

cat <<EOF >./kustomization.yaml
resources:
- deployment.yaml
configMapGenerator:
- name: example-configmap-1
  files:
  - application.properties
EOF
```

#### Secret Generation

**From a File:**

```bash
# Create a password.txt file
cat <<EOF >./password.txt
username=admin
password=secret
EOF

cat <<EOF >./kustomization.yaml
secretGenerator:
- name: example-secret-1
  files:
  - password.txt
EOF
```

_Generated Secret:_

```yaml
apiVersion: v1
data:
  password.txt: dXNlcm5hbWU9YWRtaW4KcGFzc3dvcmQ9c2VjcmV0Cg==
kind: Secret
metadata:
  name: example-secret-1-t2kt65hgtb
type: Opaque
```

**From Literal Key-Value Pairs:**

```bash
cat <<EOF >./kustomization.yaml
secretGenerator:
- name: example-secret-2
  literals:
  - username=admin
  - password=secret
EOF
```

_Generated Secret:_

```yaml
apiVersion: v1
data:
  password: c2VjcmV0
  username: YWRtaW4=
kind: Secret
metadata:
  name: example-secret-2-t52t6g96d8
type: Opaque
```

_Usage in a Deployment (similar to ConfigMap usage):_ Refer to the generated secret by its generated name.

---

### generatorOptions

Control the behavior of generated ConfigMaps and Secrets with content hash suffixes. To disable suffixes and add global
options:

```bash
cat <<EOF >./kustomization.yaml
configMapGenerator:
- name: example-configmap-3
  literals:
  - FOO=Bar
generatorOptions:
  disableNameSuffixHash: true
  labels:
    type: generated
  annotations:
    note: generated
EOF
```

_Resulting ConfigMap:_

```yaml
apiVersion: v1
data:
  FOO: Bar
kind: ConfigMap
metadata:
  annotations:
    note: generated
  labels:
    type: generated
  name: example-configmap-3
```

---

### Setting Cross-Cutting Fields

Apply a common namespace, name prefix/suffix, labels, or annotations to all resources:

```bash
# Create a deployment.yaml
cat <<EOF >./deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
EOF

cat <<EOF >./kustomization.yaml
namespace: my-namespace
namePrefix: dev-
nameSuffix: "-001"
labels:
  - pairs:
      app: bingo
    includeSelectors: true
commonAnnotations:
  oncallPager: 800-555-1212
resources:
- deployment.yaml
EOF
```

_Generated Deployment:_

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    oncallPager: 800-555-1212
  labels:
    app: bingo
  name: dev-nginx-deployment-001
  namespace: my-namespace
spec:
  selector:
    matchLabels:
      app: bingo
  template:
    metadata:
      annotations:
        oncallPager: 800-555-1212
      labels:
        app: bingo
    spec:
      containers:
        - image: nginx
          name: nginx
```

---

### Composing and Customizing Resources

Compose multiple resource files and apply patches to customize them.

#### Composing

For an NGINX application with a Deployment and a Service:

```bash
# Create deployment.yaml
cat <<EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# Create service.yaml
cat <<EOF > service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
  labels:
    run: my-nginx
spec:
  ports:
  - port: 80
    protocol: TCP
  selector:
    run: my-nginx
EOF

# Create kustomization.yaml
cat <<EOF >./kustomization.yaml
resources:
- deployment.yaml
- service.yaml
EOF
```

#### Customizing with Patches

**Using StrategicMerge Patches:**

```bash
# Create deployment.yaml
cat <<EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# Create patch increase_replicas.yaml
cat <<EOF > increase_replicas.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 3
EOF

# Create patch set_memory.yaml
cat <<EOF > set_memory.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  template:
    spec:
      containers:
      - name: my-nginx
        resources:
          limits:
            memory: 512Mi
EOF

cat <<EOF >./kustomization.yaml
resources:
- deployment.yaml
patches:
  - path: increase_replicas.yaml
  - path: set_memory.yaml
EOF
```

_Resulting Deployment:_

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      run: my-nginx
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
        - image: nginx
          name: my-nginx
          ports:
            - containerPort: 80
          resources:
            limits:
              memory: 512Mi
```

**Using Json6902 Patches:**

```bash
# Create deployment.yaml
cat <<EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# Create json patch file patch.yaml
cat <<EOF > patch.yaml
- op: replace
  path: /spec/replicas
  value: 3
EOF

# Create kustomization.yaml
cat <<EOF >./kustomization.yaml
resources:
- deployment.yaml
patches:
- target:
    group: apps
    version: v1
    kind: Deployment
    name: my-nginx
  path: patch.yaml
EOF
```

_Resulting Deployment will have replicas set to 3._

#### Image Replacement

Change the container image using the `images` field:

```bash
# Create deployment.yaml
cat <<EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

cat <<EOF >./kustomization.yaml
resources:
- deployment.yaml
images:
- name: nginx
  newName: my.image.registry/nginx
  newTag: 1.4.0
EOF
```

_Resulting Deployment will reference the updated image._

#### Replacements

Inject field values from other objects. For example, to set the Service name into a Deployment container command:

```bash
# Create deployment.yaml (using a literal delimiter to preserve special characters)
cat <<'EOF' > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        command: ["start", "--host", "MY_SERVICE_NAME_PLACEHOLDER"]
EOF

# Create service.yaml
cat <<EOF > service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
  labels:
    run: my-nginx
spec:
  ports:
  - port: 80
    protocol: TCP
  selector:
    run: my-nginx
EOF

cat <<EOF >./kustomization.yaml
namePrefix: dev-
nameSuffix: "-001"
resources:
- deployment.yaml
- service.yaml
replacements:
- source:
    kind: Service
    name: my-nginx
    fieldPath: metadata.name
  targets:
  - select:
      kind: Deployment
      name: my-nginx
    fieldPaths:
    - spec.template.spec.containers.0.command.2
EOF
```

_Resulting Deployment will have the Service name injected as `dev-my-nginx-001`._

---

### Bases and Overlays

**Bases** are directories with a `kustomization.yaml` that define resources and customizations. **Overlays** reference
these bases and add further customizations.

#### Base Example

```bash
# Create a directory for the base
mkdir base
# base/deployment.yaml
cat <<EOF > base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
EOF

# base/service.yaml
cat <<EOF > base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
  labels:
    run: my-nginx
spec:
  ports:
  - port: 80
    protocol: TCP
  selector:
    run: my-nginx
EOF

# base/kustomization.yaml
cat <<EOF > base/kustomization.yaml
resources:
- deployment.yaml
- service.yaml
EOF
```

This base can be reused in multiple overlays:

```bash
# Overlay for dev
mkdir dev
cat <<EOF > dev/kustomization.yaml
resources:
- ../base
namePrefix: dev-
EOF

# Overlay for prod
mkdir prod
cat <<EOF > prod/kustomization.yaml
resources:
- ../base
namePrefix: prod-
EOF
```

---

### How to Apply/View/Delete Objects Using Kustomize

Given a `kustomization.yaml`:

```bash
# Create deployment.yaml
cat <<EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# Create kustomization.yaml
cat <<EOF >./kustomization.yaml
namePrefix: dev-
labels:
  - pairs:
      app: my-nginx
    includeSelectors: true
resources:
- deployment.yaml
EOF
```

**Apply:**

```bash
kubectl apply -k ./
```

_Output:_

```
deployment.apps/dev-my-nginx created
```

**View:**

```bash
kubectl get -k ./
kubectl describe -k ./
```

**Diff:**

```bash
kubectl diff -k ./
```

**Delete:**

```bash
kubectl delete -k ./
```

_Output:_

```
deployment.apps "dev-my-nginx" deleted
```
