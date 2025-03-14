# ArgoCD and Argo Rollouts GitOps Documentation

This documentation provides a comprehensive, factual reference for using **ArgoCD** and **Argo Rollouts** in GitOps
workflows. It covers the latest versions of both tools, focusing on how to declaratively manage applications (with
ArgoCD **Applications** and **ApplicationSets**) and perform advanced deployment strategies (with **Argo Rollouts**).
All sections include full YAML syntax, examples, edge cases, CLI commands, and best practices. If an option or feature
is not documented here, you can assume it is not available in these frameworks.

## 1. ArgoCD ApplicationSets and Applications Syntax

ArgoCD is a declarative GitOps continuous delivery tool that deploys Kubernetes manifests from Git. It introduces two
key custom resource definitions (CRDs) for representing deployments:

- **Application**: Defines a single application’s source repository, path (or chart), destination cluster/namespace, and
  sync settings.
- **ApplicationSet**: A higher-level CRD that generates multiple Applications from a template, using various
  **generators** (for example, to deploy one app per cluster, per Git directory, etc.).

### 1.1 ArgoCD Application CRD Syntax

An **Application** is the core unit in ArgoCD, representing a desired state of a Kubernetes app. It includes where to
fetch the manifests (source), where to deploy them (destination), and how to sync. Below is the full YAML structure of
an Application with all possible fields and configurations:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app # Name of the application (ArgoCD uses this as unique identifier)
  namespace: argocd # Usually the ArgoCD control plane namespace
  finalizers:
    - resources-finalizer.argocd.argoproj.io # Enables cascading deletion of app resources ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,labels%20to%20your%20application%20object))
  labels:
    team: frontend # Custom labels for organizational purposes
spec:
  project: default # ArgoCD Project name (for RBAC and grouping) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,project%3A%20default))
  source:
    repoURL: https://github.com/my-org/my-repo.git # Git repo or Helm chart URL ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,Helm%20repo%20instead%20of%20git))
    targetRevision: main # Git branch, tag, or Helm chart version ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,Helm%20repo%20instead%20of%20git))
    path: k8s/manifests/app1 # Path within repo (ignored for pure Helm charts)
    chart: mychart # If using a Helm repo, specify chart name ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,parameters))
    helm: # Helm-specific settings (if source is a Helm chart)
      releaseName: my-app-release # Override Helm release name (defaults to app name) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=fileParameters%3A%20,json))
      values:
        | # Multi-line string of Helm values (alternative to separate files) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,mydomain.example.com%20annotations))
        replicaCount: 3
        image: my-image:1.0
      valuesObject: # Structured override of Helm values (takes precedence over `values`) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,class%3A%20nginx))
        replicaCount: 3
        image: my-image:1.0
      valueFiles: # List of values.yaml files (relative to repo path) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,releaseName%3A%20guestbook))
        - values-prod.yaml
      parameters: # Helm parameters (set via --set) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,is%20treated%20as%20a%20string))
        - name: environment
          value: production
      fileParameters: # Helm file parameters (set via --set-file) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,json))
        - name: config
          path: configs/prod.json
      ignoreMissingValueFiles: false # If true, ignore missing files in valueFiles ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=))
      passCredentials: false # Pass repo credentials to dependencies (Helm dependency charts) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=chart%3A%20chart,parameters))
      skipCrds: false # Skip applying CRDs from the chart ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,Defaults%20to%20false%20skipCrds%3A%20false))
      skipSchemaValidation: false # Skip schema validation for CRDs ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=skipCrds%3A%20false))
      version: v3 # Force use of Helm v3 (v2 or v3) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,version%3A%20v2))
      kubeVersion: 1.24.0 # Kubernetes version to template with (semver, no "v" prefix) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,kubeVersion%3A%201.30.0))
      apiVersions: # K8s API versions to support in templating ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,v1%2FService))
        - networking.k8s.io/v1/Ingress
        - argoproj.io/v1alpha1/Rollout
    kustomize: # Kustomize-specific settings (if source uses a kustomization)
      namePrefix: prod- # Prefix to add to all resource names ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,enables%2Fdisables%20env%20variables%20substitution%20in))
      nameSuffix: -v1 # Suffix to add to all resource names ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,enables%2Fdisables%20env%20variables%20substitution%20in))
      commonLabels: # Labels added to all resources ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=commonLabels%3A%20foo%3A%20bar%20commonAnnotations%3A%20beep%3A,true%20forceCommonLabels%3A%20false%20forceCommonAnnotations%3A%20false))
        env: production
      commonAnnotations: # Annotations added to all resources ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=commonLabels%3A%20foo%3A%20bar%20commonAnnotations%3A%20beep%3A,true%20forceCommonLabels%3A%20false%20forceCommonAnnotations%3A%20false))
        deployTime: '{{now}}'
      images: # Kustomize image overrides (name=image:tag or newName=newImage) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=forceCommonAnnotations%3A%20false%20images%3A%20,ui%20count%3A%204))
        - my-app=repo/my-app:1.2.0
      replicas: # Kustomize replicas count overrides ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=namespace%3A%20custom,patches))
        - name: my-deployment
          count: 4
      patches: # Strategic patches or JSON patches to apply ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=patches%3A%20,pro))
        - target:
            kind: Deployment
            name: my-deployment
          patch: |-
            - op: replace
              path: /spec/template/spec/replicas
              value: 5
      namespace: custom-ns # Override namespace for kustomize (if needed) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=forceCommonAnnotations%3A%20false%20images%3A%20,ui%20count%3A%204))
      forceCommonLabels: false # Force applying common labels, even if already present ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,namespace))
      forceCommonAnnotations: false # Force applying common annotations ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=commonAnnotations%3A%20beep%3A%20boop,forceCommonLabels%3A%20false%20forceCommonAnnotations%3A%20false%20images))
      commonAnnotationsEnvsubst: true # Enable env substitution in commonAnnotations ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=commonAnnotations%3A%20beep%3A%20boop,forceCommonLabels%3A%20false%20forceCommonAnnotations%3A%20false%20images))
      apiVersions: # Additional API versions for Kustomize (similar to Helm above) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,kubeVersion%3A%201.30.0))
        - argoproj.io/v1alpha1/Rollout
      kubeVersion: 1.24.0 # Kubernetes version for Kustomize (if needed) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,kubeVersion%3A%201.30.0))
    directory: # Plain directory (yaml/json manifests or Jsonnet) settings
      recurse: true # Recurse into sub-folders for manifests ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,name%3A%20foo%20value%3A%20bar)) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,only%20matching%20manifests%20will%20be))
      exclude: '{test/**, README.md}' # Glob patterns to exclude from sync ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,only%20matching%20manifests%20will%20be))
      include: '*.yaml' # Glob patterns to include (if set, only these are used) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=them%20with%20commas,yaml))
      jsonnet: # Jsonnet-specific settings if using Jsonnet
        extVars: # Jsonnet external variables ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=jsonnet%3A%20,code%3A%20true%20name%3A%20baz))
          - name: env
            value: prod
        tlas: # Jsonnet top-level arguments ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,field))
          - name: config
            value: prod-config
            code: false
    plugin: # Config Management Plugin settings (if using a custom plugin)
      name: myplugin # Name of the configured plugin to use ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,name%3A%20FOO))
      env: # Environment variables to pass to the plugin ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=name%3A%20mypluginname%20,string))
        - name: FOO
          value: bar
      parameters: # Plugin parameters (ArgoCD v2.5+) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,value))
        - name: mode
          string: 'fast'
  sources: # (Optional) *Multiple* sources for an app (multi-source app) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,field))
    - repoURL: https://github.com/my-org/another-repo.git
      targetRevision: main
      path: overlays/prod
      ref: repo2 # Reference name to use this source's files in Helm valueFiles, etc. ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=path%3A%20guestbook%20%20,field))
  destination:
    server: https://kubernetes.default.svc # Target cluster API server URL (in-cluster here) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,namespace%20namespace%3A%20guestbook))
    # name: my-cluster                             # Alternatively, reference cluster by name (as in ArgoCD cluster list) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,namespace%20namespace%3A%20guestbook))
    namespace: prod-namespace # Target namespace for deployment ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,namespace%20namespace%3A%20guestbook))
  info: # Arbitrary info items shown in ArgoCD UI ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,com))
    - name: Repository
      value: https://github.com/my-org/my-repo.git
    - name: Service Owner
      value: frontend-team
  syncPolicy:
    automated: # Enable automated sync (Git push triggers deployment) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,cluster%20and%20no%20git%20change)) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,deleting%20all%20application%20resources%20during))
      prune: true # Prune resources not defined in Git on sync (defaults false) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=automated%3A%20,deleting%20all%20application%20resources%20during))
      selfHeal: true # If cluster state diverges (out-of-band), resync it automatically ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=controlled%20using%20,deleting%20all%20application%20resources%20during))
      allowEmpty: false # If true, allow sync to delete **all** resources (even entire app) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=allowEmpty%3A%20false%20,options%20which%20modifies%20sync%20behavior))
    syncOptions: # Fine-tuning sync behavior ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=syncOptions%3A%20%20%20%20,wave%20of%20a%20sync%20operation))
      - CreateNamespace=true # Auto-create the destination namespace if it doesn't exist ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=syncOptions%3A%20%20%20%20,wave%20of%20a%20sync%20operation))
      - Validate=false # Skip kubectl schema validation on apply ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=syncOptions%3A%20%20%20%20,wave%20of%20a%20sync%20operation))
      - PrunePropagationPolicy=foreground # Use foreground deletion propagation ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=specified%20as%20the%20application%20destination,every%20object%20in%20the%20application))
      - PruneLast=true # Do pruning after all sync waves complete ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=specified%20as%20the%20application%20destination,every%20object%20in%20the%20application))
      - RespectIgnoreDifferences=true # Honor ignoreDifferences settings during sync ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=final%2C%20implicit%20wave%20of%20a,every%20object%20in%20the%20application))
      - ApplyOutOfSyncOnly=true # Only apply out-of-sync (changed) resources ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=final%2C%20implicit%20wave%20of%20a,every%20object%20in%20the%20application))
    managedNamespaceMetadata: # (If CreateNamespace=true) add metadata to the created namespace ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=managedNamespaceMetadata%3A%20,namespace%20the%3A%20same%20applies%3A%20for))
      labels:
        team-owned: 'true'
      annotations:
        owner: argocd
    retry: # Retry strategy for failed syncs (since v1.7) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,duration%20after%20each%20failed%20retry))
      limit: 5 # Retry attempts (if <0, unlimited) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,duration%20after%20each%20failed%20retry))
      backoff:
        duration: 5s # Initial backoff duration ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=backoff%3A%20duration%3A%205s%20,allowed%20for%20the%20backoff%20strategy))
        factor: 2 # Exponential backoff factor ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=backoff%3A%20duration%3A%205s%20,allowed%20for%20the%20backoff%20strategy))
        maxDuration: 3m # Max total backoff time ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=could%20also%20be%20a%20duration,allowed%20for%20the%20backoff%20strategy))
  ignoreDifferences: # Ignore specified diffs between Git and cluster state ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,group%3A%20apps%20kind%3A%20Deployment%20jsonPointers))
    - group: apps
      kind: Deployment
      jsonPointers: ['/spec/replicas'] # e.g. ignore changes in replicas count ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=ignoreDifferences%3A%20,%27.data%5B%22config.yaml%22%5D.auth))
    - kind: ConfigMap
      jqPathExpressions: ['.data["config.yaml"].auth'] # ignore specific JSON key diff ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,%27.data%5B%22config.yaml%22%5D.auth))
    - group: '*'
      kind: '*'
      managedFieldsManagers: ['kube-controller-manager'] # ignore changes made by specified controllers ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,namespace))
  revisionHistoryLimit: 10 # Number of past sync histories to keep for rollback (default 10) ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,revisionHistoryLimit%3A%2010))
```

In the above Application manifest, **every possible field** is shown. Most real-world Applications are simpler. Key
fields explained:

- **spec.project**: Grouping of applications for RBAC and policy control. Defaults to `default` if not set
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,project%3A%20default)).
- **spec.source**: Defines where to get manifests. Supports Git (with `path`), Helm (with `chart` and optional `path`
  for charts in Git), Kustomize, plain directories, or Config Management Plugins. Only one source is used unless using
  the multi-source feature (specify multiple under `sources` to combine them)
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,field)).
- **spec.destination**: Target cluster and namespace. Use `server` with the API URL, or `name` for a cluster that’s been
  added to ArgoCD by name. `namespace` is where to deploy the resources (namespaces for cluster-scoped resources are
  ignored)
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,namespace%20namespace%3A%20guestbook)).
- **spec.syncPolicy**: Defines how ArgoCD syncs this application. If `automated` is set, ArgoCD will attempt to
  automatically apply changes. `prune` removes resources not in Git, and `selfHeal` monitors the cluster state for drift
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,cluster%20and%20no%20git%20change)).
  `syncOptions` provide granular control (e.g., auto-create namespace, skip validation, etc.)
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=syncOptions%3A%20%20%20%20,wave%20of%20a%20sync%20operation)).
- **spec.ignoreDifferences**: Allows ignoring certain fields when detecting diffs (useful for fields that change in
  cluster, like replicas, timestamps, etc.)
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,group%3A%20apps%20kind%3A%20Deployment%20jsonPointers)).
- **spec.revisionHistoryLimit**: How many past revisions to keep for potential rollback and history visibility
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,revisionHistoryLimit%3A%2010)).

**Practical examples:** A minimal Application might only specify `repoURL`, `path`, `targetRevision`, `destination`, and
set `syncPolicy` to manual (by omitting `automated`). On the other hand, a Helm-based Application would omit `path` and
use `chart` and possibly `helm` values/parameters. If using Kustomize, you can add kustomize-specific overrides as shown
above. All these fields can be combined as needed (e.g., an Application could use a Git repo with a Kustomize overlay
and have automated sync enabled with pruning).

**Edge cases & advanced configs:**

- _Multi-source Applications_: ArgoCD supports defining multiple sources (Helm + Kustomize, or multiple Helm charts,
  etc.) in one Application (introduced in v2.5)
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,field)).
  The `sources` list can be used to merge manifests from different repos or charts. In such cases, one of the sources
  can reference others via `ref` to share value files, etc.
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=path%3A%20guestbook%20%20,field)).
- _Hooks_: Pre-sync or post-sync hooks are implemented by adding special Kubernetes resources (like Jobs) with
  particular annotations (not via a field in the spec). For example, a resource with annotation
  `argocd.argoproj.io/hook: PreSync` acts as a pre-deployment hook. Though not a field in Application spec, it’s an
  advanced topic to be aware of for complex deployments.
- _Self-heal and auto-sync_: If `selfHeal: true`, ArgoCD will continuously monitor the cluster. If someone manually
  changes a managed resource (e.g., scale a Deployment) in the cluster, ArgoCD will detect the drift and revert it to
  Git state
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=controlled%20using%20,deleting%20all%20application%20resources%20during)).
  This is powerful but one must configure `ignoreDifferences` if certain drift (like status or timestamp fields) should
  be tolerated.
- _Allowing deletion of all resources_: By default ArgoCD prevents an Application sync from deleting **all** resources
  (to avoid wiping everything on accidental empty commit). Setting `allowEmpty: true` permits sync to delete all objects
  if the Git app manifest is empty
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=allowEmpty%3A%20false%20,options%20which%20modifies%20sync%20behavior))
  – use with caution.
- _Finalizer behavior_: The `resources-finalizer.argocd.argoproj.io` on an Application ensures that when the Application
  CR is deleted, ArgoCD will also delete all resources it deployed (cascading delete)
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,labels%20to%20your%20application%20object)).
  You can switch it to background deletion if needed (deletes Application immediately and cleans up resources in
  background).

**Error handling & debugging Applications:** If an Application fails to sync or shows an error state, ArgoCD provides
details in several places:

- **Application Status Conditions**: The Application status has conditions (like `SyncFailed`, `ComparisonError`, etc.)
  with messages. For example, if the Git repo cannot be reached or manifest parsing fails, a condition will indicate the
  issue.
- **ArgoCD UI and CLI**: The Web UI shows events and logs for the Application. The CLI `argocd app get <name>` will
  display status and any errors. For instance, a common error is “OutOfSync” if manifests in Git differ from the cluster
  – ArgoCD will list which resources differ.
- **Controller Logs**: In complex cases, checking the ArgoCD Application Controller pod logs can help (it logs sync
  attempts, hook execution, and errors like unknown API kinds).
- **App-Project relationship**: If an Application’s project is misconfigured (e.g., the Project doesn’t allow the target
  namespace or cluster), the sync will be blocked. ArgoCD will report a `PermissionDenied` or project mismatch error.
  Ensuring the Application’s spec.project matches an ArgoCD Project that allows the specified source repo and
  destination is crucial (security aspect).
- **Health Status**: Each Application resource has a health assessment. ArgoCD knows how to judge resource health (e.g.,
  Deployment is healthy when desired pods are ready). If a Rollout (from Argo Rollouts) is part of the app, ArgoCD can
  assess its health too (with custom health checks in newer versions) – if not, it may show “Unknown” health, which can
  be customized via ArgoCD settings.

### 1.2 ArgoCD ApplicationSet CRD Syntax

An **ApplicationSet** automates the management of multiple Applications. Instead of writing many similar Application
manifests, you define a single ApplicationSet with a template and a **generator** that produces parameters. The
controller then instantiates an ArgoCD Application for each set of parameters. The ApplicationSet CRD supports multiple
generator strategies and advanced features for large-scale GitOps.

The full YAML structure of an ApplicationSet with all possible fields is shown below:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: example-appset
  namespace: argocd
spec:
  generators:
    # 1. List generator example (explicit list of values)
    - list:
        elements:
          - cluster: engineering-dev # Custom parameters to template
            url: https://dev.k8s.local
            env: staging
          - cluster: engineering-prod
            url: https://prod.k8s.local
            env: prod
        template: # (Optional) override template for this generator ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,prod%20url%3A%20https%3A%2F%2Fkubernetes.default.svc)) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,cd.git))
          metadata: {}
          spec:
            project: 'default'
            source:
              repoURL: https://github.com/argoproj/argo-cd.git
              targetRevision: HEAD
              # Use the cluster name in the path via parameter substitution:
              path: 'apps/{{cluster}}'
            destination: {}
        selector:
          matchLabels:
            env: staging # Filters which list elements to use (only where env=staging) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=destination%3A%20))

    # 2. Cluster generator example (generates one Application per target cluster)
    - clusters:
        selector:
          matchExpressions: # Select clusters by labels (ArgoCD cluster secrets labels) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,cluster))
            - key: environment
              operator: In
              values: ['dev', 'prod']
        values: # Additional values to inject for all clusters selected ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=generators%3A%20,clusters%3A%20selector%3A%20matchLabels)) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=values%3A%20kafka%3A%20%27true%27%20redis%3A%20%27false%27,kafka%3A%20%27false%27%20values))
          team: platform
    # The cluster generator will produce parameters like {{name}} and {{server}} for each cluster known to ArgoCD that matches the selector.

    # 3. Git generator (Directory and Files)
    - git:
        repoURL: https://github.com/my-org/config-repo.git
        revision: main
        # Option A: Directory generator – one Application per directory
        directories:
          - path: 'apps/*' # Generates an app for each sub-directory under apps/ ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=The%20Git%20directory%20generator%2C%20one,of%20a%20specified%20Git%20repository))
            exclude: 'apps/excluded/**' # Optionally exclude some directories ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=The%20Git%20directory%20generator%20will,git))
        # Option B: File generator – one Application per file
        files:
          - path: 'environments/*/config.json' # Finds all config.json files in env dirs ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=generators%3A%20,config%2F%2A%2A%2Fconfig.json%22%20template%3A%20metadata)) ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=source%3A%20repoURL%3A%20https%3A%2F%2Fgithub.com%2Fargoproj%2Fargo,cluster.address%7D%7D%27%20namespace%3A%20guestbook))
        # The Git generator will poll the repo every 3 minutes by default for changes ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=cd,)), or use webhooks for instant update.

    # 4. SCM Provider generator (scans code hosting services for repos)
    - scmProvider:
        cloneProtocol: https # Use https or ssh for cloning discovered repos ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,For%20GitHub%20Enterprise))
        github:
          organization: my-org # Scan all repos in this GitHub org ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,Defaults%20to%20false))
          api: https://api.github.com # (Optional) custom API endpoint (for GitHub Enterprise) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=github%3A%20,%28optional))
          tokenRef: # (Optional) secret with API token for auth ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=api%3A%20https%3A%2F%2Fgit.example.com%2F%20,token%20key%3A%20token))
            secretName: github-token
            key: token
          allBranches: false # If true, include all branches; if false, only default branch ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=organization%3A%20myorg%20,%28optional%29%20tokenRef))
          appSecretName: gh-app-repo-creds # (Optional) use GitHub App credentials ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=secretName%3A%20github,repository))
          values: # Values to inject for each repo ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=%23Pass%20additional%20key,repository))
            component: '{{ repository }}'
        filters: # Filter which repos to include ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,txt)) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,may%20be%20used%20here%20instead))
          - repositoryMatch: ^myapp # Regex to include repos starting with "myapp"
            pathsExist: ['kustomization.yaml'] # Only if this file exists in repo
            labelMatch: deploy-ok # Only if repo has this label (GitHub specific)
          - repositoryMatch: ^otherapp
            pathsExist: ['helm']
            pathsDoNotExist: ['disabledrepo.txt']
        gitlab: {} # Similar structures exist for gitlab, gitea, bitbucket, azureDevOps, awsCodeCommit, etc. (Only one provider section is used at a time)

    # 5. Pull Request generator (creates Apps for each PR/MR in a repo)
    - pullRequest:
        requeueAfterSeconds: 1800 # Poll interval for PR changes (30 min default) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,The%20GitHub%20organization%20or%20user))
        github:
          owner: myorg # GitHub org or user ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,%28optional))
          repo: my-repo # Repository name to scan PRs ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,token))
          api: https://api.github.com # GitHub API (if using GHE) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,API%20instead%20of%20a%20PAT))
          tokenRef:
            secretName: github-token
            key: token
          labels: ['preview'] # Only include PRs with this label (optional) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,preview))
        filters:
          - branchMatch: '.*-preview' # Only include PRs whose branch name matches regex ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,argocd))
        # (GitLab, Gitea, Bitbucket, Azure, AWS CodeCommit can also be configured similarly under pullRequest) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,bitbucket))

    # 6. Matrix generator (cartesian product of two or more generators)
    - matrix:
        generators:
          - list:
              elements:
                - region: us-east
                - region: us-west
          - git:
              repoURL: https://github.com/my-org/app-configs.git
              revision: main
              directories:
                - path: 'services/*'
        # This will generate an Application for every combination of region X service directory.

    # 7. Merge generator (combine outputs of generators by merging on keys)
    - merge:
        mergeKeys: ['server', 'values.env'] # Keys to determine matching parameter sets to merge ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,values.selector%20generators)) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,clusters%3A%20values%3A%20kafka%3A%20%27true))
        generators:
          - clusters:
              selector:
                matchLabels:
                  env: dev
              values:
                env: dev
          - clusters:
              selector:
                matchLabels:
                  env: prod
              values:
                env: prod
          - list:
              elements:
                - server: https://prod.k8s.local
                  values.env: prod
                  values.db: postgres
    # In this example, the merge generator pairs cluster outputs with matching env values and adds database info from list.

    # 8. Plugin generator (custom script/external data source)
    - plugin:
        configMapRef:
          name: my-plugin # ConfigMap containing plugin configuration ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,available%20on%20the%20generator%27s%20output)) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,key.%20input))
        input:
          parameters: # Arbitrary key-values passed as input to the plugin script ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,values))
            foo: 'bar'
            list: [1, 2, 3]
          values:
            globalToggle: true # Values to inject into templates under `.values` key ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=key2%3A%20%22value2%22%20key3%3A%20%22value3%22%20,generator%2C%20the%20ApplicationSet%20controller%20polls))
        requeueAfterSeconds: 600 # How often to re-run the plugin to detect changes (default 1800s) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,to%20detect%20changes))

    # 9. Cluster Decision Resource generator (integrates with OCM/ACM for cluster placement)
    - clusterDecisionResource:
        configMapRef: my-configmap # ConfigMap that defines the duck-typed GVK for cluster decision ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=%23%20Cluster,OPTIONAL%20duck%3A%20spotted))
        name: my-placement # Name of the cluster decision resource (if known) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,key%3A%20duck))
        labelSelector:
          matchLabels:
            environment: staging # Alternatively, select the resource by labels
        requeueAfterSeconds: 60 # Poll frequency (default 180s) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,default%203min%29%20requeueAfterSeconds%3A%2060))

  template:
    metadata:
      name: '{{cluster}}-{{application}}' # Name template for generated Applications (using parameters)
      labels:
        generated-by: applicationset
    spec:
      project: '{{ values.team | default("default") }}' # Use team value if provided, else default project
      source:
        repoURL: https://github.com/my-org/my-app.git
        targetRevision: '{{ branch | default("HEAD") }}'
        path: '{{ appPath }}'
      destination:
        server: '{{ server | default("https://kubernetes.default.svc") }}'
        namespace: '{{ namespace | default("default") }}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true

  goTemplate: false # If true, allows using Go templating in the template field (alternative to default simple placeholders) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,is%20true))
  goTemplateOptions: ['missingkey=error'] # Options for Go template rendering (if enabled) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,is%20true))

  syncPolicy:
    applicationsSync: create-only # Control how the ApplicationSet updates Applications ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,only))
    # options: create-only (never update or delete apps once created), create-update (no deletions), create-delete (no updates) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=syncPolicy%3A%20,only))
    preserveResourcesOnDeletion: true # If true, when an Application is deleted (e.g., ApplicationSet removed it), its resources are not pruned from cluster ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,Application%20is%20deleted%20preserveResourcesOnDeletion%3A%20true))

  strategy:
    type: RollingSync # Enable progressive sync (batch updates of Applications) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=strategy%3A%20,using%20their%20labels%20and%20matchExpressions))
    rollingSync:
      steps:
        - matchExpressions:
            - key: env
              operator: In
              values: ['dev']
        - matchExpressions:
            - key: env
              operator: In
              values: ['qa']
          maxUpdate: 0 # e.g., hold QA apps until manually triggered (0% updated in this wave) ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,matched%20applications%20will%20be%20synced))
        - matchExpressions:
            - key: env
              operator: In
              values: ['prod']
          maxUpdate: 10% # Only update 10% of prod apps at a time in this wave ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=operator%3A%20In%20values%3A%20,0))

  preservedFields:
    annotations: ['some.annotation/key'] # These annotations on Applications won’t be touched by the ApplicationSet ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,key))
    labels: ['some.label/key'] # Likewise for labels (legacy way to ignore changes)

  ignoreApplicationDifferences:
    - jsonPointers: ['/spec/source/targetRevision'] # Newer way to ignore fields when comparing generated Application spec vs live Application spec ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,.spec.source.helm.values))
    - name: specific-app
      jqPathExpressions: ['.spec.source.helm.values']
```

This ApplicationSet spec is exhaustive. Key parts to understand:

- **Generators (spec.generators)**: A list of one or more generator configurations. Each generator produces a set of
  parameter values (a list of map keys/values) which will be substituted into the `template`. You can use multiple
  generators:

  - **List generator**: Define an explicit list of parameter sets (each element is an object with arbitrary keys). For
    example, in the list above, we define two clusters with their URLs and environment
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,prod%20url%3A%20https%3A%2F%2Fkubernetes.default.svc)).
    The ApplicationSet will create Applications for each list element (and you can filter them further using a
    `selector` on those parameter fields
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=destination%3A%20))).
  - **Cluster generator**: Generates one entry per cluster known to ArgoCD (clusters are added via
    `argocd cluster add`). You can filter clusters by label or name. Each cluster entry yields parameters like `name`
    (cluster name in ArgoCD) and `server` (API URL) by default. You can also attach static `values` to all generated
    items
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=generators%3A%20,clusters%3A%20selector%3A%20matchLabels)).
    Common use case: Deploy the same app to all clusters or a subset (e.g., all clusters labeled “prod”).
  - **Git generator**: Scans a Git repository for directories or files. Two sub-modes:
    - _Directory generator_: one Application per subdirectory matching a path pattern (supports wildcards and exclude)
      ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=The%20Git%20directory%20generator%2C%20one,of%20a%20specified%20Git%20repository)).
      For example, generate an app for each folder under `apps/`. You can even set `path: '*'` to use the repo root and
      treat each top-level folder as an app
      ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=The%20Git%20directory%20generator%20can,as%20the%20%60path)).
    - _File generator_: one Application per file matching a glob pattern
      ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=generators%3A%20,config%2F%2A%2A%2Fconfig.json%22%20template%3A%20metadata)).
      Often used by storing a file (like `config.json`) per cluster or environment, which the generator flattens into
      parameters. The content of JSON/YAML files can be turned into template params: keys are flattened (e.g., JSON with
      `cluster.name` becomes a param)
      ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=aws_account%3A%20123456%20asset_id%3A%2011223344%20cluster,dev%20cluster.address%3A%20https%3A%2F%2F1.2.3.4))
      ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=In%20addition%20to%20the%20flattened,following%20generator%20parameters%20are%20provided)).
      The Git generator polls every 3 minutes by default for changes
      ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=cd,)),
      but you can configure ArgoCD’s webhook receiver to trigger immediate updates on Git push
      ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=cd,secret%20Kubernetes)).
  - **SCM Provider generator**: Connects to Git hosting platforms (GitHub, GitLab, Bitbucket, Azure DevOps, etc.) via
    their APIs to list repositories in an org/group
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,For%20GitHub%20Enterprise))
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,to%20look%20up%20eligible%20repositories)).
    You specify the organization or group and optional filters. This generator is great for **automatically onboarding
    new repos** – e.g., every new repo in “my-org” that contains a Kubernetes manifest directory triggers a new
    Application. You can filter by repository name regex, presence or absence of certain files, or repository labels (in
    GitHub)
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,txt))
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,may%20be%20used%20here%20instead)).
    It requires an API token or GitHub App credentials for authentication (token stored in a Secret and referenced in
    the generator)
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=api%3A%20https%3A%2F%2Fgit.example.com%2F%20,token%20key%3A%20token)).
  - **Pull Request generator**: Scans pull requests or merge requests in a specific repo and creates an Application for
    each open PR
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,github)).
    This is used for **preview environments**. For example, each PR might deploy a temporary environment for testing. It
    supports GitHub, GitLab, Gitea, Bitbucket, Azure, AWS CodeCommit PRs
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,bitbucket)).
    You can filter PRs by branch name regex or labels
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,argocd)).
    When a PR is merged or closed, the corresponding Application can be configured to delete (if you remove it from
    generator output, ApplicationSet will delete the app).
  - **Matrix generator**: Takes two or more generators and produces the Cartesian product of their outputs
    ([Generators - Argo CD - Declarative GitOps CD for Kubernetes - Read the Docs](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators/#:~:text=files%20within%20a%20Git%20repository%2C,parameters%20of%20two%20separate%20generators)).
    For instance, combine a list of regions with a list of services to deploy every service in every region. Each
    combination yields one Application. This is useful for multi-dimensional deployments (like multiple environments \*
    multiple microservices).
  - **Merge generator**: Takes multiple generator outputs and **merges** parameter sets that share common keys
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,values.selector%20generators)).
    You specify `mergeKeys` to identify matching entries. For example, one generator yields cluster info (with key
    “env”), another yields database settings per env. The merge generator can combine them into a single parameter set
    per environment. It allows you to split your data sources and then join them.
  - **Plugin generator**: Executes a custom logic (outside of ArgoCD’s built-in options) to produce a list of parameters
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,key)).
    You configure a `configMapRef` which points to a ConfigMap that the ApplicationSet controller will use (the
    ConfigMap contains scripting or plugin config the controller knows how to run). The `input` section passes arbitrary
    parameters to the plugin, and the plugin returns a list of generated parameters. This is an **escape hatch** for
    complex or bespoke generation logic (for example, call an external API to get a list of tenants). The controller
    polls at `requeueAfterSeconds` interval to refresh plugin data
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,to%20detect%20changes)).
  - **ClusterDecisionResource generator**: Integrates with Cluster Placement APIs (like Open Cluster Management’s
    PlacementDecision CRs). You provide a ConfigMap that tells ArgoCD how to interpret a custom resource as a list of
    clusters. The ApplicationSet will read that resource (matching name or labels) to determine which clusters should
    receive the Application
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=%23%20Cluster,OPTIONAL%20duck%3A%20spotted))
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,key%3A%20duck)).
    This is advanced usage for dynamic multi-cluster scenarios where cluster membership is managed by another system.

- **Template (spec.template)**: This is essentially a template of an ArgoCD Application. It contains metadata
  (name/labels/annotations for the generated Application) and spec (which is exactly the same fields as a normal
  Application spec). The values from the generators are substituted into this template. In the YAML above, the template
  uses Jinja-like syntax (`{{ }}`) for substitution by default. For example, `{{cluster}}` will be replaced by each
  generator’s `cluster` value, and `{{ server }}` with the cluster API URL. If `goTemplate: true` is set, the template
  uses Go template syntax instead (which can be more powerful, allowing loops, conditionals, etc., as defined by Go’s
  text/template)
  ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,is%20true)).
  The template can reference:

  - Direct fields from generator elements (e.g., `.cluster`, `.url`, or nested `.values.*` if using `values` as shown in
    some generators
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=generators%3A%20,clusters%3A%20selector%3A%20matchLabels))).
  - Built-in generator fields like `{{path.basename}}` for git directory names, etc., depending on generator type
    ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=following%20generator%20parameters%20are%20provided%3A)).
  - In Go templates mode, a dot notation is used (e.g., `{{.cluster}}`). The example above sticks to the default style
    for clarity.

  The `metadata.name` in the template should be carefully chosen to avoid collisions. Often it concatenates params (like
  cluster-name + app-name). If two parameter sets produce the same name, only one Application will exist (ApplicationSet
  controller will manage one). To ensure unique names, include a distinguishing field (like cluster, or repo, or PR
  number) in the name template.

- **syncPolicy (spec.syncPolicy) for ApplicationSet**: _Not to be confused with Application’s syncPolicy._ In
  ApplicationSet, `applicationsSync` can restrict how it modifies child Applications
  ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,only)).
  By default, ApplicationSet will **create, update, and delete** Applications to match the generator output. You can
  limit this:

  - `create-only`: once created, it will not update or delete Applications. (If changes occur in Git generator, new ones
    won’t apply to existing apps – you’d manage updates manually).
  - `create-update`: it will create and update apps, but never delete them. (Removed generator entries won’t trigger
    Application deletion).
  - `create-delete`: it will create and delete, but not update existing ones (useful if you want to freeze any
    modifications after creation, except deletion).
  - `preserveResourcesOnDeletion`: If true, when an Application is deleted by the ApplicationSet (e.g., a cluster was
    removed from the generator), ArgoCD will _not_ delete the Kubernetes resources of that Application
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=is%20allowed.%20%23%20applicationsSync%3A%20create)).
    This can be important to avoid accidental deletion of running workloads when you remove an entry – the Application
    CR goes away but its resources remain for manual cleanup or reattachment.

- **strategy (spec.strategy)**: Allows **progressive syncing** of generated Applications in batches (ArgoCD v2.5+
  feature). In large fleets, you may not want to sync all apps at once when something changes. `RollingSync` strategy
  groups Applications by label selectors and applies updates in waves
  ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=strategy%3A%20,using%20their%20labels%20and%20matchExpressions)).
  In the example, the strategy is defined to sync dev apps, then QA, then Prod with only 10% at a time in Prod
  ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=operator%3A%20In%20values%3A%20,key%3A%20envLabel%20operator%3A%20In%20values))
  ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=operator%3A%20In%20values%3A%20,0)).
  This is analogous to progressive delivery but at the GitOps level (it doesn’t use Argo Rollouts, rather it staggers
  when ArgoCD applies changes to different Applications). You label your Applications (via template metadata labels) and
  then define the batches in the ApplicationSet’s strategy. If `maxUpdate` is less than the number of matching apps, it
  will only sync that many at once (you can use percentages).

- **Ignore diffs between template and live Applications**: ApplicationSet can ignore certain fields when comparing the
  generated template to what’s on the cluster in the Application CRs. Previously `preservedFields` was used to list
  labels/annotations to ignore
  ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,key)).
  Now `ignoreApplicationDifferences` is available to ignore specific fields in the Application spec
  ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,.spec.source.helm.values))
  (similar to Application’s own ignoreDifferences but this is for the ApplicationSet controller to not constantly try to
  override things like targetRevision if you intentionally let them drift).

**Practical examples of ApplicationSet use cases:**

- **Deploy to multiple clusters**: Use a `clusters` generator. For instance, to deploy “guestbook” app to all clusters,
  you might have:

  ```yaml
  generators:
    - clusters: {}
  template:
    metadata:
      name: '{{name}}-guestbook'
    spec:
      source: { ... }
      destination:
        name: '{{name}}' # use cluster name
        namespace: guestbook
  ```

  This will create an Application per cluster (as known in ArgoCD). If a new cluster is added to ArgoCD, the
  ApplicationSet will eventually create the Application for it automatically
  ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=awsCodeCommit%3A)).
  Removing a cluster (or adjusting the selector) will delete the Application (unless `create-update` is set to prevent
  deletion).

- **Deploy multiple apps from a monorepo**: Use a `git` directory generator. If your repo has directories per
  microservice, e.g. `services/serviceA/`, `services/serviceB/`, you can do:

  ```yaml
  generators:
  - git:
      repoURL: <repo>
      revision: main
      directories:
      - path: 'services/*'
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      path: '{{path}}'
      ...
  ```

  ArgoCD will create an Application for each subdirectory under `services/`
  ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=Suppose%20you%20have%20a%20Git,with%20the%20following%20directory%20structure)).
  If you add a new directory in Git, it results in a new Application deployed on next sync. If you remove or rename a
  directory, the corresponding Application is deleted or updated.

- **Preview environments per Pull Request**: Use the `pullRequest` generator. For example:

  ```yaml
  generators:
    - pullRequest:
        github:
          owner: myorg
          repo: myapp
          tokenRef: ...
        filters:
          - branchMatch: 'feature/.*'
  template:
    metadata:
      name: 'myapp-pr-{{ number }}'
    spec:
      source:
        repoURL: https://github.com/myorg/myapp.git
        targetRevision: '{{ headSHA }}' # use the commit SHA of PR head
        path: overlays/preview
      destination:
        server: https://kubernetes.default.svc
        namespace: 'pr-{{ number }}'
  ```

  This creates an Application for each open PR whose branch matches “feature/…”. It uses the PR’s head commit
  (`headSHA`) and perhaps a specific Kustomize/Helm overlay for previews. When a PR is closed, ArgoCD will remove the
  app (cleaning up preview resources, especially if cascade deletion finalizer is on the Application).

**Edge cases & advanced configs for ApplicationSet:**

- _Multiple generators in one ApplicationSet_: You can list multiple generators under `spec.generators`. By default,
  they will all **merge their output (union)** – i.e., any generator that produces a set of parameters yields
  Applications. If you list two generators at top level, you’ll get sum of both sets. If you want to combine them
  differently, you should use the `matrix` or `merge` generator explicitly. Only one top-level generator needs to be
  specified normally, except when using matrix/merge which contain sub-generators.
- _Generator precedence_: If two generators output the same `metadata.name` for the Application, they will essentially
  “fight” over it (or one will update it). Ensure uniqueness or use the `merge` generator to intentionally merge their
  data.
- _Templating mode_: Setting `goTemplate: true` can be helpful for complex logic. For example, you could conditionally
  include certain fields. If using go templates, the double curly braces syntax changes (`{{` remains, but you can use
  more advanced functions). Note that using `goTemplate` might restrict the use of `mergeKeys` in merge generator (as
  noted in docs)
  ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,clusters)).
- _ApplicationSet controllers and performance_: For very large sets (hundreds of Applications), consider using
  RollingSync to avoid a stampede of syncs. Also, the ApplicationSet controller by default re-evaluates every 3 minutes
  (or the specified `requeueAfterSeconds` per generator). If using webhooks for Git generators, ensure the ArgoCD
  webhook endpoint is configured so that changes are pushed immediately
  ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=cd,secret%20Kubernetes)).
- _Troubleshooting ApplicationSet_: Check the `.status.conditions` of the ApplicationSet CR. If something goes wrong
  (like a generator cannot pull data), it will put a condition with message. For example, if a Git generator fails to
  authenticate (bad token), or if a plugin script fails, you’ll see a condition of type `ErrorOccurred` with details.
  The ArgoCD logs (for the ApplicationSet controller) will also have stack traces or error messages.

- _Debugging tip_: You can simulate what Applications will be created by using the ArgoCD CLI:
  `argocd appset generate <appset-name>` (or `appset create --dry-run -o json`) to have the controller output the list
  of generated Applications without actually applying them
  ([argocd appset create Command Reference - Argo CD - Declarative GitOps ...](https://argo-cd.readthedocs.io/en/latest/user-guide/commands/argocd_appset_create/#:~:text=argocd%20appset%20create%20Command%20Reference,output))
  ([argocd appset Command Reference - Argo CD - Declarative GitOps CD for ...](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_appset/#:~:text=argocd%20appset%20create%20,List%20ApplicationSets)).
  This is useful to validate your generators are producing the intended results.

### 1.3 Examples for Common ApplicationSet Generators

To illustrate, here are some concise examples for each generator type:

- **List Generator Example**: Suppose you want to deploy an “nginx” Application to two namespaces (staging and prod) on
  the same cluster:

  ```yaml
  apiVersion: argoproj.io/v1alpha1
  kind: ApplicationSet
  metadata:
    name: nginx-environments
  spec:
    generators:
      - list:
          elements:
            - environment: staging
              namespace: staging-ns
            - environment: production
              namespace: prod-ns
    template:
      metadata:
        name: 'nginx-{{environment}}'
      spec:
        project: default
        source:
          repoURL: https://github.com/example/nginx-manifests.git
          targetRevision: HEAD
          path: ./
        destination:
          server: https://kubernetes.default.svc
          namespace: '{{namespace}}'
        syncPolicy:
          automated:
            prune: true
  ```

  This will create two ArgoCD Applications: `nginx-staging` and `nginx-production`, each deploying to its respective
  namespace.

- **Cluster Generator Example**: Deploy a baseline monitoring stack to all clusters:

  ```yaml
  spec:
    generators:
      - clusters:
          selector:
            matchLabels:
              stage: prod
    template:
      metadata:
        name: '{{name}}-monitoring'
      spec:
        project: infra
        source:
          repoURL: https://github.com/example/monitoring.git
          targetRevision: v1.0.0
          path: k8s/
        destination:
          name: '{{name}}'
          namespace: monitoring
  ```

  If ArgoCD has clusters labeled `stage=prod`, each will get an Application e.g. `cluster1-monitoring`,
  `cluster2-monitoring`, etc. If a new cluster with that label is added, it gets an app; if one is removed, the app is
  deleted (unless `applicationsSync` policy is adjusted).

- **Git Directory Generator Example**: Deploy each microservice in a monorepo:

  ```yaml
  spec:
    generators:
      - git:
          repoURL: https://github.com/myorg/microservices.git
          revision: main
          directories:
            - path: 'services/*'
              exclude: 'services/common'
    template:
      metadata:
        name: '{{path.basename}}'
      spec:
        project: microservices
        source:
          repoURL: https://github.com/myorg/microservices.git
          targetRevision: main
          path: '{{path}}'
        destination:
          server: https://kubernetes.default.svc
          namespace: '{{path.basename}}'
  ```

  Each subfolder under `services/` (except `services/common`) will produce an Application named after the folder. So if
  you have `services/auth` and `services/payment`, you get `auth` and `payment` apps deployed to namespaces `auth` and
  `payment` respectively. The generator will ignore folders starting with `.` by default (e.g., `.git`)
  ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=match%20at%20L364%20The%20Git,git)).

- **Git File Generator Example**: Deploy infrastructure per cluster using cluster config files:

  - Repo structure:

    ```
    cluster-configs/
      clusterA/config.json
      clusterB/config.json
    apps/
      base-manifests/   (common app manifests)
    ```

  - ApplicationSet:

    ```yaml
    generators:
      - git:
          repoURL: https://github.com/myorg/infra.git
          revision: HEAD
          files:
            - path: 'cluster-configs/*/config.json'
    template:
      metadata:
        name: '{{path.basename}}-infra'
      spec:
        project: infra
        source:
          repoURL: https://github.com/myorg/infra.git
          targetRevision: HEAD
          path: 'apps/base-manifests'
        destination:
          server: '{{ cluster.address }}'
          namespace: infra
    ```

    The Git file generator will read each config.json (say clusterA’s file contains
    `{"cluster":{"name": "clusterA", "address":"https://1.2.3.4"}, "env":"dev"}` etc). It flattens those JSON fields
    into parameters like `cluster.name`, `cluster.address`, etc.
    ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=aws_account%3A%20123456%20asset_id%3A%2011223344%20cluster,dev%20cluster.address%3A%20https%3A%2F%2F1.2.3.4))
    ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=In%20addition%20to%20the%20flattened,following%20generator%20parameters%20are%20provided)),
    which we use in template (`{{cluster.address}}`). It also provides special parameters like `{{path.basename}}`
    (which here would be `clusterA` and `clusterB`)
    ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=following%20generator%20parameters%20are%20provided%3A)).
    So this yields two Applications: `clusterA-infra` and `clusterB-infra`, each pointed at their respective cluster API
    and deploying the base manifests. This approach cleanly separates cluster-specific data (in config files) from app
    manifests.

- **SCM Provider Generator Example** (GitHub org scanning): Automatically deploy any repo that contains a helm chart for
  a service:

  ```yaml
  generators:
    - scmProvider:
        github:
          organization: myorg
          tokenRef:
            secretName: github-token
            key: token
        filters:
          - pathsExist: ['helm/Chart.yaml'] # only repos that have a Helm chart
  template:
    metadata:
      name: '{{repository}}-helm-release'
    spec:
      project: default
      source:
        repoURL: https://github.com/myorg/{{repository}}.git
        targetRevision: '{{ default_branch }}'
        path: helm
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{repository}}'
      syncPolicy:
        automated: {}
  ```

  This would scan all repos in **myorg** and for each repo where a `helm/Chart.yaml` file exists at root, it creates an
  Application. The template uses provided parameters like `{{repository}}` (repo name) and `{{ default_branch }}` (the
  repo’s default branch) to fill in values. This way, developers just create a repo with a Helm chart and, without any
  additional config, ArgoCD will deploy it.

- **Pull Request Generator Example**: (already discussed in preview env use case above) – each PR gets its own
  Application.

- **Matrix Generator Example**: Suppose you have two data centers (us-east, us-west) and three apps. Using matrix:

  ```yaml
  generators:
    - matrix:
        generators:
          - list:
              elements:
                - region: us-east
                - region: us-west
          - list:
              elements:
                - app: analytics
                - app: frontend
                - app: backend
  template:
    metadata:
      name: '{{region}}-{{app}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/myorg/{{app}}.git
        targetRevision: main
        path: k8s
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{app}}-{{region}}'
  ```

  This will produce 2 (regions) x 3 (apps) = 6 Applications: us-east-analytics, us-east-frontend, us-east-backend, and
  similarly for us-west. Each app deploys to a namespace combining app and region. This demonstrates multi-dimensional
  param expansion.

- **Merge Generator Example**: If you maintain separate sources of truth (like a cluster registry and an app list) and
  want to deploy apps only to specific cluster types:

  ```yaml
  generators:
    - merge:
        mergeKeys: ['env']
        generators:
          - list:
              elements:
                - env: dev
                  app: testservice
                - env: prod
                  app: testservice
          - list:
              elements:
                - env: prod
                  clusterLabelSelector: stage=prod
          - clusters:
              selector:
                matchLabels:
                  stage: prod
        # The above intends: Only for env=prod, get clusters with stage=prod
  template:
    metadata:
      name: '{{app}}-{{name}}' # app name + cluster name
    spec: ...
  ```

  While this specific example is abstract, the idea is the first generator lists app & env combos, the second provides
  cluster selection criteria for env=prod, and the third yields actual cluster info. The merge on `env` will attach
  cluster info only to the prod env entries, resulting in Applications for `testservice` on each prod cluster, but none
  on dev (depending on how merge is set up). Merge is tricky and used in advanced cases.

**Error handling & debugging ApplicationSets:** Many issues can arise with ApplicationSets:

- If Applications aren’t appearing or are wrong, first inspect the **ApplicationSet status conditions**
  (`kubectl get applicationset <name> -o yaml`). Errors like inability to connect to Git (`RepoServerTimeout` or
  similar), template rendering issues, or duplicate name conflicts will surface there.
- A common mistake is forgetting to include a field in the template’s metadata.name that differentiates outputs. If two
  generator outputs produce the same Application name, the controller will usually update one Application repeatedly or
  fail to create the duplicate. The status might show an error about duplicate Application if it conflicts.
- For Pull Request generators, ensure the ArgoCD ApplicationSet controller has network access to the SCM API (if running
  in a cluster without internet, the API calls might fail – use a proxy or mirror if needed).
- Debugging tip: Use `argocd appset get <name>` to see a summary, or `argocd appset list` to see all sets
  ([argocd appset Command Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_appset/#:~:text=,appset%20get%20APPSETNAME)).
  The CLI also offers a dry-run for create as mentioned (to preview output without applying)
  ([argocd appset create Command Reference - Argo CD - Declarative GitOps ...](https://argo-cd.readthedocs.io/en/latest/user-guide/commands/argocd_appset_create/#:~:text=Dry,output)).
- If using a **plugin generator** and nothing happens, check that the ApplicationSet controller actually has the plugin
  execution configured (this might involve mounting scripts or containers – refer to ArgoCD docs on plugin generators).
  The controller logs will show what it tried to do.
- **Synchronization issues**: The ApplicationSet will continuously reconcile. If someone manually edits a generated
  Application (which is generally discouraged, as ApplicationSet will overwrite changes), those changes will be reverted
  on the next reconcile. If you see an Application spec “jumping back” after you edit it, remember it’s managed by
  ApplicationSet – the source of truth is the ApplicationSet template in Git.
- If ApplicationSet is deleting and re-creating apps too often, check if the template or generator outputs have
  non-deterministic values (like timestamps or random ordering). For instance, list generator elements should be sorted
  or stable; otherwise the diff may cause churn. In goTemplate mode, be careful not to include variables that can change
  on each evaluation.

**Debugging cascade deletion**: If an ApplicationSet is deleted, by default it will also delete all generated
Applications (since they have ownerReferences to the ApplicationSet). If `preserveResourcesOnDeletion:true` was set,
those Applications will be deleted but their workloads will remain in clusters. In such scenario, you must manually
clean up or re-adopt those resources. It’s usually safer to let ArgoCD handle deletions unless you intentionally want to
orphan deployments for analysis.

## 2. Argo Rollouts Structure and Progressive Delivery

**Argo Rollouts** is a Kubernetes controller (and set of CRDs) that implements advanced deployment strategies beyond the
standard RollingUpdate. With Argo Rollouts, you define a **Rollout** (a replacement for a Deployment) which supports
**Canary**, **Blue-Green**, and other progressive delivery features like manual promotion, automated analysis, and
experimentations. It integrates with various service meshes and ingress controllers for traffic shifting, and with
metric providers for automated analysis (for example, using Prometheus or other analytics to decide if a rollout is
healthy)
([Argo Rollouts | Argo](https://argoproj.github.io/rollouts/#:~:text=Argo%20Rollouts%20is%20a%20Kubernetes,progressive%20delivery%20features%20to%20Kubernetes))
([Argo Rollouts | Argo](https://argoproj.github.io/rollouts/#:~:text=Argo%20Rollouts%20,or%20rollback%20during%20an%20update)).

A **Rollout** CRD spec resembles the Kubernetes Deployment spec (pods template, replicas, selectors) but adds a
`strategy` section for the advanced rollout behavior. Below is the full YAML structure of a Rollout with all possible
fields and strategies:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: example-rollout
spec:
  replicas: 5 # Number of desired pods (just like Deployment) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,runs%20and%20experiments%20to%20be))
  selector:
    matchLabels:
      app: guestbook # Pod label selector (should match template labels) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,selector%3A%20matchLabels%3A%20app%3A%20guestbook))
  template:
    metadata:
      labels:
        app: guestbook
    spec:
      containers:
        - name: guestbook
          image: argoproj/rollouts-demo:blue # Initial version image ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,demo%3Ablue)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=containers%3A%20,demo%3Ablue))
          ports:
            - containerPort: 80
  minReadySeconds: 30 # Minimum time a new pod should be ready before considering it available ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,minReadySeconds%3A%2030))
  revisionHistoryLimit: 3 # How many old ReplicaSets to keep (default 10) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,Defaults%20to%2010%20revisionHistoryLimit%3A%203))
  paused: false # Start in a paused state or not (defaults false). If true at creation, it won't scale up until unpaused. ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,paused%3A%20true))
  progressDeadlineSeconds: 600 # Time (sec) to consider rollout failed if new RS doesn't progress (default 600s) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,Defaults%20to%20600s%20progressDeadlineSeconds%3A%20600))
  progressDeadlineAbort: false # If true, automatically abort the rollout when progressDeadlineSeconds is exceeded (default false) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,progressDeadlineAbort%3A%20false))
  restartAt: '2025-03-01T12:00:00Z' # (Optional) Timestamp to trigger a restart of all pods (Rollout will rotate pods when this is set) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,30T21%3A19%3A35Z))
  rollbackWindow: # (Optional) Enables fast rollback to recent stable revisions
    revisions: 3 # Allow rollback to any of last 3 revisions quickly ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,rollbackWindow%3A%20revisions%3A%203))
  # Optional analysis history limits (how many AnalysisRuns/Experiments to keep in history)
  analysis:
    successfulRunHistoryLimit: 10 # Successful analysis runs history to keep (default 5) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=replicas%3A%205%20analysis%3A%20,Inconclusive))
    unsuccessfulRunHistoryLimit: 10 # Failed or inconclusive runs to keep (default 5) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,unsuccessfulRunHistoryLimit%3A%2010))

  # Either 'workloadRef' or 'template' is used. (workloadRef allows referring to an existing Deployment instead of specifying template)
  workloadRef:
    apiVersion: apps/v1
    kind: Deployment
    name: legacy-deployment
    scaleDown: progressively # Options: never, onsuccess, progressively – how to scale down the old Deployment if converting to Rollout ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,down%20after%20migrating%20to%20Rollout)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,progressively))
  # (If workloadRef is set, Rollout will manage that Deployment's ReplicaSets as if they were its own; not common in GitOps unless migrating)

  strategy:
    # BLUE-GREEN strategy configuration
    blueGreen:
      activeService: myapp-active # Service name that always points to the ACTIVE (stable) version ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=blueGreen%3A%20,service)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=activeService%3A%20active))
      previewService: myapp-preview # Service that points to the new version (before promotion) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=value%3A%20guestbook))
      previewReplicaCount: 1 # How many replicas to scale up for preview before switch (if not full) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,service))
      autoPromotionEnabled: false # If false, after new version is ready, do NOT auto switch – wait for manual promote ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,%2Boptional%20autoPromotionEnabled%3A%20false)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,%2Boptional%20autoPromotionEnabled%3A%20false))
      autoPromotionSeconds: 30 # If set (and autoPromotionEnabled true by default), automatically promote after this seconds delay ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=autoPromotionEnabled%3A%20false)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,%2Boptional%20autoPromotionSeconds%3A%2030))
      scaleDownDelaySeconds: 30 # Delay after switching traffic to scale down old version (default 30s) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,scaleDownDelaySeconds%3A%2030))
      scaleDownDelayRevisionLimit: 2 # Keep at most 2 old versions running (with delay) before scaling down (if you need to see multiple) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=scaleDownDelaySeconds%3A%2030))
      abortScaleDownDelaySeconds: 30 # If rollout is aborted, how long to wait before scaling down the preview (0 means don't scale down automatically on abort) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,is%2030%20second%20abortScaleDownDelaySeconds%3A%2030))
      antiAffinity: # (Optional) Anti-affinity rules to avoid placing active and preview pods on same nodes ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,100))
        requiredDuringSchedulingIgnoredDuringExecution: {} # enforce separation (empty means just enable default pod anti-affinity on hostname) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,100))
        # OR
        preferredDuringSchedulingIgnoredDuringExecution:
          weight: 1
          podAffinityTerm:
            labelSelector:
              matchExpressions:
                - key: app
                  operator: In
                  values: [guestbook]
            topologyKey: kubernetes.io/hostname
      activeMetadata: # (Optional) Extra metadata (labels/annotations) to add to pods on ACTIVE replicaset ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,optional%20activeMetadata%3A%20labels%3A%20role%3A%20active)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,optional%20activeMetadata%3A%20labels%3A%20role%3A%20active))
        labels:
          role: active
      previewMetadata: # (Optional) Metadata for pods on PREVIEW replicaset (removed after promotion) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,optional%20previewMetadata%3A%20labels%3A%20role%3A%20preview)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=their%20preview%20phase.%20,previewMetadata%3A%20labels%3A%20role%3A%20preview))
        labels:
          role: preview
      prePromotionAnalysis: # (Optional) Analysis run to execute before switching active service (i.e., while new RS is preview) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=activeService%3A%20active)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=%23%20Pre,svc.default.svc.kube.pc-tips.se))
        templates:
          - templateName: success-rate # Refers to an AnalysisTemplate name
        args:
          - name: service-name
            value: myapp-preview.default.svc.kube.pc-tips.se
      postPromotionAnalysis: # (Optional) Analysis to run after promotion (after traffic switched) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=value%3A%20guestbook)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=%23%20Post,svc.default.svc.kube.pc-tips.se))
        templates:
          - templateName: success-rate
        args:
          - name: service-name
            value: myapp-active.default.svc.kube.pc-tips.se

    # CANARY strategy configuration
    canary:
      canaryService: myapp-canary # Service for canary pods (for traffic splitting). **Required for traffic routing** ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,service)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,service))
      stableService: myapp-stable # Service for stable pods. **Required for traffic routing** ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,service)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=canaryService%3A%20canary))
      steps: # Sequence of steps to perform during the rollout ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,setWeight%3A%2020)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=steps%3A%20,setWeight%3A%2020))
        - setWeight: 20 # Step1: send 20% traffic to canary ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,setWeight%3A%2020)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=steps%3A%20,setWeight%3A%2020))
        - pause: {} # Step2: pause indefinitely (await manual resume) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,pause%3A%20duration%3A%201h)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=duration%3A%201h))
        - setWeight: 40 # Step3: (after resume) increase canary to 40%
        - pause: { duration: 60s } # Step4: pause for 60 seconds ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=steps%3A%20,setWeight%3A%2020)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=))
        - setWeight: 60 # Step5: ramp to 60%
        - analysis: # Step6: run an analysis before going further ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,rate)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,rate))
            templates:
              - templateName: conformance-check
        - setWeight: 100 # Step7: (final step) go to 100% - essentially promote canary to stable
      # (After final step, rollout is complete, stableService now points to new RS)
      maxUnavailable: 1 # Max pods unavailable during update (like Deployment maxUnavailable) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,immediately%20when%20the%20rolling)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,RC%2C%20ensuring%20that%20at%20least))
      maxSurge: '20%' # Max extra pods above desired during update (like Deployment maxSurge) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=maxUnavailable%3A%201)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,of))
      pause: # (Optional) Global rollout pause settings if needed (can define default duration, etc.)
        duration: 5m
      analysis: # (Optional) Background analysis to run during the rollout (parallel to traffic shifting) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,svc.default.svc.kube.pc-tips.se)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=analysis%3A%20templates%3A%20,svc.default.svc.kube.pc-tips.se))
        templates:
          - templateName: check-errors
        args:
          - name: stable-hash
            valueFrom:
              podTemplateHashValue: Stable # Example of using built-in dynamic values for analysis ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,hash%20valueFrom%3A%20podTemplateHashValue%3A%20Latest)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,hash%20valueFrom%3A%20podTemplateHashValue%3A%20Latest))
          - name: latest-hash
            valueFrom:
              podTemplateHashValue: Latest
      antiAffinity: # (Optional) Pod anti-affinity between canary and stable pods (to avoid co-locating) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=%23%20Anti,100)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=%23%20Anti,100))
        preferredDuringSchedulingIgnoredDuringExecution:
          weight: 1
          podAffinityTerm:
            labelSelector:
              matchLabels:
                app: guestbook
            topologyKey: kubernetes.io/hostname
      trafficRouting: # (Optional) Config for ingress/service-mesh traffic splitting (if not set, uses weight by scaling pods)
        # Optionally set maxTrafficWeight to change weight scale (default 100). e.g., maxTrafficWeight: 1000 to use 0-1000 weights ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,defaults%20to%20100%20maxTrafficWeight%3A%201000)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,is%20currently%20only%20required%20for))
        managedRoutes:
          - name: header-route-1 # If using header-based or mirror routing steps, define route names here ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=maxTrafficWeight%3A%201000%20,match%20the%20names%20from%20the)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=manage%20it%20is%20currently%20only,managedRoutes))
          - name: mirror-route
        istio: # Traffic routing via Istio virtual service ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=managedRoutes%3A%20,is%20a%20single%20route%20in)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=istio%3A%20,more%20virtualServices%20can%20be%20configured))
          virtualService:
            name: myapp-vsvc
            routes:
              - primary
          # virtualServices: [] (optionally multiple vs if splitting across multiple vservices)
        nginx: # NGINX Ingress controller routing ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,ingress)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,ingress%20annotationPrefix%3A%20customingress.nginx.ingress.kubernetes.io%20%23%20optional))
          stableIngress: myapp-ingress
          # or stableIngresses: [myapp-ingress] (multiple ingress resources if needed)
          annotationPrefix: nginx.ingress.kubernetes.io # (Optional) custom annotation prefix if NGINX not default
          additionalIngressAnnotations: # (Optional) extra annotations to add when canary is active
            canary-by-header: X-Canary-Version
            canary-by-header-value: 'true'
          canaryIngressAnnotations: # (Optional) annotations specifically for canary Ingress
            nginx.ingress.kubernetes.io/canary: 'true'
        alb: # AWS ALB Ingress controller routing ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,optional))
          ingress: myapp-alb-ingress
          servicePort: 80
          annotationPrefix: alb.ingress.kubernetes.io
        smi: # Service Mesh Interface (Linkerd, etc.) routing ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,split%20%23%20optional))
          rootService: myapp
          trafficSplitName: myapp-traffic-split

    # Optional additional features (apply to either strategy):
    canaryMetadata: # Extra metadata for pods in canary RS (exists only during update) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,canaryMetadata%3A%20annotations%3A%20role%3A%20canary%20labels)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,role%3A%20canary%20labels%3A%20role%3A%20canary))
      labels:
        version: canary
      annotations:
        note: 'This pod is on canary'
    stableMetadata: # Metadata for pods in stable RS ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,role%3A%20stable%20labels%3A%20role%3A%20stable)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=stableMetadata%3A%20annotations%3A%20role%3A%20stable%20labels%3A,role%3A%20stable))
      labels:
        version: stable
    scaleDownDelaySeconds: 30 # (If using traffic routing) delay before scaling down previous RS after services switch (default 30) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=maxSurge%3A%20%2720)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,traffic%20routing))
    scaleDownDelayRevisionLimit: 2 # Limit how many old RS can run with delay (beyond this, older ones are scaled down immediately) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=minPodsPerReplicaSet%3A%202)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,Defaults%20to%20nil%20scaleDownDelayRevisionLimit%3A%202))
    abortScaleDownDelaySeconds: 30 # After aborting (in canary strategy), wait before scaling down canary pods (0 to keep them) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,abortScaleDownDelaySeconds%3A%2030)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,abortScaleDownDelaySeconds%3A%2030))
    dynamicStableScale: false # (Canary + traffic routing only) If true, as canary scale increases, auto scale down stable pods to not exceed total replicas ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,dynamicStableScale%3A%20false)) ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=canary%20pods%20increases%20,dynamicStableScale%3A%20false))
```

This YAML is complex. In practice, you will choose either **blueGreen** or **canary** under `strategy`:

### 2.1 Blue-Green Strategy in Argo Rollouts

**Blue-Green** (also known as Red/Black) is a strategy where you have two environments: one active (serving all traffic
– “blue”) and one new version (idle or serving test traffic – “green”). Once the new version is ready, a switch flips
all traffic from blue to green (making green the new active). In Kubernetes, this is achieved by maintaining two sets of
pods (ReplicaSets) and typically two services: one that always points to the active pods, and one that points to the new
ones for preview.

Key fields for BlueGreen in a Rollout spec:

- **activeService**: The Service name that always routes to the current active (stable) pods
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=blueGreen%3A%20,service)).
  The Rollouts controller updates this service’s selector to point to the stable ReplicaSet (once new is promoted, it
  points to new RS). This Service should exist and have a selector matching the pod labels (usually something like
  `app=myapp,rollouts-pod-template-hash=<hash>` of stable RS).
- **previewService**: (Optional) A Service that routes to the new ReplicaSet’s pods (the “green” pods)
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=value%3A%20guestbook)).
  If specified, the controller will update this service’s selector to match the new pods during the rollout. This allows
  the new version to be reachable (for testing) before it receives production traffic.
- **previewReplicaCount**: (Optional) If you want to scale up only a subset of the new version pods for preview, you can
  set this to a number (e.g., 1)
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,service)).
  By default, when you start a blue-green deployment, the new ReplicaSet is scaled to full `spec.replicas`. By setting
  previewReplicaCount, the new RS will initially scale only that many pods (for testing on preview service). When you
  decide to promote, Argo Rollouts will scale it up to full before switching services.
- **autoPromotionEnabled**: If true (default), Argo Rollouts will automatically promote the new version to active once
  it’s healthy. If false, the Rollout will pause indefinitely after the new ReplicaSet is fully up, waiting for manual
  promotion
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,%2Boptional%20autoPromotionEnabled%3A%20false)).
  Setting this to false is useful when you want a human approval or external signal before switching traffic.
- **autoPromotionSeconds**: If autoPromotionEnabled is true, you can add a delay (seconds) before auto-promote
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,%2Boptional%20autoPromotionSeconds%3A%2030)).
  For example, `autoPromotionSeconds: 180` would automatically switch traffic to the new version 3 minutes after it
  becomes fully available, unless manually promoted sooner.
- **scaleDownDelaySeconds**: After switching the active Service to the new pods, how long to wait before scaling down
  the old (previously active) ReplicaSet
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,scaleDownDelaySeconds%3A%2030)).
  Default is 30 seconds. This delay can help ensure that in-flight traffic or DNS/IP table updates have time to
  propagate before killing old pods. In production, a small delay (30s or more) is recommended
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,scaleDownDelaySeconds%3A%2030)).
  During this time, the old pods still exist (and the activeService now points to new pods, so ideally old pods are
  serving 0 traffic unless some lagging requests).
- **scaleDownDelayRevisionLimit**: Normally only one old ReplicaSet (the last active) might be kept during delay. This
  field lets you have multiple older versions running (to a limit) before they scale down. For example,
  `scaleDownDelayRevisionLimit: 2` means the controller can keep up to 2 prior ReplicaSets around with delay before
  scaling down; older than that get scaled down immediately
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=scaleDownDelaySeconds%3A%2030)).
- **abortScaleDownDelaySeconds**: If the rollout is aborted (meaning something failed and we decide not to proceed with
  new version), this controls whether to keep the preview pods running or not. Default 30 sec – after abort, preview
  pods scale down after 30s
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,is%2030%20second%20abortScaleDownDelaySeconds%3A%2030)).
  Setting 0 means if you abort, it leaves the preview pods running (for debugging perhaps).
- **antiAffinity**: An optional pod anti-affinity rule to avoid co-locating the new and old pods on the same node
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,100)).
  In blue-green, this can ensure the two versions run on separate nodes (useful if you want isolation). The above
  example shows `requiredDuringSchedulingIgnoredDuringExecution: {}` which basically means “hard requirement: don’t
  schedule new pods on nodes that have old pods”. If you set a `preferred` with weight, it’s a soft rule. Argo Rollouts
  by default will add a hostname anti-affinity if you specify even an empty required (which defaults to hostName
  anti-affinity between versions).
- **activeMetadata/previewMetadata**: You can specify labels or annotations to _add_ to the pods depending on their
  status (active or preview)
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,optional%20activeMetadata%3A%20labels%3A%20role%3A%20active))
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,optional%20previewMetadata%3A%20labels%3A%20role%3A%20preview)).
  For instance, you might label active pods with `role=active` and preview pods with `role=preview` to differentiate
  them (as shown). These metadata are injected by the controller dynamically. Preview metadata is only on the new RS
  pods _until_ promotion; once promoted, the preview labels are removed (since they become active) and the
  activeMetadata might be applied.
- **prePromotionAnalysis**: Optionally, an **analysis run** to perform before the promotion (traffic switch)
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=activeService%3A%20active)).
  This references one or more AnalysisTemplates. For example, you could run a smoke test or validate metrics on the new
  pods while they are serving on the preview service. If the analysis fails (maybe error rate is too high, or a test job
  fails), the Rollout will abort promotion (and depending on settings, might rollback). In the example, an
  AnalysisTemplate named “success-rate” is run, perhaps checking that the preview service has <5% error rate, etc. If
  prePromotion analysis fails, the rollout will not proceed to switch the active service.
- **postPromotionAnalysis**: Similarly, an analysis to run after traffic has been switched to the new pods (but before
  scaling down the old pods)
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=%23%20Post,svc.default.svc.kube.pc-tips.se)).
  This could double-check things like latency under real load, or other business metrics. If this fails, the rollout can
  be aborted/rolled back even after switching (Argo Rollouts can roll back by swapping activeService back to old RS if
  needed).

A **Blue-Green rollout process** typically goes:

1. Rollout creates new ReplicaSet (“green”) with either full or `previewReplicaCount` pods.
2. If `autoPromotionEnabled: false`, the Rollout enters a **Paused** state waiting. In ArgoCD or CLI, you’d see status
   “Paused, waiting for manual promotion”.
3. (Optional) Pre-promotion analysis runs while in paused state (if configured).
4. An admin can then promote manually (via CLI or ArgoCD UI) – or if autoPromotion is true, after `autoPromotionSeconds`
   it proceeds.
5. On promotion: Rollouts scales new RS to full (if it wasn’t already), then switches the selector on `activeService` to
   the new RS pods. Now “green” is live, “blue” is still running but receiving no traffic (because activeService moved).
6. (Optional) Post-promotion analysis runs. If it fails and abort on failure is configured (Rollouts by default will
   mark Rollout degraded and you can manually decide to rollback; you can also set automated rollback on certain
   analysis failure conditions).
7. After `scaleDownDelaySeconds`, the old RS (“blue”) pods are scaled down to 0. The rollout is considered complete
   (status Healthy).
8. If at any point a failure or abort occurs, by default Argo Rollouts **pauses** the rollout in a degraded state (it
   does not automatically rollback unless told via analysis or you manually do). You can then choose to rollback by
   changing the spec back or using CLI to undo (or if you set `progressDeadlineAbort: true`, hitting the progress
   deadline triggers an automatic rollback abort).

**Integration with ArgoCD (Blue-Green)**: ArgoCD will treat a Rollout just like another resource. It will apply the
changes (like updating the Rollout spec for a new image). The actual traffic switching and scaling is handled by Argo
Rollouts controller, not ArgoCD. From a GitOps perspective, when you want to deploy a new version:

- You update the Rollout manifest in Git (e.g., change the container image tag).
- ArgoCD syncs the change to the cluster (Rollout spec gets updated).
- Argo Rollouts notices the template changed (new image) and starts the blue-green process.
- If `autoPromotionEnabled:false`, ArgoCD will show the Application as **Healthy** only when the rollout finishes.
  Before promotion, Argo Rollouts will mark the Rollout resource as _Paused_ (which by default is considered **Healthy**
  because the old version is still serving and new one is waiting; ArgoCD’s health assessment for a Rollout might show
  “Progressing” or “Paused”). You can configure ArgoCD custom health checks so that a Rollout in paused state is treated
  as Progressing instead of Healthy, depending on preference.
- You then promote via Argo Rollouts CLI or ArgoCD UI (ArgoCD has an action for Rollouts if you install the Rollouts
  plugin – e.g., in the UI you can click “Promote” or “Abort” as seen in Red Hat’s example
  ([How to do blue/green and canary deployments with Argo Rollouts](https://www.redhat.com/en/blog/blue-green-canary-argo-rollouts#:~:text=In%20the%20ArgoCD%20interface%2C%20click,choose%20Abort%20to%20back%20out))
  ([How to do blue/green and canary deployments with Argo Rollouts](https://www.redhat.com/en/blog/blue-green-canary-argo-rollouts#:~:text=You%20could%20do%20the%20same,of%20the%20rollout%20by%20using))).
- Once promoted and old scaled down, Rollout status becomes Healthy (with new version stable). ArgoCD sees no diff (the
  spec in Git is now the same as live), and the app is Healthy.

Blue-Green is great for scenarios where you want a quick toggle between versions and possibly running both versions
concurrently (for a short time) to do comparisons or run tests.

**Blue-Green Best Practices:**

- Ensure your `activeService` and `previewService` have proper selectors that match the pods. Typically, Argo Rollouts
  uses label `rollouts-pod-template-hash` and adds that to selectors. You usually configure your Service selectors with
  stable identifiers (like `app=myapp` and perhaps `role=active` for activeService if using activeMetadata).
- DNS or client cache: If clients (or ingress) route by service name, the switch is near-instant in Kubernetes service
  controller, but external clients may have DNS cache (if using external DNS). In such cases consider using
  ingress-based routing (which can also be managed by Rollouts trafficRouting with stable and canary service).
- Use analysis runs to automate checks – for example, automatically abort if new version pods have high error rates
  _before_ switching (prePromotion) or _after_ switching (postPromotion).
- If abort happens after switching (postPromotion), you may need to manually intervene to switch back traffic. Argo
  Rollouts does not automatically revert service selector unless you explicitly configured it (by detecting analysis
  failure and doing rollback steps in your workflow).
- Monitor the Rollout’s events (kubectl describe rollout <name>) during a blue-green. Events will show phases like
  “Switching active service to new RS”, etc. These are helpful for debugging timing issues.

### 2.2 Canary Strategy in Argo Rollouts

**Canary** strategy involves gradually shifting traffic from the stable version to the new version in increments,
potentially with pauses and verifications at each step. Unlike blue-green, canary typically has both versions serving
live traffic simultaneously, but the new version starts with a small percentage and increases over time until it’s 100%.

Key fields for Canary in Rollout spec:

- **canaryService** and **stableService**: If you want to do **traffic shaping** via ingress or service mesh, you need
  two services
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,service)).
  The stableService always selects the stable pods, and the canaryService selects the canary pods. These are analogous
  to active/preview in blue-green but used differently: in canary, both may receive traffic concurrently. You then
  configure ingress or service mesh to split traffic between these two services (e.g., Istio VirtualService splitting
  80/20 between stableService and canaryService). **If you do not specify these, Argo Rollouts will perform a basic
  canary by scaling** – meaning it will simply scale up/down pods to reach approximate percentages (this is less
  precise).
  - For GitOps best practice, use service-based traffic routing (with ingress or mesh) if you can, as it provides
    accurate traffic percentages and zero-downtime. The Rollout’s `trafficRouting` section (discussed below) must be
    configured for your specific ingress/mesh.
- **steps**: A list of steps to execute in order
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,setWeight%3A%2020)).
  Each step can be one of:

  - `setWeight`: sets the traffic weight that should go to canary pods
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,setWeight%3A%2020)).
    If using service mesh/ingress, this weight is enforced at the network level. If not, the controller will try to
    scale pods to approximately achieve that fraction (e.g., 20% of replicas).
  - `pause`: can be either indefinite (`pause: {}`) which pauses until manually resumed, or with a `duration` (s, m, h)
    to automatically resume after that time
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,pause%3A%20duration%3A%201h)).
  - `analysis`: run an analysis (inline) at that point
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,rate)).
    You specify templates (similar to pre/post analysis but in sequence).
  - `experiment`: launch an experiment (multiple test workloads) at that point
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,rate))
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,acceptable%20if%20name%20is%20not)).
  - `setCanaryScale`: advanced step (when using traffic routing) to set the number of canary pods explicitly without
    changing traffic percentage
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,setCanaryScale%3A%20replicas%3A%203))
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=)).
    For example, `setCanaryScale: replicas: 3` will scale canary RS to 3 pods regardless of weight.
    `setCanaryScale: weight: 25` scales canary pods to 25% of desired (if maxTrafficWeight is default 100). Or
    `matchTrafficWeight: true` to tie canary pod count to traffic weight (default behavior).
  - `plugin`: execute a custom plugin at this step (extend rollout steps with your own logic via a Step Plugin)
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=)).
    This requires configuration of a plugin in the controller (advanced usage).
  - `setHeaderRoute` / `setMirrorRoute`: advanced steps for Istio to route traffic based on headers or mirror traffic
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,in%20spec.strategy.canary.trafficRouting.managedRoutes))
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,created%20by%20argo%20rollouts%20this)).
    For example, `setHeaderRoute` can direct 100% of requests with a certain header to the canary (useful for testing by
    specific users)
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,to%20apply%20the%20match%20rules)).
    `setMirrorRoute` will copy a percentage of traffic to the canary service as a shadow (the canary receives that
    traffic in addition to stable receiving 100%)
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,a%20removal%20of%20the%20route))
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=name%3A%20%27header,exact%2C%20regex%2C%20prefix)).

  The `steps` sequence in the example gradually increased weight 20% -> pause -> 40% -> pause 60s -> 60% -> analysis ->
  100%. You can design any sequence. If a Rollout reaches the end of the steps, that typically means canary is fully
  promoted (100%). If a step has an indefinite pause, the rollout will remain paused at that step until intervention (or
  until a timeout if you later script one).

- **maxUnavailable / maxSurge**: Similar to how Deployments have these in RollingUpdate, they apply in canary during
  scaling
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,immediately%20when%20the%20rolling))
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=maxUnavailable%3A%201)).
  If using traffic routing (canaryService/stableService), these mainly apply during initial scaling of new RS. Usually
  you’d leave these default (1 and 1) or tune them if you need to control resource usage. For example, if you have 10
  replicas and do a setWeight 50%, with maxSurge 1, it might create one extra pod at a time.
- **pause** (top-level under canary): You can set a default duration for automated pauses or other global pause settings
  if needed. Often each pause step defines its own behavior, so this is less used.
- **analysis (background analysis)**: Under canary.strategy, `analysis` specifies a continuous or background analysis
  run that starts when update begins and possibly runs alongside the steps
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,svc.default.svc.kube.pc-tips.se)).
  This is different from an analysis step: a background analysis doesn’t block the rollout unless configured to (it can
  be configured to abort rollout on failure or not). It’s more like a continuous monitor while canary progresses. In the
  example, it runs a template `check-errors` with some args referencing stable and latest hashes
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,hash%20valueFrom%3A%20podTemplateHashValue%3A%20Latest)).
  If that analysis detects problems, it can mark rollout as Failed or Inconclusive which can trigger a pause or abort.
- **antiAffinity**: Similar to blue-green, to avoid placing canary and stable pods on same node
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=%23%20Anti,100)).
  This can ensure a failure domain separation (so that a bad node won’t affect both sets at once).
- **trafficRouting**: The section where you configure specifics for your ingress or service mesh:

  - `managedRoutes`: a list of route names the Rollout can manage for header/mirror routes
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=maxTrafficWeight%3A%201000%20,match%20the%20names%20from%20the)).
    If you plan to use `setHeaderRoute` or `setMirrorRoute` steps, you must list the route names here. Rollouts will
    insert these routes into your VirtualService or Ingress in the order specified.
  - `istio`: If using Istio, specify the VirtualService(s) and routes that should be modified
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=istio%3A%20,more%20virtualServices%20can%20be%20configured)).
    Typically you give the VS name and the route name within it. Rollouts will then adjust the weights on that
    VirtualService according to setWeight steps.
  - `nginx`: If using NGINX Ingress with nginx’s canary annotations, provide the base ingress name(s)
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,ingress)).
    Rollouts will duplicate the Ingress with `-canary` annotations to split traffic. `annotationPrefix` can be set if
    using a custom build of NGINX ingress that expects different annotation keys
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,annotation.mygroup.com%2Fkey%3A%20value)).
    You can also specify additional annotations for when canary is active (like enabling NGINX canary via
    `canary: "true"` on the canary ingress)
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=optional%20additionalIngressAnnotations%3A%20%23%20optional%20canary,annotation.mygroup.com%2Fkey%3A%20value)).
  - `alb`: For AWS ALB ingress, provide the ingress name and service port etc.
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,optional)).
    Rollouts will adjust the ALB target group weights.
  - `smi`: For Service Mesh Interface (e.g., Linkerd or Consul), provide root Service name and an SMI TrafficSplit CR
    name
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,split%20%23%20optional)).
    Rollouts will create or manage a TrafficSplit object to direct traffic.
  - You configure only the one you use; others can be left out. If no trafficRouting is specified, Rollouts defaults to
    **pod scaling** for canary: meaning it will scale up new RS pods such that, for example, 20% weight means roughly
    20% of pods are new (which means 2 new, 8 old if 10 total). This approach is less exact (traffic isn’t guaranteed
    20/80, it’s random which pods get requests if behind same service) and can momentarily violate maxUnavailable/Surge
    precisely when adjusting. However, it’s simpler as it doesn’t require service mesh/ingress.

- **canaryMetadata / stableMetadata**: Just like active/preview in blue-green, you can label/annotate canary pods
  differently from stable ones
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,canaryMetadata%3A%20annotations%3A%20role%3A%20canary%20labels))
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,role%3A%20stable%20labels%3A%20role%3A%20stable)).
  For instance, add `version: canary` label on canary pods for monitoring systems to distinguish them.
- **scaleDownDelaySeconds** (for canary with traffic routing): Similar to blue-green’s delay – after the rollout
  completes (traffic 100% to new), how long to keep the previous ReplicaSet around before scaling it down
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=maxSurge%3A%20%2720)).
  Default 30s. This is relevant mainly if you used service mesh/ingress. Without traffic routing, after final step, the
  old RS likely has been scaled down gradually anyway as weight increased.
- **scaleDownDelayRevisionLimit**: Same idea as in blue-green – how many older RS can be kept with delay.
- **abortScaleDownDelaySeconds**: If the rollout is aborted mid-canary (meaning we decide to stop releasing the new
  version), this controls whether to scale down the canary pods immediately or wait some time
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,abortScaleDownDelaySeconds%3A%2030)).
  If you abort, you typically want to keep stable serving. If abortScaleDownDelaySeconds is >0, the canary pods will
  hang around for that many seconds (maybe to allow debugging) before being deleted. If 0, they remain (so you could
  manually inspect them).
- **dynamicStableScale**: When using traffic routing, by default the stable ReplicaSet keeps all its pods until the very
  end (so during the canary, you temporarily have more pods than desired, because new pods come up in addition to old).
  If `dynamicStableScale: true`, Argo Rollouts will **scale down stable pods proportionally as canary pods scale up** to
  keep total = replicas count
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,dynamicStableScale%3A%20false)).
  For example, 10 replicas, weight 50% with dynamic scaling might run ~5 old + 5 new, instead of 10 old + 5 new. This
  saves resources but riskier if new fails (since you already scaled down some old). By default it’s false (meaning
  stable stays at full and you handle resource overhead by maxSurge etc).

A **Canary rollout process** example for the above spec:

1. Initially, stable pods = 5 (blue). We update image in Rollout spec.
2. Rollout creates canary ReplicaSet (green) with maybe 0 pods then:
   - Step1: setWeight 20. If using service mesh, it will route 20% of traffic via canaryService (and likely scale canary
     pods up to handle that load according to some minimum pods setting; by default at least 1 pod). If not using mesh,
     it scales canary RS to 1 pod (20% of 5 ≈ 1) and keeps stable at 5, achieving roughly 1/6 ~16% but it tries within
     maxSurge allowances to match 20%.
   - After applying weight, it moves to next step.
3. Step2: pause: {} – rollout is now **Paused**. It will wait indefinitely. In status, you’ll see something like
   “Paused - waiting for user action”. At this point: 1 canary pod (serving 20% ideally) and 5 stable pods (80%). An
   admin can check metrics, etc.
4. Admin decides to continue (or maybe ArgoCD UI’s Rollout actions are used). They run
   `kubectl argo rollouts promote example-rollout` (which resumes from the pause)
   ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery ...](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=,to%20fully%20promote%20the%20rollout))
   ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=,kubectl%20argo%20rollouts%20promote%20guestbook)).
5. Step3: setWeight 40. Now rollout increases canary pods to ~2 (40% of 5 = 2) or adjusts ingress weight to 40%. It may
   have also allowed a maxSurge, so possibly 2 canary + 5 stable (7 total) if not dynamically scaling stable.
6. Step4: pause for 60s. This pause has a duration, so the controller will automatically unpause after 60s. During this
   time, it’s monitoring. After 60s, it goes on.
7. Step5: setWeight 60. Now more canary pods (maybe 3) and weight 60%. Stable possibly still at 5 (or 4 if dynamic
   stable scale).
8. Step6: analysis step. The Rollout triggers an AnalysisRun using the referenced AnalysisTemplate `conformance-check`.
   This AnalysisRun might run tests or metric checks while the traffic is 60/40. The Rollout will **wait for analysis to
   complete** before proceeding. If the analysis comes back Failed or Inconclusive, the rollout will pause (and mark
   degraded). If Successful, rollout continues.
9. Step7: setWeight 100. This means send all traffic to canary (promote it). If using service mesh, it flips
   stableService to 0% or flips service selectors such that stable pods get no traffic. If not using trafficRouting, it
   scales canary to 5 and stable down to 0 (gradually within maxUnavailable etc).
10. Rollout is now considered complete – new RS is fully stable. The stableService (if used) now points to what was
    canary pods (or service selectors swapped).
11. The old RS (previous stable) has 5 pods still (if we didn't scale it down gradually). Now `scaleDownDelaySeconds`
    (30s) kicks in. After 30s, the old RS is scaled down to 0. That old RS is kept in history (you have
    `revisionHistoryLimit` old RS).
12. If any failure had happened at, say, step6 analysis, the rollout would pause at that step. You could then decide to
    abort (which means keep serving 60% new? Actually abort usually implies don’t continue increasing – by default abort
    will scale traffic back to 0 new? But Argo Rollouts doesn’t automatically rollback unless configured; “Abort” via
    CLI will attempt to terminate the rollout and optionally reset traffic to stable).
13. If `progressDeadlineSeconds` (600s) is exceeded without completing, the Rollout is marked **Degraded**
    (ProgressDeadlineExceeded) and if `progressDeadlineAbort: true`, it would also initiate an automatic rollback
    (basically treat as aborted)
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,Defaults%20to%20600s%20progressDeadlineSeconds%3A%20600))
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,progressDeadlineAbort%3A%20false)).

**Integration with ArgoCD (Canary)**: Similar to blue-green, ArgoCD applies the Rollout manifest changes. Argo Rollouts
handles the rest. Some considerations:

- ArgoCD will often consider the Application **Healthy** if at least the desired state is met (which might be tricky
  during canary). For instance, if using ArgoCD’s health checks, a Rollout is typically considered healthy when the
  status indicates the update is complete or paused. If a Rollout is mid-progress (e.g., 40% traffic shifted and
  paused), ArgoCD might show status **Progressing** or **Paused** depending on health check scripts. ArgoCD 2.3+
  includes a health assessment for Rollout: it’s healthy if rollout.status.health == Healthy, and progressing if
  updating, degraded if something failed
  ([How to do blue/green and canary deployments with Argo Rollouts](https://www.redhat.com/en/blog/blue-green-canary-argo-rollouts#:~:text=Name%3A%20%20%20%20,2))
  ([How to do blue/green and canary deployments with Argo Rollouts](https://www.redhat.com/en/blog/blue-green-canary-argo-rollouts#:~:text=Status%3A%20%20%20%20,2)).
- Promotion/pausing can be done via ArgoCD UI’s actions if the Rollouts plugin is enabled (which it often is by default
  in ArgoCD 2.x). The UI will offer “Resume”, “Pause”, “Abort”, “Promote” actions on a Rollout resource
  ([How to do blue/green and canary deployments with Argo Rollouts](https://www.redhat.com/en/blog/blue-green-canary-argo-rollouts#:~:text=In%20the%20ArgoCD%20interface%2C%20click,choose%20Abort%20to%20back%20out)).
  These actions call Argo Rollouts under the hood (they don’t modify Git; they use the Rollout’s CRD API via ArgoCD’s
  resource actions feature).
- You might include the Rollout’s AnalysisTemplates and other CRDs in the same Git folder so ArgoCD applies them as
  well. Ensure those are present or pre-created, otherwise the Rollout will reference a non-existent AnalysisTemplate.

**Canary Best Practices:**

- Use a **service mesh or ingress** for precise traffic control. Argo Rollouts supports Istio, NGINX, ALB, and others.
  For example, with Istio you define VirtualService with routes pointing to stable and canary services, and Argo
  Rollouts will adjust the weights
  ([Argo Rollouts | Argo](https://argoproj.github.io/rollouts/#:~:text=Argo%20Rollouts%20,or%20rollback%20during%20an%20update))
  ([Argo Rollouts | Argo](https://argoproj.github.io/rollouts/#:~:text=the%20new%20version%20during%20an,or%20rollback%20during%20an%20update)).
  This avoids the “approximate by scaling” approach which can overshoot or undershoot traffic.
- Determine your step weights and pause durations based on your app’s tolerance and metrics availability. E.g., start
  with a very low percentage (5% or 10%) to limit blast radius.
- Always have at least one pause (manual or automated) before 100% so you have a checkpoint to verify metrics. An
  indefinite pause for manual judgment (the classical “canary analysis approval”) is a common pattern – e.g., you might
  automate up to 50%, then require human approval to go to 100%.
- Leverage **AnalysisRuns** to automate decisions. Argo Rollouts can automate promotion or abort based on analysis. For
  instance, you can have an analysis step that if fails, causes the rollout to abort and optionally roll back. You can
  configure an AnalysisTemplate to return Inconclusive (which typically pauses the rollout) or Failed (which can mark it
  degraded).
- Use `progressDeadlineSeconds` and `progressDeadlineAbort` carefully. If you set `progressDeadlineAbort: true`, the
  rollout will automatically abort if stuck too long. This can be good to avoid long-running partial rollouts, but
  ensure your system or team is prepared to handle the abort (like monitoring alerts).
- Monitor Argo Rollouts metrics: The controller can emit Prometheus metrics about rollout status. Not directly a GitOps
  concern, but important for production – e.g., you can alert if a rollout is in degraded state for too long.

### 2.3 Analysis and Experiment in Argo Rollouts

**Analysis**: Argo Rollouts introduces **AnalysisTemplate** and **AnalysisRun** CRDs. An AnalysisTemplate defines one or
more metrics or tests to evaluate (could be a Prometheus query, a Datadog query, a job to run, a web URL to call, etc.)
([Argo Rollouts | Argo](https://argoproj.github.io/rollouts/#:~:text=Argo%20Rollouts%20,or%20rollback%20during%20an%20update))
([Argo Rollouts | Argo](https://argoproj.github.io/rollouts/#:~:text=the%20new%20version%20during%20an,or%20rollback%20during%20an%20update)).
AnalysisRuns are instances of those templates executed during a Rollout. In YAML, AnalysisTemplates have spec with
`metrics:` and each metric can have a provider (Prometheus, Wavefront, job, etc.) and success/failure conditions. While
not asked in detail by the prompt, be aware:

- Analysis can be triggered in **three ways**: prePromotion, postPromotion (BlueGreen) or as a step (or background) in
  Canary. The Rollout spec references AnalysisTemplates by name. Ensure those are applied to the cluster (ArgoCD should
  sync them from Git).
- A typical Analysis metric might query Prometheus for error rate over last 5 minutes. If above threshold, mark Failed.
- If an AnalysisRun fails, by default the Rollout will pause (analysis step will be considered failed and rollout enters
  paused state with status indicating analysis failure). You can mark metrics with `failureAssessment: false` to have
  them not fail the rollout, etc., or use web hooks to notify.
- **AnalysisRun CLI**: `kubectl argo rollouts get analysisrun <name>` would show details if needed. Also,
  `kubectl argo rollouts terminate analysisrun <name>` can stop a running analysis early (the CLI has a command for
  that)
  ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=,114))
  ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=,Security%20%20Security)).

**Experiment**: An Experiment CRD lets you run multiple versions concurrently for a short duration, mainly to compare
them (not necessarily to shift traffic gradually, but more to test in parallel). A Rollout can reference an Experiment
as a step:

- In the Rollout steps above, the `experiment:` step launched an experiment for 1h with two templates: baseline (stable)
  and canary, each with certain traffic share and an optional Service
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,rate))
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,acceptable%20if%20name%20is%20not)).
- The experiment had an analysis as well (`analyses:` within experiment step) to evaluate results
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=specRef%3A%20canary%20,be%20attached%20to%20the%20AnalysisRun)).
- Essentially, an Experiment is like a mini temporary rollout: you define spec.templates (which are basically ReplicaSet
  specs for baseline and canary), you can give them weights or fixed counts, and optionally route traffic via services
  to them (the experiment can create temporary services).
- After the duration, the experiment will scale down those pods. Based on analysis results you could then decide to
  proceed or not.
- Experiments are more advanced/edge-case usage (A/B testing or running a trial of two configs simultaneously). They are
  fully supported in GitOps by just defining the Experiment templates and referring to them.
- CLI: You can start an Experiment outside of a rollout too, via applying an Experiment CR.
  `kubectl argo rollouts get experiment <name>` to see status, or terminate it if needed.

### 2.4 Argo Rollouts CLI Commands and API Usage

Argo Rollouts comes with a kubectl plugin (or a standalone binary) `kubectl-argo-rollouts`. These commands allow you to
interact with Rollouts (much like how `kubectl` interacts with Deployments, plus rollout-specific features). Key CLI
commands include:

- **Get status**:

  - `kubectl argo rollouts get rollout <rollout-name> -n <namespace>` – Shows detailed status of a Rollout
    ([How to do blue/green and canary deployments with Argo Rollouts](https://www.redhat.com/en/blog/blue-green-canary-argo-rollouts#:~:text=Rollouts%20www,20%20ActualWeight%3A%2020%20Images))
    ([How to do blue/green and canary deployments with Argo Rollouts](https://www.redhat.com/en/blog/blue-green-canary-argo-rollouts#:~:text=%24%20oc%20argo%20rollouts%20get,2)),
    including current step, setWeight, which ReplicaSets are active, etc. This is similar to `kubectl describe` but
    formatted nicely with Rollout info. For example, it will list revision history and which RS is stable vs canary
    ([How to do blue/green and canary deployments with Argo Rollouts](https://www.redhat.com/en/blog/blue-green-canary-argo-rollouts#:~:text=%24%20oc%20argo%20rollouts%20get,2))
    ([How to do blue/green and canary deployments with Argo Rollouts](https://www.redhat.com/en/blog/blue-green-canary-argo-rollouts#:~:text=Namespace%3A%20%20%20%20,2)).
  - `kubectl argo rollouts list rollouts -n <ns>` – Lists all rollouts and their status (if plugin supports it, or use
    `kubectl get rollouts` as they are CRs).
  - `kubectl argo rollouts get experiment <experiment-name>` – Shows status of an Experiment (which templates running,
    etc).
  - `kubectl argo rollouts get analysisrun <analysisrun-name>` – Shows analysis results (metrics values, whether
    successful).

- **Promote / Resume**:

  - `kubectl argo rollouts promote <rollout-name> [--full]` – This command will resume a paused rollout. If `--full` is
    used, it will skip all remaining steps and proceed to full promotion
    ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery ...](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=Rollouts%20Promote%20,to%20fully%20promote%20the%20rollout))
    ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=Promotes%20a%20rollout%20paused%20at,to%20fully%20promote%20the%20rollout)).
    For a blue-green rollout paused before switching, `promote` triggers the switch (for blue-green, there is also a
    specific `Promote-full` in UI which likely corresponds to `--full`). For canary, `promote` basically means "continue
    through the steps or finish it". With `--full`, it jumps straight to 100% canary and completes immediately
    ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=Promotes%20a%20rollout%20paused%20at,to%20fully%20promote%20the%20rollout))
    ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=,full)).
  - In ArgoCD’s UI, as noted, the **vertical ellipsis (action menu)** on a Rollout allows “Promote” (which likely calls
    this CLI under the hood)
    ([How to do blue/green and canary deployments with Argo Rollouts](https://www.redhat.com/en/blog/blue-green-canary-argo-rollouts#:~:text=In%20the%20ArgoCD%20interface%2C%20click,choose%20Abort%20to%20back%20out)).
  - If a rollout has multiple pauses, each `promote` command only moves past the next pause (unless `--full`).

- **Abort**:

  - `kubectl argo rollouts abort <rollout-name>` – Aborts an in-progress rollout
    ([How to do blue/green and canary deployments with Argo Rollouts](https://www.redhat.com/en/blog/blue-green-canary-argo-rollouts#:~:text=You%20could%20do%20the%20same,of%20the%20rollout%20by%20using)).
    This will mark the Rollout as aborted. Behavior on abort: If using BlueGreen and new version wasn’t active yet, it
    simply scales down new and keeps old active. If using canary, it stops incrementing and will usually scale back up
    stable to 100%. It doesn’t automatically rollback to old version’s spec (because the old version is still running in
    parallel). Essentially abort stops the rollout where it is and makes the rollout status Degraded. In many cases,
    after an abort you’d then want to manually rollback (either via undo or by re-applying old image).
  - The Red Hat blog snippet shows `kubectl argo rollouts abort bluegreen` as a way to back out changes
    ([How to do blue/green and canary deployments with Argo Rollouts](https://www.redhat.com/en/blog/blue-green-canary-argo-rollouts#:~:text=You%20could%20do%20the%20same,of%20the%20rollout%20by%20using)).

- **Pause**:

  - `kubectl argo rollouts pause <rollout-name>` – Manually pause a rollout at the current point
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=match%20at%20L225%20,paused%3A%20true)).
    If you set a rollout running without an explicit pause step, you can still pause it via CLI (maybe to investigate
    something). The Rollout’s `spec.paused` field will be set true by this command. This is the same as editing the
    Rollout and setting `spec.paused: true` which one can do as well
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,paused%3A%20true)).
  - `kubectl argo rollouts resume <rollout-name>` – This is essentially the same as `promote` for resuming a manual
    pause (note: historically, there wasn’t a distinct resume command; `promote` and `kubectl patch` were used, but
    newer CLI might have an alias).

- **Rollback/Undo**:

  - `kubectl argo rollouts undo <rollout-name> [--to-revision=N]` – Similar to `kubectl rollout undo` for deployments,
    this will rollback the Rollout to a previous revision
    ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=,117))
    ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=,Contributing%20%20Contributing)).
    If you don’t specify `--to-revision`, it rolls back to the last stable revision (previous ReplicaSet). This
    essentially updates the Rollout spec’s template back to the old spec (old image, etc.). ArgoCD integration: if you
    have GitOps, doing an undo via CLI changes the live state but not Git – ArgoCD will detect the drift. For true
    GitOps, you’d ideally commit a rollback in Git. However, in emergencies, `kubectl argo rollouts undo` is a quick fix
    and you can sync Git later by either reverting commit or accepting the live change.

- **Update Image**:

  - `kubectl argo rollouts set image <rollout-name> <container>=<image:tag>` – This updates the Rollout’s template image
    field
    ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=,Rollouts%20Undo)).
    It’s akin to `kubectl set image deploy/...` but for Rollout. This is mostly for manual use; in GitOps, you’d update
    the manifest in Git instead. But it’s handy for testing or hot-fix outside the Git cycle.

- **Restart**:

  - `kubectl argo rollouts restart <rollout-name>` – This toggles the `spec.restartAt` field to now, causing the Rollout
    to restart pods (by updating that field, which the controller reacts to by cycling all pods)
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,progressDeadlineAbort%3A%20false)).
    It’s similar to `kubectl rollout restart`. Again, in GitOps context, use with caution because ArgoCD will see that
    spec change (if ArgoCD is tracking that field).

- **History**:

  - `kubectl argo rollouts history <rollout-name>` – Shows the revisions (ReplicaSets) and the image/tag for each
    revision, similar to Deployment history. This helps identify revision numbers for undo.

- **Analytics**:
  - `kubectl argo rollouts get analysisrun <name>` / `kubectl argo rollouts logs analysisrun <name>` – If an AnalysisRun
    spawned a job, you can fetch its logs, etc. Or `get analysisrun --watch` to see real-time metric evaluations.

These CLI commands interface with the Kubernetes API (they create/patch the Rollout resources). For automation, you can
also directly patch the Rollout CR:

- For example, to promote via API, one could `kubectl patch rollout myrollout --patch '{"spec":{"paused":false}}'` if it
  was paused. Or set `spec.pause` true to pause.
- The Argo Rollouts controller adds conditions and status fields (like `status.currentStepIndex`,
  `status.pauseConditions`, etc.) you can observe via `kubectl get rollout -o yaml`.

**API usage**: Since the question asks for API reference with request/response, note:

- ArgoCD has a REST/gRPC API (e.g., you can use ArgoCD’s API to create applications, list them, etc., which is beyond
  just kubectl). For example, `POST /api/v1/applications` with a JSON payload (same fields as YAML) will create an
  Application in ArgoCD
  ([argocd appset Command Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_appset/#:~:text=Options%20inherited%20from%20parent%20commands%C2%B6))
  ([argocd appset Command Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_appset/#:~:text=,web%20protocol.%20Useful%20if)).
  ArgoCD CLI uses this under the hood. In a company setting, one might script ArgoCD API calls to create or sync apps,
  but since we focus on GitOps, usually you push YAMLs to Git rather than call the API directly. Still, ArgoCD’s CLI
  (e.g., `argocd app create`) is essentially using that API.
- Argo Rollouts doesn’t have a separate REST API beyond the Kubernetes API for CRs. It exposes some metrics and
  optionally a GUI (Argo Rollouts comes with a UI that can be launched via `kubectl argo rollouts dashboard`). The
  dashboard is a UI to visualize rollouts, but not typically used in automation.
- If needed, one could operate Argo Rollouts via the Kubernetes API (e.g., a script using the K8s client to patch
  Rollout spec to promote, etc.). But the CLI abstracts that nicely.

For completeness, **ArgoCD CLI for Applications**:

- `argocd app list`, `argocd app get <name>` – list or get app details.
- `argocd app create -f app.yaml` – create an application from a manifest file
  ([argocd_appset.md - GitHub](https://github.com/argoproj/argo-cd/blob/master/docs/user-guide/commands/argocd_appset.md#:~:text=argocd_appset.md%20,as%20string%20Username%20to)).
- `argocd app delete <name>` – remove an application (optionally cascade delete resources or not, based on finalizer).
- `argocd app sync <name>` – manually trigger a sync (useful if auto-sync is off or if you want to retry immediately).
- `argocd app wait <name> --health --timeout 300` – wait until app is healthy (used in CI pipelines).
- `argocd app history <name>` – view history and rollback option.
- `argocd app set <name> -p spec.source.targetRevision=…` – update an app’s parameter (like switch branch or image tag
  if tracked via parameter).
- These commands hit ArgoCD’s API server. They require authentication (you login via `argocd login` with a token or
  username/password). In scripts, one often uses an auth token in environment or kube config with port-forward to
  argocd-server.

**ArgoCD ApplicationSet CLI**:

- `argocd appset list` – list all ApplicationSets
  ([argocd appset Command Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_appset/#:~:text=argocd%20appset%20get%20APPSETNAME)).
- `argocd appset get <name>` – get details (maybe YAML or summary).
- `argocd appset create -f appset.yaml` – create an ApplicationSet from file
  ([argocd appset Command Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_appset/#:~:text=,filename%20or%20URL)).
- `argocd appset delete <name>` – delete an ApplicationSet
  ([argocd appset Command Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_appset/#:~:text=argocd%20appset%20create%20,filename%20or%20URL)).
- `argocd appset generate <name>` – (if available) output the generated applications without applying (dry run).
- These are less commonly used than just applying via kubectl, but they exist for completeness.

### 2.5 Integration of Argo Rollouts with ArgoCD and Kubernetes

**GitOps Workflow**: Using ArgoCD and Argo Rollouts together means your Git repo contains Rollout CR manifests instead
of Deployment manifests for apps that need progressive delivery. ArgoCD syncs those to the cluster. The Argo Rollouts
controller then takes over to orchestrate how new versions are rolled out. Some important integration points and best
practices:

- **Health Checks**: As mentioned, ArgoCD can be aware of Rollout health. ArgoCD (in recent versions) includes a
  built-in health assessment for Rollouts. A Rollout is healthy when it’s at full desired replicas and not paused or
  degraded. It’s progressing when steps are being executed. If ArgoCD doesn’t have the health plugin, it might default
  to Unknown or consider the Rollout healthy as long as spec.replicas equals status.available (which might be true even
  mid-canary). It's wise to enable ArgoCD's Rollout health checks (which are usually on by default in 2.1+). You can
  also customize them in the ArgoCD ConfigMap if needed.
- **Automation vs Manual**: Decide how much of the rollout process you want to automate via analysis vs require manual
  intervention. In a GitOps context, pure Git changes can’t easily convey “pause here for manual test then resume” –
  that’s outside of Git. That’s where ArgoCD’s UI/CLI and Argo Rollouts CLI come in. It’s common to commit the new
  version in Git, let ArgoCD apply it, then use the Rollouts dashboard or ArgoCD UI to monitor and manually promote at
  checkpoints. This hybrid approach maintains Git as source of what to deploy (image versions, etc.) and uses Rollouts
  for _how_ to deploy.
- **Notifications**: Argo Rollouts integrates with Argo CD notifications or Rollouts-specific notifications. For
  instance, ArgoCD notifications (if configured) can send Slack messages on app sync or health state changes. Argo
  Rollouts also has an notifications integration (similar to ArgoCD’s) for rollout events. This helps in GitOps to
  notify when a rollout is paused awaiting input, or when it aborted.
- **Multi-Tenancy**: If multiple teams use ArgoCD in a cluster, they can all leverage Argo Rollouts as needed. ArgoCD
  doesn’t need special config for Rollouts CRD aside from health checks. Ensure the Rollouts controller is installed (it
  runs cluster-wide by default in its namespace, managing all Rollout CRs). It’s compatible with multi-tenant setups as
  long as teams have RBAC to create Rollout CRs in their namespaces.
- **Kubernetes Integration**: Argo Rollouts can work with Horizontal Pod Autoscalers (HPA) and PodDisruptionBudgets:
  - You can use an HPA with a Rollout similar to a Deployment. It will scale the stable ReplicaSet normally. During an
    update, HPA might not know about the canary RS or might scale stable. Argo Rollouts has support to detect HPA and
    adjust behavior (there is a section in docs about HPA integration
    ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=,Anti%20Affinity)),
    basically ensuring HPA doesn't fight the rollout).
  - PodDisruptionBudgets can be used to protect minimum pods during rollout.
  - If you use service mesh, ensure sidecars (like Istio sidecar) are present or any required labels (Argo Rollouts will
    label canary pods with `rollouts-pod-template-hash` and modifies service selectors accordingly).
  - ArgoCD will apply all needed resources: the Rollout, the Services (stable & canary or active/preview), the
    AnalysisTemplates, etc., from Git. You should include those in the same Application so that ArgoCD syncs them
    together.

**Advanced Use Cases**:

- **Rollout and ApplicationSet Combined**: You can use ApplicationSet to deploy the same Rollout to multiple clusters or
  environments. Each cluster will have its own instance of Rollout doing progressive delivery. You might coordinate
  these via ApplicationSet’s `strategy: RollingSync` (e.g., first let canary happen on a staging cluster, then later
  promote on production cluster). This would be a layered approach: Git triggers ArgoCD which triggers Argo Rollouts in
  each cluster.
- **Promotion via Git**: Some teams may prefer not to use the CLI for promotion. An alternative pattern is to encode
  rollout steps in Git itself. For example, you might initially push a Rollout with `steps: [setWeight:20, pause:{}]`.
  ArgoCD applies it, rollout goes to 20% and pauses. Then, to promote via Git, you could push a commit that changes the
  Rollout manifest to remove the pause or update the steps (e.g., remove the pause entry). ArgoCD applies that, the
  rollout continues to next step. This is less common but possible – treating the Rollout spec itself as declarative
  state machine. However, it’s a bit clunky to manage via Git commits (and can pollute history). Most prefer using the
  Rollouts plugin to promote outside of Git.
- **Web UI (Rollouts dashboard)**: Argo Rollouts offers a UI (accessible via `kubectl argo rollouts dashboard`). This is
  a real-time GUI that shows the rollout steps, versions, metrics. For GitOps, you might not use it in pipelines, but
  it’s great for observing behavior live during a deployment.
- **API (Rollouts)**: There isn’t a separate Argo Rollouts API server to call (the kubectl plugin just uses Kubernetes
  API). But it’s worth noting Argo Rollouts has a concept of a “Analysis API” for web metrics (in AnalysisTemplate you
  can define a web endpoint to fetch metrics). That’s more about metric providers.

### 2.6 Security Best Practices in a GitOps Environment

When operating ArgoCD and Argo Rollouts in an enterprise (multi-team, multi-cluster) environment, consider the following
security and safety practices:

**ArgoCD Security:**

- **Projects and RBAC**: Use ArgoCD **Projects** to silo applications by team or purpose. Projects allow whitelisting
  which Git repos an Application can deploy from and which clusters/namespaces it can deploy to. This prevents a
  compromised repo from affecting unrelated clusters, and prevents teams from accidentally deploying to each other’s
  namespaces. Tie this with ArgoCD RBAC so that team A can only manage Applications in project A, etc.
- **Least Privilege for ArgoCD**: By default, ArgoCD’s application controller runs with cluster-admin in target clusters
  (because it needs to create any resource). In multi-cluster setups, ArgoCD uses bearer tokens for each cluster (stored
  as Secrets). Ensure those tokens have minimal permissions (maybe use specific service accounts per namespace if
  possible). If some clusters are lower environment, consider separate ArgoCD instances for isolation from prod.
- **Repository Credentials**: Store Git credentials (if using private repos) in ArgoCD secret (or use SSH certificates).
  Avoid putting credentials in plain text in Git. ArgoCD supports Vault integration or using SOPS for encrypting secrets
  in Git.
- **Signature and Image Verification**: ArgoCD can verify PGP signatures on Git commits (to ensure the commit wasn’t
  tampered)
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,34)).
  Consider enabling this (it’s an ArgoCD config option with GnuPG keyring). Also, using admission controllers or
  Kubernetes tools for container image signing (like Cosign and policies) can add security – outside ArgoCD’s scope but
  complementary.
- **Secrets Management**: Don’t store raw Kubernetes Secrets with plaintext data in Git. Use tools like
  **SealedSecrets** or **External Secrets**. ArgoCD can sync those sealed secrets which are safe in Git, and controllers
  in cluster decrypt them. This keeps your GitOps repo free of sensitive plaintext.
- **ArgoCD Webhook**: Secure the Git webhooks that trigger ArgoCD (shared secret tokens, etc.)
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,Metrics)).
  This prevents abuse of webhook endpoint.
- **Network and Access**: Ensure ArgoCD’s UI is behind authentication (OIDC, SSO). Use role-based access to control who
  can trigger syncs or override rollout actions. ArgoCD supports fine-grained RBAC on actions (like “allow user X to
  sync but not to create apps”).
- **Audit**: ArgoCD records an audit log of who synced what (if SSO is used). Keep those logs for compliance if needed.
- **Cluster Admin vs Namespace scope**: You can run ArgoCD in a namespaced mode (managing only a namespace), but
  typically it manages cluster-wide. For multi-tenant, you might deploy one ArgoCD per cluster or per environment,
  depending on trust boundaries.

**Argo Rollouts Security:**

- The Argo Rollouts controller runs with certain permissions to create/manage ReplicaSets, services, etc. Ensure its
  RBAC is restricted to needed groups (should be covered by its install YAML).
- If Rollouts uses metric providers, e.g., querying Prometheus, ensure read-only access. For external providers (Datadog
  API keys, etc.), store those in Secrets and reference them in AnalysisTemplates (Argo Rollouts supports referencing
  secret data for provider auth).
- If using analysis with Job metric (which runs a Kubernetes Job), those jobs may need permissions if they, say, read
  cluster state. Usually they are just test jobs in same namespace.
- For multi-tenant clusters, you might allow some teams to use Rollouts and others not. It’s a CRD – you could use
  Kubernetes RBAC to control who can create `rollouts.argoproj.io` resources.
- Rollouts CRs could potentially reference other namespace’s resources (like services in other namespaces for traffic
  routing, though usually they are same namespace). Kubernetes will enforce namespace boundaries in most cases.
- **Failure handling**: Have monitoring on your rollouts. For example, if a rollout is stuck or degraded, ensure alerts
  fire so operators can intervene. This is more reliability than security, but part of safe operations.

**GitOps Process Control:**

- Use pull requests and reviews on the Git repositories hosting your ArgoCD manifests. This ensures any change to an
  Application or Rollout spec is reviewed (preventing malicious or wrong configs from direct push).
- Possibly require signature on commits (with ArgoCD verifying).
- Use branch protection so that changes to prod manifests have an approval gate.
- Keep ArgoCD itself updated to get latest security patches and features.

By adhering to these best practices, you ensure that your GitOps deployment pipeline is not only efficient and automated
but also secure and auditable.

## 3. Comprehensive Use Cases and Scenarios

In this section, we illustrate how ApplicationSets, Applications, and Argo Rollouts can be combined in real-world
scenarios, including multi-cluster deployments, multi-tenant setups, and various deployment strategies working in
concert:

### 3.1 Multi-Cluster Deployment of an Application with Canary Releases

**Scenario:** Your company runs a microservice `shopping-cart` that should be deployed to two clusters: `us-east` and
`us-west`. You want to use a canary strategy for releases in each cluster. For global reliability, you will deploy to
one cluster first, then the other.

**Solution:** Use an ApplicationSet with a cluster generator to target both clusters, and inside the template, define
the `shopping-cart` as a Rollout (with canary strategy).

- **ApplicationSet**:
  - Generator: `clusters` with a label selector (e.g., select clusters with `environment=prod`). This yields two
    parameter sets (for two clusters).
  - Strategy: Use ApplicationSet’s `RollingSync` to control order. Tag each generated Application with a label
    `region: us-east/us-west`. In RollingSync steps, first target `us-east` with `maxUpdate: 1` (sync east first, west
    held at 0 until manual or after some interval).
  - Template: The ApplicationSet template will have `spec.source.path: k8s/shopping-cart/` and
    `destination.name: {{name}}` (cluster name) and likely `project: prod`.
- **Application (generated)**: For each cluster, an Application is created, which points to the manifest
  kustomization/helm of `shopping-cart`. That manifest defines a **Rollout** (not a Deployment) for the app.
- **Rollout**: The Rollout YAML in Git for `shopping-cart` includes the Canary steps: e.g., 10% -> pause -> 50% -> pause
  -> 100%, with analysis at 50%. Also includes stable and canary Services for traffic splitting via Istio (assuming
  clusters use Istio).
- **Process**:
  1. Dev team opens a PR to update the `shopping-cart` image tag in the Rollout manifest (in Git).
  2. After review, they merge to main. This triggers ArgoCD (via webhook) to pick up changes.
  3. ArgoCD’s ApplicationSet sees the new commit. According to RollingSync, it updates the Application in `us-east`
     first (syncs that app)
     ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,matchExpressions))
     ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,matched%20applications%20will%20be%20synced)).
     The west Application is either not yet synced (if maxUpdate 0 for west initially) or at least delayed.
  4. In `us-east` cluster, ArgoCD applies the Rollout. Argo Rollouts in `us-east` begins canary. 10% of traffic goes to
     new version. It pauses (as per Rollout spec).
  5. The team verifies metrics in `us-east`. The AnalysisRun at 50% might run automated tests. Suppose everything looks
     good. They then promote the rollout (either manually or if the analysis set it to auto-continue).
  6. `us-east` goes 100% new, old version scaled down – rollout complete in east.
  7. Now, the ApplicationSet’s progressive sync can either automatically continue (if configured a timed wave or if
     someone unpauses it) to `us-west`. It syncs `us-west` Application.
  8. In `us-west` cluster, the rollout process repeats. Perhaps here we skip analysis because we trust it after east, or
     we still run it. Either way, eventually west is updated.
  9. Both clusters are now updated. Users in both regions got a canary rollout with minimal impact.

**Key Points:** Using ApplicationSet’s waves ensures we didn’t deploy to both clusters simultaneously. If `us-east` had
issues, we could abort there and never even trigger `us-west`. This limits blast radius. Each cluster’s Argo Rollouts
handled local traffic management. From ArgoCD’s perspective, each cluster’s Application went from
Healthy->Progressing->Healthy one after the other.

### 3.2 Multi-Tenant ArgoCD with Team-Specific ApplicationSets

**Scenario:** An organization has multiple teams deploying apps to a shared cluster (or set of clusters). They use
ArgoCD as a shared service, but need isolation: Team A should not affect Team B’s apps. Also, each team wants to
leverage ApplicationSets to manage many services, and possibly Rollouts for deployment strategies.

**Solution:** Use ArgoCD Projects for multi-tenancy and separate ApplicationSets per team.

- **ArgoCD Projects**: Define a Project for each team (TeamA, TeamB) with:
  - Allowed Git sources: restrict to that team’s Git repositories (or specific paths).
  - Allowed destinations: maybe each team deploys to a separate namespace (or separate clusters/namespaces). Project
    will enforce that.
  - Role-based access: Bind team’s LDAP/OIDC group to have access to their project’s apps only.
- **Team ApplicationSets**: Each team has their own ApplicationSet CRs, likely defined in their own Git repo.
  - For example, Team A’s repo contains `appset-team-a.yaml` which lists all microservices of Team A and generates
    Applications for each (perhaps using a Git directory generator or a list).
  - The Applications use `project: TeamA` and destination namespace TeamA’s space.
- **Deployment strategies**: Team A might decide to use Argo Rollouts for two of their services that need canary. In
  their kustomize overlay or helm values, they can choose to deploy a Rollout instead of Deployment for those specific
  services. Team B might use simple Deployments or BlueGreen depending on their preference.
  - ArgoCD can manage both standard Deployments and Rollouts concurrently.
  - It’s advisable to have Argo Rollouts controller installed cluster-wide (it will only act on Rollout CRs).
  - Teams that don’t need it can ignore it; it doesn’t interfere with standard deployments.
- **Example**: Team A’s ApplicationSet uses a Git generator to create an Application per service folder. Service
  “web-ui” uses a Rollout (Canary), service “api” uses a Deployment (rolling update). ArgoCD applies both. Argo Rollouts
  controller only touches “web-ui” (Rollout). The “api” just uses native deployment.
- **Manual control**: Each team can be given permissions to use `kubectl argo rollouts` in their namespace (via RBAC).
  Or they use ArgoCD’s UI: they will only see their own Applications (project isolation). If an Application contains a
  Rollout, ArgoCD’s UI will show the rollout status and allow promote/abort actions for that team’s operators (the
  ArgoCD UI respects RBAC so only TeamA members can operate on TeamA’s rollout).
- **Benefit**: Teams operate independently but through the same central GitOps service, with guardrails. If Team B’s
  rollout goes bad, it won’t affect Team A’s stuff (aside from sharing the ArgoCD and Rollouts controllers, which are
  engineered to handle multi-app concurrency).

### 3.3 GitOps for Progressive Delivery in a CD Pipeline

**Scenario:** A company wants fully automated progressive delivery: on each commit to main, run integration tests, then
deploy to staging with canary, if success, automatically promote to production with blue-green. All without manual
steps, but still gated by quality checks.

**Solution:** Utilize ArgoCD and Argo Rollouts with analysis to automate promotions. And use a **promotion pipeline**
approach:

- **Stages as Git branches or folders**: Use Git to represent environments:
  - e.g., have a `staging` folder and `prod` folder for manifests (or use Kustomize overlays).
  - The CI pipeline (Jenkins/Argo Workflows/GitHub Actions) on commit to main runs tests. If tests pass, it updates the
    `staging` manifest with the new image tag and pushes to Git.
  - ArgoCD (watching staging folder) syncs to staging cluster. The Rollout there (canary strategy) starts. Include an
    AnalysisRun in the canary steps that maybe runs a synthetic test or checks error rates. The Rollout is configured to
    **automatically promote** if analysis is OK. (Could use `analysis` with `successCondition` that triggers rollout to
    continue, etc., actually rollouts analysis doesn’t automatically promote but can mark success for an automated
    step).
  - After staging rollout finishes successfully (maybe ArgoCD notifications or Rollouts notifications tell CI that
    staging is good), the pipeline then copies the manifest to `prod` folder (or updates an image tag in prod config)
    and pushes.
  - ArgoCD syncing prod uses BlueGreen strategy for nearly zero-downtime. Perhaps with `autoPromotionSeconds: 300` to
    allow 5 minutes of soak time before switching automatically, giving time for any last-minute abort if monitoring
    catches something.
  - Prod Rollout goes live; if its post-promotion analysis detects an issue, it auto-aborts (since we set
    `progressDeadlineAbort: true` or use AnalysisRun with `failure` action to rollback).
- **All possible configurations**: In this pipeline, we used canary + analysis in staging, and blue-green + analysis in
  prod, demonstrating combination. All configurations (like metric providers credentials, multiple environment values)
  must be in Git. For example, AnalysisTemplate CRs for checkings metrics are in the repo, one might be tuned for
  staging thresholds, another for prod.
- This achieves an end-to-end GitOps continuous deployment with progressive delivery:
  - Commits and test results control when things move to next stage by updating Git.
  - Human oversight can be inserted by requiring PR approvals for promoting to prod (e.g., have a PR from staging branch
    to prod branch that a lead approves, if wanting a manual gate).
  - Rollouts controllers in each cluster ensure the rollout is safe and reversible.

**Multi-cluster failover example**:

- You could also do blue-green across clusters (active cluster vs disaster recovery cluster) using similar Service
  switching or DNS update triggers, but that extends beyond Argo Rollouts (would involve external tooling).

### 3.4 Combining ApplicationSets, ArgoCD, and Rollouts in Complex Deployments

Consider a **microservice platform** with dozens of services, deployed to multiple clusters (dev, QA, prod), with
different rollout strategies per environment:

- In dev: deploy each commit with basic RollingUpdate (Deployment) since stakes are low and speed is priority.
- In QA: use Argo Rollouts Canary, but auto-promote quickly (no manual pause) just to test progressive delivery logic.
- In prod: use Argo Rollouts BlueGreen with manual approval (so SRE can verify).

Using ArgoCD:

- You might use **ApplicationSet with multiple generators** – for example, a Git directory generator for services
  combined with a cluster list:
  - One ApplicationSet generates Applications for each service x environment (like matrix of service and env).
    Alternatively, you have separate ApplicationSets per environment for clarity.
- Each Application in dev cluster uses plain Deployment manifests (or you could even still use Rollout with no steps, as
  it supports basic rolling).
- Each Application in prod cluster points to a different kustomize overlay where the Deployment is patched into a
  Rollout with BlueGreen strategy.

This can be achieved by kustomize or Helm:

- Use a base manifest for Deployment, and in prod overlay, replace it with a Rollout (there’s an ArgoCD example of
  transforming Deployment to Rollout via Kustomize patches in documentation
  ([Migrating - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/migrating/#:~:text=Migrating%20,it%20involves%20changing%20three%20fields))
  ([Migrating - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/migrating/#:~:text=Controller%20argoproj,Convert%20Deployment%20to%20Rollout%C2%B6%20When))).
- Or maintain separate YAMLs for each environment.

**Benefit**: You manage everything in Git with ArgoCD syncing appropriately. Developers mostly deal with dev and QA
flows; SRE/Release managers focus on prod approvals.

### 3.5 Multi-Cluster Multi-Tenancy with GitOps and Security

Bringing together multi-cluster and multi-tenant:

- Suppose you run a platform where multiple product teams each have dev and prod clusters (or namespaces) isolated for
  them. ArgoCD can handle all clusters.
- You can set up an ApplicationSet per team that uses a **Cluster Decision Resource** generator (if using Open Cluster
  Management) to determine which clusters are for that team. Or simpler, label clusters with team names and use cluster
  generator filtering.
- Each team’s apps get deployed to their clusters. Some teams might not need Argo Rollouts (they do simple deployment),
  others can opt-in by writing Rollout manifests.
- ArgoCD ensures one team cannot deploy to another’s cluster due to Projects restrictions.
- If a malicious actor got access to one Git repo, worst case they can mess with that team’s deployments but not others
  or not escalate privileges on cluster thanks to namespace isolation and Projects.

**Observation**: In all cases, if a feature, argument, or syntax is not mentioned above, it likely isn’t part of ArgoCD
Application/ApplicationSet or Argo Rollouts. We’ve covered fields like syncOptions, various generator types, rollout
steps, trafficRouting integrations, etc. For instance, Argo Rollouts does **not** have a strategy called “RollingUpdate”
– if you want a plain rolling update, you either use Deployment or you use Rollout with steps that effectively replicate
rolling (e.g., setWeight 100 immediately). ArgoCD Application does not have a field to directly schedule sync at certain
time (that would be done via webhook or API triggers outside spec). These omissions are intentional because those
features don’t exist in the frameworks beyond what’s documented.

## 4. Exhaustive Configuration Reference

This section serves as a quick reference for all possible configurations, parameters, CLI commands, and API usage
discussed, ensuring completeness.

### 4.1 ArgoCD Application Fields Reference

An ArgoCD **Application** CRD contains the following key spec fields (all are optional except source, destination, and
project in practice):

- **spec.project** (string): Name of the ArgoCD Project the application belongs to
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,project%3A%20default)).
- **spec.source** (object): Defines where to fetch the application manifests. Sub-fields:
  - **repoURL** (string): Git repository URL or Helm chart repository URL
    ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,Helm%20repo%20instead%20of%20git)).
  - **path** (string): Path within the repo to the directory containing manifests (for Git sources)
    ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,Helm%20repo%20instead%20of%20git)).
  - **targetRevision** (string): Git revision (branch, tag, commit SHA) or Helm chart version to use
    ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,Helm%20repo%20instead%20of%20git)).
  - **chart** (string): If repoURL is a Helm repo, specify the chart name to pull
    ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,parameters)).
  - **helm** (object): Helm-specific configuration:
    - **parameters** (list of name/value pairs): Helm CLI `--set` overrides
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,is%20treated%20as%20a%20string)).
    - **fileParameters** (list of name/path pairs): Helm CLI `--set-file` overrides
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,json)).
    - **valueFiles** (list of strings): Paths to values.yaml files in repo to use
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,releaseName%3A%20guestbook)).
    - **values** (string): Multi-line string of Helm values (alternative to separate files)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,mydomain.example.com%20annotations)).
    - **valuesObject** (map): Structured values (overrides `values` if both set)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,class%3A%20nginx)).
    - **releaseName** (string): Helm release name (defaults to app name)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=fileParameters%3A%20,json)).
    - **passCredentials** (bool): Pass repo credentials to dependencies
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=chart%3A%20chart,parameters)).
    - **ignoreMissingValueFiles** (bool): If true, ignore any listed valueFiles not found
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=)).
    - **skipCrds** (bool): If true, do not install CRDs from Helm chart (default false)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,Defaults%20to%20false%20skipCrds%3A%20false)).
    - **skipSchemaValidation** (bool): Skip validation of CRD schemas (default false)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=skipCrds%3A%20false)).
    - **version** (string): Force Helm version (“v2” or “v3”) to template with
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,version%3A%20v2)).
    - **kubeVersion** (string): Kubernetes version to use for Helm engine template (semver)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,kubeVersion%3A%201.30.0)).
    - **apiVersions** (list of strings): K8s API versions to add to Capabilities for Helm (group/version/kind)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,v1%2FService)).
    - **namespace** (string): If set, template Helm with this namespace (affects certain charts’ behavior)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=)).
  - **kustomize** (object): Kustomize-specific configuration:
    - **namePrefix** / **nameSuffix** (string): Prefix or suffix for all resource names
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,enables%2Fdisables%20env%20variables%20substitution%20in)).
    - **commonLabels** / **commonAnnotations** (map): Labels/annotations to add to all resources
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=commonLabels%3A%20foo%3A%20bar%20commonAnnotations%3A%20beep%3A,true%20forceCommonLabels%3A%20false%20forceCommonAnnotations%3A%20false)).
    - **commonAnnotationsEnvsubst** (bool): If true, perform environment variable substitution in commonAnnotations
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=commonAnnotations%3A%20beep%3A%20boop,forceCommonLabels%3A%20false%20forceCommonAnnotations%3A%20false%20images)).
    - **images** (list of strings): Kustomize image override strings (`old=new:tag` or `image:tag`)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=forceCommonAnnotations%3A%20false%20images%3A%20,ui%20count%3A%204)).
    - **replicas** (list of objects): Kustomize replica count overrides (each with name, count)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=namespace%3A%20custom,patches)).
    - **components** (list of strings): Kustomize component paths to include
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,patches)).
    - **patches** (list of objects): Kustomize patches (each with target selector and patch content)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=patches%3A%20,pro)).
    - **version** (string): Kustomize version to use (must be set in ArgoCD config)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,io%2Freferences%2Fkustomize%2Fkustomization%2F%20namePrefix%3A%20prod)).
    - **kubeVersion** / **apiVersions**: Similar to Helm, pass K8s version info to Kustomize (for substitution or
      helmchart inflator)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,kubeVersion%3A%201.30.0)).
  - **directory** (object): Plain YAML/Jsonnet directory config:
    - **recurse** (bool): Recurse into subdirectories for manifests
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,name%3A%20foo%20value%3A%20bar)).
    - **exclude** (string): Glob pattern to exclude certain files/dirs
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,only%20matching%20manifests%20will%20be)).
    - **include** (string): Glob pattern to include only certain files
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=them%20with%20commas,yaml)).
    - **jsonnet** (object): If using jsonnet:
      - **extVars** (list): External variables (each with name, value, and optional code flag)
        ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=jsonnet%3A%20,code%3A%20true%20name%3A%20baz)).
      - **tlas** (list): Top-level arguments for Jsonnet (similar structure to extVars)
        ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,field)).
  - **plugin** (object): Config Management Plugin info:
    - **name** (string): Name of the plugin to use
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,name%3A%20FOO)).
    - **env** (list of env vars): Environment variables to set for plugin
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=name%3A%20mypluginname%20,string)).
    - **parameters** (list): Plugin-specific parameters (ArgoCD v2.5+)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,value)).
- **spec.sources** (list of source objects): If using multi-source app, list of sources. Each has same fields as above
  plus an optional **ref** (string) to identify it
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,field))
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=path%3A%20guestbook%20%20,field)).
  Multi-source allows combining manifests from multiple repos or charts.
- **spec.destination** (object): Where to deploy:
  - **server** (string): Kubernetes API server URL. Use `https://kubernetes.default.svc` for in-cluster, or external
    cluster URL
    ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,namespace%20namespace%3A%20guestbook)).
  - **name** (string): Alternatively, ArgoCD cluster name (as given when added to ArgoCD)
    ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,namespace%20namespace%3A%20guestbook)).
    (Mutually exclusive with server; ArgoCD resolves name to a server URL internally).
  - **namespace** (string): Kubernetes namespace to deploy resources into
    ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,namespace%20namespace%3A%20guestbook)).
    If a manifest has a namespace set, that takes precedence unless this is empty (ArgoCD will not override a resource’s
    own namespace, but will set it for namespace-scoped resources with no namespace defined).
- **spec.syncPolicy** (object): How syncs are performed:
  - **automated** (object): Enable auto-syncing if present.
    - **prune** (bool): If true, ArgoCD will delete resources that exist in cluster but not in Git (when syncing)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=controlled%20using%20,false%20by%20default)).
    - **selfHeal** (bool): If true, ArgoCD will continuously monitor and revert any drift without Git change (state
      reconciliation)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=controlled%20using%20,false%20by%20default)).
    - **allowEmpty** (bool): If true, allows syncing an Application even if it contains no manifests (deleting all
      resources)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=allowEmpty%3A%20false%20,options%20which%20modifies%20sync%20behavior)).
  - **syncOptions** (list of strings): Additional flags influencing sync:
    - **Validate=false**: Skip schema validation by kubectl apply
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=syncOptions%3A%20%20%20%20,wave%20of%20a%20sync%20operation)).
    - **CreateNamespace=true**: Auto-create the destination namespace if it doesn’t exist
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=syncOptions%3A%20%20%20%20,wave%20of%20a%20sync%20operation)).
    - **PrunePropagationPolicy**: foreground, background, or orphan – deletion propagation mode
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=specified%20as%20the%20application%20destination,every%20object%20in%20the%20application)).
    - **PruneLast=true**: Perform pruning as a final wave after all applies
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=specified%20as%20the%20application%20destination,every%20object%20in%20the%20application)).
    - **RespectIgnoreDifferences=true**: During sync, do not overwrite changes that are listed in ignoreDifferences
      (will leave those differences)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=final%2C%20implicit%20wave%20of%20a,every%20object%20in%20the%20application)).
    - **ApplyOutOfSyncOnly=true**: Only apply resources that are detected OutOfSync, rather than all resources. (Speeds
      up partial changes)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=final%2C%20implicit%20wave%20of%20a,every%20object%20in%20the%20application)).
    - **managedNamespaceMetadata**: If CreateNamespace is true, a sub-object to specify labels/annotations on the
      created namespace
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=applying%20every%20object%20in%20the,the%20application%20namespace%20the%3A%20same)).
  - **retry** (object): Retry strategy for failed syncs
    ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,duration%20after%20each%20failed%20retry)):
    - **limit** (int): Number of retry attempts (default 5, <0 = unlimited)
      ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,duration%20after%20each%20failed%20retry)).
    - **backoff** (object): Backoff timing between retries:
      - **duration** (string): Base backoff (e.g., "5s")
        ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=backoff%3A%20duration%3A%205s%20,allowed%20for%20the%20backoff%20strategy)).
      - **factor** (number): Backoff multiplication factor (e.g., 2 = exponential)
        ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=backoff%3A%20duration%3A%205s%20,allowed%20for%20the%20backoff%20strategy)).
      - **maxDuration** (string): Max total time to wait (e.g., "3m")
        ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=could%20also%20be%20a%20duration,allowed%20for%20the%20backoff%20strategy)).
- **spec.ignoreDifferences** (list): Specifies which fields to ignore when comparing live vs desired state
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,group%3A%20apps%20kind%3A%20Deployment%20jsonPointers)).
  Each item can target by group/kind/name/namespace and list either **jsonPointers** (fields in JSONPath from the
  resource root)
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=ignoreDifferences%3A%20,%27.data%5B%22config.yaml%22%5D.auth))
  or **jqPathExpressions** (JQ style expressions)
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,%27.data%5B%22config.yaml%22%5D.auth))
  or **managedFieldsManagers** (list of controller manager names to ignore changes from)
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,namespace)).
- **spec.revisionHistoryLimit** (int): How many past synced revisions to keep in history (default 10)
  ([Application Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/#:~:text=,revisionHistoryLimit%3A%2010)).
  These are visible in ArgoCD UI/CLI and used for rollback via ArgoCD.

**CLI Reference (ArgoCD Application):**

- Create an Application: `argocd app create -f app.yaml` or specify each field with flags.
- Get status: `argocd app get my-app` – shows health, sync status, history, conditions.
- List: `argocd app list` – shows all apps and whether Healthy/Synced.
- Sync: `argocd app sync my-app [--prune] [--revision=HEAD]` – triggers a sync (even if auto-sync is off or to force an
  update to a specific revision).
- Wait: `argocd app wait my-app --health --timeout 120` – wait until app is Healthy (all resources healthy) or timeout.
- Rollback: `argocd app rollback my-app --to-revision 3` – resets app to a previous Git revision that was synced (if
  history is present).
- Delete: `argocd app delete my-app` – removes the Application. (If the cascading finalizer is in place, it will also
  delete the Kubernetes resources it created, unless you remove finalizer first or use `--cascade=false`).

**API Usage (ArgoCD Application):**

- ArgoCD server provides a gRPC/REST API. For example, to get an application’s details via REST:
  `GET /api/v1/applications/<name>`. To create: `POST /api/v1/applications` with a JSON payload of the Application spec.
  The response will include the created resource or error.
- A request sample (JSON) for creating an Application via API:

  ```json
  {
    "apiVersion": "argoproj.io/v1alpha1",
    "kind": "Application",
    "metadata": { "name": "my-app", "namespace": "argocd" },
    "spec": {
      "project": "default",
      "source": { "repoURL": "...", "path": "...", "targetRevision": "..." },
      "destination": { "server": "https://...", "namespace": "..." },
      "syncPolicy": { "automated": { "prune": true, "selfHeal": false } }
    }
  }
  ```

  The ArgoCD API would return 201 Created with the Application details (including status). One can also patch an
  Application via `PUT /api/v1/applications/<name>` or use CLI which wraps these calls.

### 4.2 ArgoCD ApplicationSet Fields Reference

An **ApplicationSet** CRD has the following main fields in its spec:

- **spec.generators** (list): One or more generator definitions. Each entry has exactly one of the generator types
  defined:

  - **list** (object): Contains `elements` (list of YAML objects). Each element is a set of parameters (key: value) that
    will be made available to the template
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,prod%20url%3A%20https%3A%2F%2Fkubernetes.default.svc)).
    Optionally can have an inline `template` override (same schema as spec.template) to override the global template for
    this generator only
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,cd.git)).
    Also can have a `selector` to filter which elements actually yield Applications (by matching labels in the element)
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=destination%3A%20)).
  - **clusters** (object): No further keys required in simplest form (if empty, it lists all clusters in ArgoCD)
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,cluster)).
    Optionally:
    - **selector**: label selector to filter clusters (as labeled in ArgoCD’s cluster secrets)
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,cluster)).
    - **values**: a map of additional parameters to inject for each cluster
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=generators%3A%20,clusters%3A%20selector%3A%20matchLabels)).
      The cluster generator automatically provides `name` (cluster name in contexts) and `server` (URL). It also
      provides `labels` of cluster as a map if needed.
  - **git** (object): Scans a Git repository:
    - **repoURL** (string): Git repo URL.
    - **revision** (string): Git revision (branch, tag, commit).
    - One of the following to define what to scan:
      - **directories** (list): Each item has:
        - **path** (string): Glob pattern for directories to include
          ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=The%20Git%20directory%20generator%2C%20one,of%20a%20specified%20Git%20repository)).
        - **exclude** (string, optional): Glob pattern to exclude directories
          ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=The%20Git%20directory%20generator%20will,git)).
        - **pathParamPrefix** (string, optional): If set, all path-related parameters will be prefixed with this string
          (to avoid collisions if multiple git generators).
      - **files** (list): Each item has:
        - **path** (string): Glob pattern for files to include
          ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=generators%3A%20,config%2F%2A%2A%2Fconfig.json%22%20template%3A%20metadata)).
        - **exclude** (string, optional): Glob pattern to exclude files.
        - **pathParamPrefix** (string, optional): Similar prefix for parameters.
    - **requeueAfterSeconds** (int, optional): Interval for polling the Git repo for changes (defaults 180s).
    - _Parameters provided_: For Directory generator, provides `path.basename`, `path.dirname`, etc., and `path` itself
      (the directory path). For Files generator, provides flattened file content as parameters plus `path.filename`,
      `path.basename` etc.
      ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=In%20addition%20to%20the%20flattened,following%20generator%20parameters%20are%20provided))
      ([Git Generator - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators-Git/#:~:text=,path.basename)).
  - **scmProvider** (object): Connects to SCM (GitHub, GitLab, etc.):
    - **cloneProtocol** (string): `https` or `ssh` (how to form clone URLs)
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,organization%3A%20myorg)).
    - Then one provider subsection:
      - **github**: with fields:
        - **organization** (string): Org or user to scan
          ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,Defaults%20to%20false)).
        - **api** (string): Base API URL (for GitHub Enterprise, else omit for github.com)
          ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=github%3A%20,%28optional)).
        - **tokenRef** (secret ref): Access token secret for API
          ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=api%3A%20https%3A%2F%2Fgit.example.com%2F%20,token%20key%3A%20token)).
        - **appSecretName** (string): If using a GitHub App, name of the App’s private key secret
          ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=secretName%3A%20github,repository)).
        - **allBranches** (bool): If true, includes all branches for each repo (meaning the generator will treat each
          branch as separate “repo” entry). Typically false – only default branch is considered
          ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=organization%3A%20myorg%20,%28optional%29%20tokenRef)).
        - **values** (map): Key/values to inject for each repo
          ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=%23Pass%20additional%20key,repository))
          (e.g., organization and repo name were used to form a name).
      - **gitlab**: fields: group, api, tokenRef, projectFilter, etc. (similar concept).
      - **gitea**: fields: org, api, tokenRef.
      - **bitbucketServer**: fields: project, api, tokenRef.
      - **bitbucket**: fields: workspace, tokenRef.
      - **azureDevOps**: fields: organization, project, api (for Azure DevOps repos).
      - **awsCodeCommit**: fields: AWS region/account info and filters.
    - **filters** (list of objects, optional): Additional filtering on discovered repos:
      - **repositoryMatch** (string regex): Include repos matching this regex
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,txt)).
      - **pathsExist** (list of strings): Only include repos that contain these files (or directories)
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=filters%3A%20,repositoryMatch%3A%20%5Eotherapp)).
      - **pathsDoNotExist** (list): Only include if these files do _not_ exist
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,matrix%20%27parent%27%20generator)).
      - **labelMatch** (string or regex): For GitHub, repo must have this label
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=filters%3A%20,repositoryMatch%3A%20%5Eotherapp)).
    - The SCM provider will enumerate repos (and possibly branches) and yield parameters: `organization`, `repository`,
      `branch` (if allBranches true, multiple entries per repo), etc.
  - **pullRequest** (object): Scans pull requests:
    - **requeueAfterSeconds** (int): Poll interval (default 1800s = 30min)
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,The%20GitHub%20organization%20or%20user)).
    - One provider subsection (similar structure to SCM provider but for PRs):
      - **github**: requires `owner` (org/user)
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,%28optional)),
        `repo` (name)
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,token)),
        `api` (if GH Enterprise)
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,API%20instead%20of%20a%20PAT)),
        `tokenRef` (for auth)
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,%28optional%29%20labels)),
        `appSecretName` (if using GH App)
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=secretName%3A%20github,creds)),
        and can filter by PR **labels** (list of string)
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,preview)).
      - **gitlab**: project id or path, tokenRef, etc.
      - **gitea**, **bitbucketServer**, **bitbucketCloud**, **azuredevops**, **awsCodeCommit**: each has fields for
        identifying the repo or project and credentials
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,bitbucket)).
    - **filters** (list): Similar concept to filter PRs:
      - **branchMatch** (regex): Only include PRs whose source branch matches the regex
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,argocd)).
      - (GitHub specific: could filter by author or base branch in future, but not sure if supported).
    - Provided parameters for template: likely `number` (PR number), `branch` (PR branch name), `headSHA` (commit SHA of
      PR head), perhaps `baseBranch`, and any PR labels etc. The example shows usage of `head_sha` for naming
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=match%20at%20L520%20,argocd)).
    - Typically used to create ephemeral environments for each PR.
  - **matrix** (object): Combines other generators:
    - **generators** (list): Two or more generator definitions inside it
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,may%20be%20used%20here%20instead)).
      The output is every combination of one output from each child generator. E.g., if one yields 3 values of X,
      another yields 2 values of Y, matrix yields 3\*2 = 6 sets.
    - The parameter keys from each generator are merged. If same key from multiple, one may override or conflict (so use
      unique keys, or structure them under different namespaces in values).
    - Cannot nest matrix inside matrix directly (but can nest any top-level generator type).
  - **merge** (object): Merges outputs of child generators on a common key:
    - **mergeKeys** (list of strings): One or more parameter keys to use to match outputs
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,clusters%3A%20values)).
      All generators outputs that have equal values for all these keys will be merged into one parameter set.
    - **generators** (list): Two or more child generators to merge
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=generators%3A%20,clusters%3A%20selector%3A%20matchLabels)).
    - The child generator outputs are essentially joined like database tables on those keys. If some generator provides
      a key in a nested map (like `values.env`), you can specify the dotted path in mergeKeys (as shown
      `values.selector` in example)
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,values.selector%20generators)).
    - If some output doesn’t find a match in others, I believe it is omitted unless each generator yields that key –
      likely you need matching pair from at least two.
    - Useful to enrich parameter sets from multiple sources.
    - Note: If goTemplate is true, merge might not support nested merge keys (as per docs)
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,clusters)).
  - **plugin** (object): Custom generator plugin:
    - **configMapRef** (object): name of ConfigMap containing plugin config
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,available%20on%20the%20generator%27s%20output)).
    - **input** (object):
      - **parameters** (map): Arbitrary input parameters to feed plugin
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,values)).
      - **values** (map): Values to attach to each generated element (these appear under each element’s `values` key in
        template context)
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=key2%3A%20%22value2%22%20key3%3A%20%22value3%22%20,generator%2C%20the%20ApplicationSet%20controller%20polls)).
    - **requeueAfterSeconds** (int): How often to run the plugin and refresh (default 1800s, can be overridden)
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,to%20detect%20changes)).
    - The plugin is an external process or script configured in ArgoCD that returns a list of parameters. This allows
      integrating with anything (database, custom API, etc.) as generation source.

- **spec.template** (object): Template for the resulting Application manifests:

  - **metadata**: Metadata to apply to each generated Application:
    - **name** (string): Name for the Application. Usually uses generator params (e.g., `{{cluster}}-{{app}}`). This
      must result in a valid DNS subdomain name (K8s name rules) and unique per ApplicationSet output.
    - **labels** / **annotations**: to tag the generated Applications. Often used with `strategy` to group them.
    - (You generally should not set `namespace` here; generated Applications will be created in the same namespace as
      ApplicationSet, usually argocd).
  - **spec**: The Application spec template (same fields as a normal Application spec described in 4.1). Commonly
    includes parameter placeholders. For instance:
    - `spec.project: "{{project}}"` or fixed to a known project.
    - `spec.source.repoURL/path/targetRevision`: likely mostly static except path if generating per folder or chart if
      per repo, etc.
    - `spec.destination.name` or `server`: often template in cluster info from generator.
    - You can also templatize parts of `source`, e.g., path or values. In a matrix, you might do
      `targetRevision: "{{branch}}"` if combining branch with something.
    - **Important**: If using goTemplate: true, the templating language is different (uses `{{ .param }}`).
    - If using multiple sources (multi-source app), the template spec can include a `sources: []` instead of single
      source. But ApplicationSet currently (as of v2.5) might not fully support multi-source templating – this is
      evolving, but in general, you template an Application of single-source normally.

- **spec.goTemplate** (bool): If true, use Go templating for the template field instead of simple string substitution
  ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,is%20true)).
  Default is false, which uses a simple placeholder substitution (Jinja-like, but technically just text replace of
  `{{}}` tokens with values).
- **spec.goTemplateOptions** (list of strings): Options to pass to Go template engine (e.g., "missingkey=error" or
  "missingkey=default")
  ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,is%20true)).
  This affects how missing keys or other template behaviors are handled.
- **spec.syncPolicy** (object): Controls how the ApplicationSet controller manages the Applications:
  - **applicationsSync** (string): One of `create-only`, `create-update`, `create-delete`, or `sync` (newer versions
    might name `sync` as default meaning create-update-delete).
    - `create-only`: Once an Application is created, the controller will neither update nor delete it on subsequent
      reconciliations
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,only)).
    - `create-update`: It will create new and update existing apps, but never delete them
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,update)).
    - `create-delete`: It will create and delete to match generator, but not update existing ones
      ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,delete)).
    - If not specified, default allows create, update, delete (full sync).
  - **preserveResourcesOnDeletion** (bool): If true, when an Application is deleted (by ApplicationSet or manually),
    ArgoCD will orphan its child resources (skip deleting them)
    ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,Application%20is%20deleted%20preserveResourcesOnDeletion%3A%20true)).
    Default false (ArgoCD will delete app resources on Application deletion as normal, if finalizer is present).
- **spec.strategy** (object): ApplicationSet sync strategy (for progressive sync):
  - **type** (string): Currently only `"RollingSync"` is supported (if strategy present).
  - **rollingSync** (object): Defines waves of Application updates:
    - **steps** (list of objects): Each step defines a group of Applications to sync, identified by label selectors:
      - **matchLabels** / **matchExpressions**: A label selector to pick which subset of generated Applications belong
        to this wave
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=rollingSync%3A%20steps%3A%20,dev))
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,default%20is%20100)).
      - **maxUpdate** (int or string percentage, optional): How many Applications matching this step’s selector to sync
        at once
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,matched%20applications%20will%20be%20synced))
        ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=operator%3A%20In%20values%3A%20,0)).
        If omitted or 100%, it will sync all matching in this step together. If 0, it means hold these in paused state
        (don’t sync) until manually triggered.
      - If omitted on a step, it defaults to 1 (meaning one at a time) or 100%? The docs example shows leaving blank =
        100%.
    - The steps are processed sequentially. All apps in step1’s selector up to maxUpdate will sync. Only when those
      complete (or at least start? likely complete) does it move to next step.
    - You can set maxUpdate to a low number for critical envs. E.g., step for env=prod with maxUpdate=10% means it will
      only allow 10% of prod apps to sync, then presumably one would manually bump or gradually raise that number
      (currently ArgoCD’s RollingSync is not automatically increasing like canary, it’s more static grouping).
    - If you set a step’s maxUpdate to 0%, it effectively pauses syncing those until someone changes the AppSet spec to
      non-zero or manually syncs those apps outside AppSet (they’ll just remain out-of-sync in UI).
    - _Note_: RollingSync is relatively new; it requires that generated Applications have labels that align with these
      selectors (like environment label in template).
- **spec.preservedFields** (object, deprecated in favor of ignoreApplicationDifferences): Lists metadata fields of
  Applications that ApplicationSet should ignore changes to
  ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,key)):
  - **labels** (list of strings): label keys to ignore.
  - **annotations** (list of strings): annotation keys to ignore.
  - If an ApplicationSet template doesn’t have these but someone adds them to the Application, the controller won’t
    remove them.
- **spec.ignoreApplicationDifferences** (list of objects): Each item defines fields to ignore when comparing generated
  Application spec vs live Application spec
  ([ApplicationSet Specification Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/#:~:text=,.spec.source.helm.values))
  (to prevent constant updates):
  - Same format as Application’s ignoreDifferences: can specify **jsonPointers**, **jqPathExpressions** within the
    Application spec, and optionally target by Application name.
  - This is helpful if, say, the ApplicationSet template doesn’t include `spec.syncPolicy` (so it defaults) but someone
    set a syncPolicy on the Application – you could ignore differences in syncPolicy to not get overwritten.

**CLI Reference (ArgoCD ApplicationSet):**

- Create: `argocd appset create -f appset.yaml` – server-side creation, you can use `--dry-run -o json` to preview as
  mentioned
  ([argocd appset create Command Reference - Argo CD - Declarative GitOps ...](https://argo-cd.readthedocs.io/en/latest/user-guide/commands/argocd_appset_create/#:~:text=Dry,output)).
- List: `argocd appset list` – lists all ApplicationSets with some info (maybe name, generators, etc)
  ([argocd appset Command Reference - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_appset/#:~:text=argocd%20appset%20get%20APPSETNAME)).
- Get: `argocd appset get <name>` – shows details of an ApplicationSet (likely YAML or summary including list of
  Applications it manages).
- Delete: `argocd appset delete <name>` – deletes the ApplicationSet (which will delete the Applications it created,
  unless create-only policy or orphaning).
- There is also `argocd appset generate <name>` in docs (or as per [22], `argocd appset generate` might preview apps).
- These commands are mostly wrappers around editing the ApplicationSet CR; often using `kubectl` to apply ApplicationSet
  manifests is just as common.

**API Usage (ApplicationSet):**

- ArgoCD’s API currently (as of v2.5) doesn’t have a first-class endpoint for ApplicationSet (since it’s a CR in the
  cluster managed by controller, not through ArgoCD’s server). So managing ApplicationSets is typically via Kubernetes
  API (kubectl) or ArgoCD CLI which uses a combination of ArgoCD API (for dry-run generate) and kubectl under the hood.
- To get the generated Applications list, check `.status.resources` in the ApplicationSet CR status (it lists the
  Applications currently managed).
- Error reporting: `.status.conditions` will show errors, e.g.,
  `Condition: ErrorOccurred=True, Message="Failed to generate using Git generator: authentication error..."`

### 4.3 Argo Rollout Spec Fields Reference

The **Rollout** CRD is defined by `argoproj.io/v1alpha1` and closely mirrors a Kubernetes Deployment spec plus strategy.
Key fields in `spec`:

- **replicas** (int): Desired number of pods for the application
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,runs%20and%20experiments%20to%20be)).
  Defaults to 1 if omitted. Can be dynamically scaled or auto-scaled (HPA).
- **selector** (Label selector): Defines how to identify pods managed by this Rollout
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,selector%3A%20matchLabels%3A%20app%3A%20guestbook)).
  Should match labels in the pod template. It’s required if `workloadRef` is not used (same as in Deployment).
- **template** (Pod template spec): The pod specification for your application (metadata + spec for containers, etc.)
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,demo%3Ablue)).
  Identical to a Deployment’s pod template. Use this if not using workloadRef.
- **workloadRef** (object): Instead of embedding a pod template, you can refer to an existing Deployment (or other
  workload type like ReplicaSet possibly) to “adopt” it
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,down%20after%20migrating%20to%20Rollout)).
  Fields:
  - **apiVersion**, **kind**, **name** of the referent. Currently supports Deployment and maybe ReplicaSet/StatefulSet.
  - **scaleDown** (string): Policy for scaling down the referenced workload once the Rollout takes over
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=to%20Rollout.%20,progressively)).
    Options:
    - `"never"`: Don’t scale down the old Deployment; both run (not typical).
    - `"onsuccess"`: Scale down the Deployment after the Rollout successfully promotes (becomes healthy)
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,progressively)).
    - `"progressively"`: Scale down the Deployment gradually as the Rollout scales up (mirrors canary progression)
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=healthy%20,progressively)).
- **minReadySeconds** (int): Minimum time a new pod should be ready (passed readiness probes) before it’s treated as
  available
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,minReadySeconds%3A%2030)).
  This delays advancement until pods are stable for that many seconds (e.g., to avoid quickly flipping traffic to pods
  that might still have issues).
- **revisionHistoryLimit** (int): How many old ReplicaSets to retain (like Deployment’s). Defaults to 10
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,Defaults%20to%2010%20revisionHistoryLimit%3A%203)).
- **paused** (bool): If true, the Rollout will start in a paused state
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,paused%3A%20true)).
  This means even if you apply a new spec, it won’t scale up the new ReplicaSet until unpaused. You can toggle this
  field to pause/unpause outside of the steps mechanism. Usually leave false (or let your steps manage pause).
- **progressDeadlineSeconds** (int): The time in seconds within which progress (as defined by new pods becoming ready)
  must occur or the Rollout is considered **Degraded** (progress deadline exceeded)
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,Defaults%20to%20600s%20progressDeadlineSeconds%3A%20600)).
  Defaults to 600s (10 minutes). Similar to Deployment’s progressDeadline.
- **progressDeadlineAbort** (bool): If true, when progressDeadline is exceeded, Argo Rollouts will automatically
  **abort** the rollout
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,progressDeadlineAbort%3A%20false)).
  Abort means it stops trying the new version. If you have an older stable, it will try to go back to it. By default
  this is false – it will mark degraded but not rollback.
- **restartAt** (string, date-time RFC3339): If set, the controller will ensure all pods have been restarted at or after
  this time
  ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,30T21%3A19%3A35Z)).
  Essentially, setting this field triggers a rolling restart (Rollout sets all pods with an older creationTimestamp to
  terminate). The field is usually empty; `kubectl argo rollouts restart` sets it to now. This is an alternative to
  manually changing something to force a restart.
- **rollbackWindow** (object): Allows fast rollbacks by keeping a window of previous revisions warm (available):
  - **revisions** (int): If set (e.g., 3), the controller tries to keep the last N ReplicaSets from being fully scaled
    down, so that if you rollback to one of them, it can promote faster
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,rollbackWindow%3A%20revisions%3A%203)).
    This is advanced – effectively, after a rollout, it might leave the prior RS scaled to some degree (maybe 10% or so)
    as a standby. This feature is more experimental and used in large systems for quick switchback without cold-start.
- **analysis** (object): History limits for analysis/experiment:

  - **successfulRunHistoryLimit** (int): How many successful AnalysisRuns and Experiment runs to retain in history
    (defaults 5)
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=replicas%3A%205%20analysis%3A%20,be%20stored%20in%20a%20history)).
  - **unsuccessfulRunHistoryLimit** (int): How many failed/inconclusive AnalysisRuns and Experiments to keep
    (defaults 5)
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,unsuccessfulRunHistoryLimit%3A%2010)).
  - (These are like revisionHistory but for analysis/experiment child resources.)

- **strategy** (object): **One of**:

  - **blueGreen** (object): Fields for BlueGreen strategy (if this is present, you can’t have canary, and vice versa).
    - **activeService** (string): Name of the Service that serves the active/stable pods
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=blueGreen%3A%20,service))
      (required for blueGreen).
    - **previewService** (string): Name of Service for preview pods
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,service))
      (optional).
    - **previewReplicaCount** (int): Number of pods to scale up in the new RS for preview (if you want to initially
      scale partial)
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,service)).
      If omitted, new RS scales to full `replicas`.
    - **autoPromotionEnabled** (bool): Default true. If false, after new RS is fully available, the rollout pauses,
      waiting for manual promotion
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,%2Boptional%20autoPromotionEnabled%3A%20false)).
    - **autoPromotionSeconds** (int): If autoPromotionEnabled is true, you can set a delay in seconds before
      auto-promote
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,%2Boptional%20autoPromotionSeconds%3A%2030)).
      If omitted, it waits indefinitely when Enabled=true? Actually if Enabled=true and no seconds, it promotes
      immediately when pods are ready. If you want a delay, set this.
    - **scaleDownDelaySeconds** (int): Delay after promotion before scaling down old RS
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,scaleDownDelaySeconds%3A%2030))
      (default 30).
    - **scaleDownDelayRevisionLimit** (int): How many old RS can wait (with scaleDownDelay) at once
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=scaleDownDelaySeconds%3A%2030))
      (like keep 2 old ones running until they eventually get scaled down one by one).
    - **abortScaleDownDelaySeconds** (int): Delay before scaling down the preview RS if rollout is aborted
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,is%2030%20second%20abortScaleDownDelaySeconds%3A%2030))
      (default 30; 0 means don’t auto-scale it down).
    - **antiAffinity** (object): Adds anti-affinity rules between latest and previous pods
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,100)).
      Only one of `requiredDuringSchedulingIgnoredDuringExecution` or `preferredDuringSchedulingIgnoredDuringExecution`
      should be set:
      - If `requiredDuringScheduling...` is an empty object `{}`, it defaults to requiring hostname anti-affinity (i.e.,
        do not place new pod on same node as any old pod).
      - If `preferredDuringScheduling...` is set, you give it a `weight` and a normal PodAffinityTerm structure (like
        you would in a pod spec antiAffinity). The example shows weight:1 and presumably default term (if empty might
        default similarly).
    - **activeMetadata** (object): Extra metadata to merge into pod template of the active ReplicaSet
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,optional%20activeMetadata%3A%20labels%3A%20role%3A%20active)).
      Supports `labels` and `annotations` sub-fields.
    - **previewMetadata** (object): Metadata for pods in the preview ReplicaSet
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,optional%20previewMetadata%3A%20labels%3A%20role%3A%20preview)).
    - **prePromotionAnalysis** (object): Analysis to run before switching activeService to new RS
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=%23%20Pre,svc.default.svc.kube.pc-tips.se)).
      - **templates** (list): Each item references an AnalysisTemplate or ClusterAnalysisTemplate by name (use
        `templateName` or `clusterScope: true` and `templateName`). Multiple templates can be listed (they will run in
        parallel).
      - **args** (list): Optional arguments to pass to the AnalysisTemplate (binding values to its parameters). Each arg
        has `name` and either `value` or `valueFrom`.
      - If analysis fails or is inconclusive, the rollout will pause or abort depending on configuration.
    - **postPromotionAnalysis** (object): Analysis to run after traffic cutover to new pods
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=%23%20Post,svc.default.svc.kube.pc-tips.se)).
      Same schema as prePromotionAnalysis.
    - Note: BlueGreen does **not** use a steps list. It’s basically: if autoPromotionEnabled=false, it will pause after
      new up, wait for `promote` or until autoPromotionSeconds triggers.
  - **canary** (object): Fields for Canary strategy:
    - **canaryService** (string): Service name for canary pods (for traffic splitting)
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,service)).
      Required if using trafficRouting.
    - **stableService** (string): Service for stable pods
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=canaryService%3A%20canary)).
      Required if using trafficRouting.
    - **steps** (list): The sequence of steps to perform
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,setWeight%3A%2020)).
      Each item is an object with one of these keys: `pause`, `setWeight`, `setCanaryScale`, `analysis`, `experiment`,
      `setHeaderRoute`, `setMirrorRoute`, `plugins`:
      - **pause**: can have `duration` (string, e.g., "5m") or be an empty object for indefinite
        ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,pause%3A%20duration%3A%201h)).
      - **setWeight**: (int) traffic percent to send to canary
        ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,setWeight%3A%2020)).
      - **setCanaryScale**: (object) options to scale canary RS:
        - **weight** (int): Scale canary RS to this percentage of desired replicas
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,setCanaryScale%3A%20weight%3A%2025)).
        - **replicas** (int): Scale canary RS to this exact number of pods
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,setCanaryScale%3A%20replicas%3A%203)).
        - **matchTrafficWeight** (bool): True to scale canary RS to the same percentage as traffic weight
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,setCanaryScale%3A%20matchTrafficWeight%3A%20true)).
        - Only one of the above can be specified in a step.
      - **analysis**: (object) run analysis at this point
        ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,rate)).
        Same fields as pre/post promotion analysis, except no `templates` list (actually yes it has templates list).
        Essentially an inline AnalysisRun.
      - **experiment**: (object) run an experiment at this step
        ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,rate))
        ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,acceptable%20if%20name%20is%20not)).
        Fields:
        - **duration** (string): How long to run the experiment (after which it will scale down the experiment’s pods)
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,acceptable%20if%20name%20is%20not)).
        - **templates** (list): Each template defines an experiment workload:
          - **name**: name of the experiment template.
          - **specRef**: either "stable" or "canary" meaning use the Rollout’s stable or canary pod template, OR it
            could reference an actual ReplicaSet spec inlined but usually it's stable/canary.
          - **replicas**: (int, optional) how many replicas for this template (if not specified, defaults maybe to 1 or
            same as rollout’s replicas?).
          - **weight**: (int, optional) percentage of traffic to send to this experiment template (if using traffic
            routing).
          - **service**: (object, optional) if provided, experiment will create a Service for this template’s pods. If
            `name` is not specified, it creates one with a generated name, if empty object it also generates.
        - **analyses** (list): One or more analysis tasks to run during the experiment:
          - Each item can have **name** (to identify) and either specify inline analysis or reference an
            AnalysisTemplate via `templateName` and provide args (similar to analysis step or BG analysis structure)
            ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=specRef%3A%20canary%20,be%20attached%20to%20the%20AnalysisRun)).
          - **analysisRunMetadata** can be provided to attach labels/annotations to the spawned AnalysisRun
            ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=templateName%3A%20mann,link)).
      - **setHeaderRoute**: (object) For Istio, set header-based route to canary
        ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,to%20apply%20the%20match%20rules)).
        Fields:
        - **name**: Name of the route (must be listed in trafficRouting.managedRoutes)
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,to%20apply%20the%20match%20rules)).
        - **match**: list of HTTP match conditions:
          - Each match can have **headerName** and a **headerValue** with one of `exact`, `regex`, `prefix` to match on.
            (Also Istio allows method and path as shown in setMirrorRoute example)
            ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=name%3A%20%27header,Not%20all%20traffic%20routers%20support))
            ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=acts%20as%20a%20removal%20of,all%20types%20headerValue)).
        - If match is empty and just name given, it effectively removes the header route (could be used to cleanup route
          at some step).
      - **setMirrorRoute**: (object) For Istio, set traffic mirroring to canary
        ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,a%20removal%20of%20the%20route)).
        Fields similar to headerRoute:
        - **name**: route name (must be in managedRoutes)
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,a%20removal%20of%20the%20route)).
        - **percentage**: what percentage of matching traffic to mirror to canary
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=name%3A%20%27header,exact%2C%20regex%2C%20prefix)).
        - **match**: list of conditions (method, path, headers similar to Istio VirtualService matches)
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=percentage%3A%20100%20,supported%20by%20all%20traffic%20routers)).
          The example in spec reference is detailed with method, path, headers (exact/regex/prefix)
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=and%20only%20one%20match%20type,HTTP%20url%20paths%20to%20match))
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=headers%3A%20agent,prefix%3A%20%27firefox)).
      - **plugin**: (object) Execute a Canary Step Plugin. Fields:
        - **name**: Name of the plugin (the rollout controller is configured with plugins by name).
        - **config**: Arbitrary configuration map for the plugin.
        - (This allows extending rollout steps with custom code, e.g., call an external system at a point).
    - **maxUnavailable** (int or string): Max number of pods that can be unavailable during update (works like
      Deployment’s, default 1)
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,immediately%20when%20the%20rolling)).
    - **maxSurge** (int or string): Max excess pods during update (default 1)
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=maxUnavailable%3A%201)).
    - **analysis** (object): Background analysis to run during rollout (non-blocking step)
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,svc.default.svc.kube.pc-tips.se)).
      - **templates** and **args** similar to analysis step. This starts when update begins and can continuously run
        checks. If a metric fails, by default it might mark the rollout as degraded or pause it (depending on
        configuration of the analysis template’s failure policy).
    - **antiAffinity** (object): Pod anti-affinity for canary vs stable pods (same schema as in blueGreen)
      ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=%23%20Anti,100)).
    - **trafficRouting** (object): Settings for integration with traffic shaping controllers:
      - **maxTrafficWeight** (int): If using NGINX or a custom plugin, you might change the scale of weight. For
        Istio/SMI, weight is implicitly 0-100. For NGINX, by default it’s 0-100 too but they allow 0-1000 scaling if
        needed. Default 100 if not set
        ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,defaults%20to%20100%20maxTrafficWeight%3A%201000)).
      - **managedRoutes** (list of objects): If using header/mirror routes, list the routes that Rollouts can manage, by
        name, in order of precedence
        ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=maxTrafficWeight%3A%201000%20,match%20the%20names%20from%20the)).
      - **istio** (object): Istio specific config:
        - **virtualService** (object): if one VirtualService:
          - **name** (string): Name of the VirtualService
            ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=istio%3A%20,more%20virtualServices%20can%20be%20configured)).
          - **routes** (list): Names of the routes within VirtualService to manage (if VS has multiple http routes). If
            single route in VS, this can be omitted.
        - **virtualServices** (list of objects): Optionally manage multiple VS (e.g., split traffic across multiple
          gateways). Each entry has **name** and **routes** similar to above
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=VirtualService%2C%20required%20otherwise%20virtualServices%3A%20,vsvc2%20%23%20required%20routes)).
        - (Rollout will find the VS in same namespace by that name and alter the weights for the stable vs canary
          service subsets).
      - **nginx** (object): NGINX Ingress controller config:
        - **stableIngress** (string): Name of the existing Ingress serving stable traffic
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,ingress%20annotationPrefix%3A%20customingress.nginx.ingress.kubernetes.io%20%23%20optional)).
        - **stableIngresses** (list): If multiple ingress resources divide traffic, list them
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=stableIngress%3A%20primary,Canary)).
        - **annotationPrefix** (string): If your ingress uses a custom annotation prefix for canary (default
          "nginx.ingress.kubernetes.io")
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,annotation.mygroup.com%2Fkey%3A%20value)).
        - **additionalIngressAnnotations** (map): Annotations to add to the canary Ingress that Rollout creates (like
          “canary-by-header” etc.)
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=optional%20additionalIngressAnnotations%3A%20%23%20optional%20canary,value%3A%20iwantsit%20canaryIngressAnnotations%3A%20%23%20optional)).
        - **canaryIngressAnnotations** (map): Specific annotations for the canary ingress (commonly
          `nginx.ingress.kubernetes.io/canary: "true"` and possibly `canary-weight` if not using header routes)
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=canary,annotation.mygroup.com%2Fkey%3A%20value)).
        - (Rollout works by creating a duplicate ingress resource with `-canary` suffix, adding annotations to split
          traffic according to weight or header).
      - **alb** (object): AWS ALB ingress config:
        - **ingress** (string): Name of Ingress (must exist)
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,optional)).
        - **servicePort** (int or string): Port of service (target group port) to manage weights for
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=alb%3A%20ingress%3A%20ingress%20,optional)).
        - **annotationPrefix** (string): Custom annotation prefix if not using default "alb.ingress.kubernetes.io"
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=ingress%3A%20ingress%20,optional)).
        - (Rollout will update the ALB ingress annotations like `.../weights` if I recall correctly).
      - **smi** (object): Service Mesh Interface (Linkerd, Traefik Mesh, etc.):
        - **rootService** (string): Name of the root Service (SMI uses a TrafficSplit CR which references a root service
          that points to two backend services)
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=,split%20%23%20optional)).
        - **trafficSplitName** (string): Name of the TrafficSplit resource to manage
          ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=smi%3A%20rootService%3A%20root,split%20%23%20optional)).
          If not given, I think Rollout might create one or derive one from rollout name.
        - (Rollouts will create or update a TrafficSplit CR to adjust weights between stable and canary services.)

- **status** (object): Not in spec, but good to know:
  - **availabileReplicas**, **readyReplicas**, **currentPodHash**, **currentStepIndex**, **pauseConditions**,
    **conditions**, **stableRS**, **canaryRS**, etc., are status fields Rollout uses.
  - **conditions** can include Progressing, Degraded, ReplicaFailure, etc. This is how ArgoCD’s health checks gauge it.
  - **BlueGreenPause** and **CanaryPause** conditions show why it’s paused (e.g., waiting for manual promotion vs
    waiting for analysis vs step pause).
  - For example, `status.pauseConditions` might list a pause reason (StepPause or BlueGreenPause) with startTime
    ([Rollout Spec - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argo-rollouts.readthedocs.io/en/stable/features/specification/#:~:text=status%3A%20pauseConditions%3A%20,00T1234)).
    Clearing a manual pause condition is what `promote` or `resume` does.

**CLI Reference (Argo Rollouts):**

Common `kubectl argo rollouts` commands (assuming plugin installed):

- **Get and Watch**:
  - `kubectl argo rollouts get rollout myrollout -n namespace --watch` – stream updates of the rollout (useful during a
    deployment).
  - `kubectl argo rollouts get rollout myrollout -o yaml` – get the full YAML including status to see details like
    conditions or analysis status.
  - `kubectl argo rollouts describe rollout myrollout` – similar to get, might provide events or breakdown per
    ReplicaSet.
- **Promotion/Pausing**:
  - `kubectl argo rollouts pause myrollout` – set spec.paused=true (immediate freeze).
  - `kubectl argo rollouts resume myrollout` – set spec.paused=false (if it was manually paused).
  - `kubectl argo rollouts promote myrollout` – if paused at a step or waiting BlueGreen, this proceeds to next step or
    switch.
  - `kubectl argo rollouts promote --full myrollout` – skip all remaining steps and go fully to end
    ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=,kubectl%20argo%20rollouts%20promote%20guestbook))
    ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=,full)).
  - `kubectl argo rollouts abort myrollout` – mark rollout aborted. The behavior: rollout will try to go back to stable
    service. Essentially it stops any new progress and can trigger scale-down of canary (if configured) and mark status
    aborted/degraded
    ([How to do blue/green and canary deployments with Argo Rollouts](https://www.redhat.com/en/blog/blue-green-canary-argo-rollouts#:~:text=You%20could%20do%20the%20same,of%20the%20rollout%20by%20using)).
- **Image Update**:
  - `kubectl argo rollouts set image myrollout container1=repo/image:tag` – updates the image of container1 in the
    Rollout spec
    ([argo-rollouts/examples/rollout-canary.yaml at master - GitHub](https://github.com/argoproj/argo-rollouts/blob/master/examples/rollout-canary.yaml#:~:text=argo,setWeight%3A%2040)).
    This will start a new rollout process (like doing kubectl set image on a Deployment).
- **Scaling**:
  - `kubectl argo rollouts scale myrollout --replicas=10` – scale the rollout (under the hood just patches
    spec.replicas).
- **History**:
  - `kubectl argo rollouts history myrollout` – lists revisions (ReplicaSets) with change cause (if annotated) and
    images.
  - `kubectl argo rollouts undo myrollout --to-revision=2` – rollback to revision 2 (patch spec.template back to that
    revision’s spec)
    ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=,117)).
- **Analysis**:
  - If an analysis is running (either standalone AnalysisRun or part of rollout):
    - `kubectl argo rollouts get analysisrun analysisrun-name` – show metrics status (e.g., how many successful
      measurements vs failed).
    - `kubectl argo rollouts terminate analysisrun analysisrun-name` – stop it early (will mark it as Terminated, which
      might cause rollout to proceed or abort depending on how that outcome is treated)
      ([Rollouts Promote - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_promote/#:~:text=,Rollouts%20Version)).
    - For analysis step, to abort rollout because analysis failing, often one would just let it fail or terminate with
      failure.
- **Experiment**:
  - `kubectl argo rollouts get experiment experiment-name` – shows experiment progress (how many of each template are
    running, etc).
  - `kubectl argo rollouts terminate experiment experiment-name` – stop an experiment before its duration ends (scale
    down experiment pods).
- **Dashboard/UI**:
  - `kubectl argo rollouts dashboard` – opens a local web UI for rollouts (you need port forward access). This shows
    real-time graph and allows clicking “Resume” or “Abort” etc, similar to ArgoCD UI but more focused.

**API Usage (Argo Rollouts)**:

- Since Argo Rollouts is a Kubernetes controller, the “API” is essentially the Kubernetes API for CRDs:
  - You can `kubectl apply -f rollout.yaml` to create or update a Rollout.
  - You can `PATCH` the Rollout (e.g., via `kubectl patch` or via client libraries).
  - The Argo Rollouts kubectl plugin itself uses the Kubernetes API to do things like patch spec.paused or patch
    spec.template (for set image).
- The Argo Rollouts controller also exposes some metrics and optionally an experimental metrics API server for web
  metrics, but that’s internal for analysis provider.
- You can also use ArgoCD’s resource actions to call Rollouts actions if configured. ArgoCD defines some resource
  actions (in `argocd-cm`) for Rollout, e.g., an action “Promote Full” that triggers a specific patch or CLI under the
  hood
  ([How to do blue/green and canary deployments with Argo Rollouts](https://www.redhat.com/en/blog/blue-green-canary-argo-rollouts#:~:text=In%20the%20ArgoCD%20interface%2C%20click,choose%20Abort%20to%20back%20out)).

To manually trigger a rollout via API in a pipeline, one could:

- Patch the Rollout CR to increment the template (like update image field) – which is effectively deploying a new
  version. Or use `kubectl argo rollouts set image` (which is scriptable).
- Alternatively, use ArgoCD’s application patch API to update the image tag in Git manifests and sync – but that’s more
  indirect.

### 4.4 Summary of “All Possible” Combinations

Between ArgoCD and Argo Rollouts, virtually any deployment scenario can be described. Some combinations explicitly
covered:

- **ApplicationSet Generators**: List, Cluster, Git (Dir/File), SCM (multi-repo), PRs, Matrix, Merge, Plugin,
  ClusterDecision. These can be combined (matrix/merge) to fit complex org structures (e.g., deploy all components (git
  dirs) to all clusters (cluster list) = matrix).
- **Rollout Strategies**: Canary (with any sequence of steps, including multi-step canary + analysis + experiment) or
  BlueGreen (with optional preview, manual or auto promotion) or even a basic "canary with one step 100%" which
  effectively mimics an all-at-once, or "blueGreen with previewReplicaCount=0" which mimics recreating pods one shot. If
  something is not specified (like if you omit both blueGreen and canary in spec.strategy), the Rollout will default to
  a RollingUpdate-like behavior (which in older versions wasn’t supported – you should choose one; I think one of them
  must be present).
- **Integration**: Rollouts can be used with Ingress or Service Mesh (Istio, Linkerd, SMIs) – if you don’t have any of
  those, you stick to basic functionality. If none of trafficRouting and setWeight steps are used, Rollout will do a
  rolling upgrade similar to Deployment (but without auto rollback).
- **Multi-Cluster**: ArgoCD can deploy Rollouts to multiple clusters exactly as it would any manifest. There’s nothing
  special needed except Argo Rollouts controller needs to be installed in those clusters. ArgoCD’s cluster add process
  should include CRD syncing if you want ArgoCD to be aware of health – ensure the health Lua for Rollout is present in
  argocd settings (by default ArgoCD bundles it).
- **Multi-Tenancy**: ArgoCD Projects and separate repos allow multiple teams to define their ApplicationSets and
  Rollouts, safely coexisting.

**Edge conditions not to forget**:

- If you try to use Argo Rollouts without defining either stableService/canaryService or trafficRouting, it will do
  pod-weight. It will attempt to scale pods to achieve weight, which might not perfectly equal percentages especially
  with small numbers. It's not a bug but a result of discrete pods.
- Argo Rollouts does not manage ConfigMaps/Secrets updates in a progressive way (only pods). If you want progressive
  config changes, one approach is to bake config into an ephemeral Deployment and use experiment, or use separate
  Rollouts for config (not common).
- ArgoCD and Rollouts both rely on Kubernetes events and status – ensure your cluster’s time and webhooks are
  functioning. If ArgoCD shows app healthy but you know rollout is mid-step, maybe health check config might need
  adjusting.

In conclusion, if a feature or argument is not detailed here (for example, “can I do rolling update with Argo Rollouts?”
– yes by designing a canary with one setWeight=100 step or just using Deployment), it likely means you have to use an
alternate approach within the given options. This documentation should serve as an authoritative reference for what can
be done with ArgoCD Application/ApplicationSet and Argo Rollouts in GitOps, and how to do it, along with best practices
to ensure smooth, secure operations
([Argo Rollouts | Argo](https://argoproj.github.io/rollouts/#:~:text=Argo%20Rollouts%20is%20a%20Kubernetes,progressive%20delivery%20features%20to%20Kubernetes))
([Migrating - Argo Rollouts - Kubernetes Progressive Delivery Controller](https://argoproj.github.io/argo-rollouts/migrating/#:~:text=Migrating%20,it%20involves%20changing%20three%20fields)).
