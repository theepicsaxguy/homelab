I will analyze best practices for structuring a monorepo in 2025 that integrates ArgoCD, Kustomize, overlays, and
automated environment promotions. I'll also provide recommendations on merging infra and apps to avoid code duplication
while maintaining clarity. Additionally, I'll explore best approaches for implementing PR-based deployments, rollback
automation, and GitOps principles while ensuring disaster recovery remains simple. I'll get back to you with an
optimized structure and workflow soon.

# Kubernetes Monorepo Structure for GitOps with ArgoCD (2025)

Organize your **Kubernetes monorepo** with a clear separation of concerns between infrastructure and application
manifests. Use **Kustomize overlays** to avoid duplicating manifests for each environment while keeping differences
explicit. Leverage **ArgoCD ApplicationSets** to deploy apps across dev, staging, and prod (and ephemeral PR
environments) automatically, and use **Argo Rollouts** for progressive delivery (canary/blue-green) to handle
health-check-based promotions and automatic rollbacks. Everything is managed via GitOps, so a new cluster can be
bootstrapped with minimal commands for full disaster recovery. Below is an **optimized directory structure** and an
explanation of key decisions:

## Repository Structure Overview

- **Infrastructure vs. Applications:** Separate cluster-wide **infrastructure** configuration (namespaces, ingress
  controllers, ArgoCD itself, etc.) from **application** manifests. This avoids mixing concerns and makes the repo
  easier to navigate.
- **Base and Overlays:** Each application has a _base_ Kubernetes manifest (common to all environments) and _overlay_
  folders for each environment (dev, staging, prod, etc.). This Kustomize pattern prevents duplication by reusing the
  base and overlaying environment-specific patches.
- **ArgoCD Config:** ArgoCD’s own configuration (Applications, ApplicationSets, Projects) is stored declaratively in
  Git. This enables GitOps for ArgoCD itself and one-click (or one-command) bootstrapping of a fresh cluster.
- **Scalability:** Adding a new microservice or environment is as simple as adding a new folder or Kustomize overlay.
  ArgoCD ApplicationSets can dynamically pick up new apps/environments, so the structure scales to many services without
  manual duplication of config.

## Directory Layout

```plaintext
monorepo/
├── argocd/
│   ├── applicationsets/
│   │   ├── env-apps.yaml        # ApplicationSet for dev/staging/prod apps
│   │   ├── pr-previews.yaml     # ApplicationSet for PR preview environments
│   │   └── ... (additional ApplicationSets if needed per env or team)
│   ├── projects/                # ArgoCD Project definitions (group apps & RBAC)
│   │   └── default-project.yaml
│   └── bootstrap/
│       └── root-app.yaml        # Optional App-of-Apps to bootstrap all others
├── infrastructure/              # Cluster-wide and environment infrastructure
│   ├── base/                    # Base manifests for cluster (common)
│   │   ├── namespaces.yaml
│   │   ├── ingress-controller.yaml
│   │   ├── rbac.yaml            # Global RBAC (if any cluster roles)
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── dev/                 # Dev cluster-specific config
│       │   ├── kustomization.yaml (includes ../base and dev-only patches)
│       │   └── additional-dev-config.yaml
│       ├── staging/             # Staging cluster-specific config
│       │   └── ...
│       └── prod/                # Prod cluster-specific config
│           └── ...
├── apps/                        # Application manifests
│   ├── app1/
│   │   ├── base/                # Base K8s manifests for app1
│   │   │   ├── rollout.yaml       # Argo Rollout (or Deployment) for app1
│   │   │   ├── service.yaml       # Service for app1
│   │   │   ├── configmap.yaml     # Config defaults
│   │   │   └── kustomization.yaml (references all base manifests)
│   │   └── overlays/
│   │       ├── dev/             # Overlay for dev environment
│   │       │   ├── kustomization.yaml (includes ../../base + dev patches)
│   │       │   └── patch-dev.yaml   # e.g., use dev image tag, env-specific env vars
│   │       ├── staging/         # Overlay for staging
│   │       │   └── patch-staging.yaml (e.g., replicas, config differences)
│   │       └── prod/            # Overlay for prod
│   │           └── patch-prod.yaml    # e.g., higher replicas, prod URLs
│   ├── app2/
│   │   └── ... (similarly structured as app1)
│   └── ... (more applications)
└── scripts/                     # (Optional) CI/CD scripts for automation
    ├── promote-to-staging.sh    # Example script to promote manifests dev→staging
    └── cleanup-preview.sh       # Example script to cleanup preview namespaces
```

### `argocd/` – ArgoCD Configuration and Bootstrap

All ArgoCD configuration is stored here in Git. **ApplicationSets** definitions (`env-apps.yaml`, `pr-previews.yaml`)
tell ArgoCD how to generate Applications for each app/environment combo. For example, an ApplicationSet might scan the
`apps/*/overlays/dev` folders to create a dev deployment for every app, and likewise for staging/prod. This avoids
writing individual `Application` YAMLs for each service and environment. (In the Codefresh example, an ApplicationSet
was configured to “go to the `apps` folder, find each app’s `envs/qa` overlay, and create an ArgoCD Application for it”
([Structuring Argo CD Repositories | ArgoCD Best Practices](https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/#:~:text=%E2%80%9CGo%20to%20the%20,invoices%E2%80%9D%20is%20only%20in%20QA))
– the same idea applies for dev/staging/prod overlays in our structure.) We also include an ApplicationSet for PR
previews (discussed below). ArgoCD **Projects** (in `projects/`) are used to group apps and set RBAC (for instance, a
project per team or environment to restrict access). Finally, a **bootstrap App-of-Apps** (`bootstrap/root-app.yaml`)
can be used to deploy all ApplicationSets at once – this means bringing a new cluster to the desired state is as simple
as applying this one ArgoCD application. In practice, you’d install ArgoCD, then apply `root-app.yaml`; ArgoCD will then
sync everything else (all apps and infrastructure) automatically. _This enables full disaster recovery with minimal
effort – a single manifest can deploy dozens of applications in one step
([Structuring Argo CD Repositories | ArgoCD Best Practices](https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/#:~:text=bootstrap%20an%20empty%20cluster%20from,zero%20to%20everything))._

### `infrastructure/` – Cluster Infrastructure & Environment Setup

This contains Kubernetes manifests that are **cluster-scoped or shared across apps**, organized with Kustomize. The
`base/` folder holds common infrastructure definitions (e.g. creating required namespaces, cluster-wide RBAC like
ClusterRoles, or installing an ingress controller or ArgoCD itself if you manage ArgoCD via GitOps). Under `overlays/`,
each environment (dev, staging, prod) has a folder that customizes the base for that environment. For example,
`overlays/prod` might include high-availability settings, network policies, or different ingress domain names for
production. This separation ensures you **don’t repeat identical YAML** across environments – you define it once in base
and only override what’s necessary in each overlay. It also keeps environment-specific config (like a dev-only test tool
or a prod-only monitoring tweak) isolated. ArgoCD can sync these as separate Applications (e.g., an `infrastructure-dev`
app for the dev environment’s cluster components, etc.). If each environment corresponds to a different cluster, the
ArgoCD ApplicationSet or Applications would target the respective cluster contexts.

### `apps/` – Application Manifests (Base & Overlays)

Each application (microservice) lives in its own directory under `apps/`. Within an app, the `base/` folder contains the
generic Kubernetes manifests for that app – Deployment (or Argo Rollout), Services, ConfigMaps, etc – _agnostic to any
environment_. The base should be deployable as-is, using placeholder images or config defaults that work in all
environments. Then, each environment has an overlay (`overlays/dev`, `overlays/staging`, `overlays/prod` etc.) which
references the base and applies environment-specific patches via Kustomize. For example, the dev overlay might patch the
container image tag to a `:dev` tag, use smaller resource requests, and enable debug logging; the prod overlay might
point to the `:latest` or a specific release tag, increase replicas, and use production configuration. This
**base/overlay pattern** avoids duplicating entire manifest files for each environment – only the differences are
captured in overlay patches. It maintains clarity because anyone can inspect, say, the `apps/app1/overlays/prod/` folder
to see exactly what’s different in prod (and the base shows what’s common). Developers can even build and inspect the
final manifest for a given env with a single command (e.g., `kustomize build apps/app1/overlays/prod`) to verify it,
aligning with GitOps transparency. All application manifests are **declarative** and live in Git, so ArgoCD can deploy
the exact state of each environment from these files.

**Why this structure?** It strictly follows GitOps best practices by keeping all desired state in version control,
layered to minimize repetition. The three-layer approach (base app manifests → ArgoCD ApplicationSets → optional
bootstrap app) cleanly separates concerns
([Structuring Argo CD Repositories | ArgoCD Best Practices](https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/#:~:text=At%20the%20lowest%20level%20we,in%20the%20promotion%20blog%20post))
([Structuring Argo CD Repositories | ArgoCD Best Practices](https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/#:~:text=Last%2C%20as%20an%20optional%20component,it%20is%20not%20always%20essential)).
The base app manifests are _self-contained_ and can even be deployed manually if needed (useful for testing outside
ArgoCD)
([Structuring Argo CD Repositories | ArgoCD Best Practices](https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/#:~:text=At%20the%20lowest%20level%20we,in%20the%20promotion%20blog%20post)).
The ApplicationSets at the next layer wrap those manifests into ArgoCD apps (so we treat ArgoCD configs separate from
pure K8s manifests)
([Structuring Argo CD Repositories | ArgoCD Best Practices](https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/#:~:text=One%20level%20above%2C%20we%20have,and%20not%20individual%20Application%20CRDs)).
And the optional root Application (app-of-apps) groups everything, making it easy to bring up a new environment or
recover—just apply that one root, and it will instantiate all other applications
([Structuring Argo CD Repositories | ArgoCD Best Practices](https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/#:~:text=We%20also%20have%20an%20optional,cluster%20from%20zero%20to%20everything)).
This layering means **full cluster recovery** is trivial: you don’t run dozens of `kubectl apply` commands or scripts,
you rely on ArgoCD syncing from Git (after an initial bootstrap). Git is the single source of truth, and no changes are
made to the cluster outside of Git commits (strict GitOps).

## ArgoCD ApplicationSets and Applications Usage

**ApplicationSets for Multi-Environment Deployments:** Rather than writing an ArgoCD `Application` for each
app/environment (which would be tedious and prone to drift), we use ArgoCD **ApplicationSet** controllers to automate
this. For example, the `env-apps.yaml` ApplicationSet can define a matrix of applications and environments (or use a Git
directory generator) to produce one ArgoCD Application per combination. It might scan the repo for any
`apps/*/overlays/dev` folder and generate a dev app deployment for each, naming it something like `app1-dev`. The
snippet below illustrates the concept:

```yaml
# (Inside argocd/applicationsets/env-apps.yaml)
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: apps-all-envs
spec:
  generators:
    - git:
        repoURL: https://github.com/your-org/your-monorepo.git
        revision: main
        directories:
          - path: apps/*/overlays/* # finds any env overlay for any app
  template:
    metadata:
      name: '{{index .path.segments 1}}-{{index .path.segments 3}}' # e.g., "app1-prod"
    spec:
      project: default
      source:
        repoURL: https://github.com/your-org/your-monorepo.git
        targetRevision: main
        path: '{{.path.path}}' # path to the overlay folder in repo
      destination:
        server: '{{ if eq (index .path.segments 3) "prod" }}https://prod-cluster{{ else }}https://dev-cluster{{ end }}'
        namespace: '{{index .path.segments 1}}-{{index .path.segments 3}}' # e.g., namespace "app1-prod"
      syncPolicy:
        automated: { prune: true, selfHeal: true }
```

In this example, the ApplicationSet uses a Git directory scan to find each app’s overlay folder and creates an
Application accordingly. The naming and namespace are templated from the folder names. This means if you add a new app
folder or a new overlay, ArgoCD will detect it and deploy automatically – **zero manual config needed for new
apps/environments**. You could also split this into one ApplicationSet per environment (e.g., one for all dev apps, one
for staging, etc.) depending on your preference. The result is the same: ArgoCD manages a set of Applications
internally, one per app per env, but you don’t have to write those by hand.

**ArgoCD Applications:** In a few cases, you might still use individual `Application` CRs. For example, the cluster
infrastructure stacks (in `infrastructure/overlays/*`) could each be an ArgoCD Application, or you might include them in
the ApplicationSet as well. If your cluster infra is fairly static (dev/staging/prod differences are small), you can
manage those with a simple `Application` per env, or also via an ApplicationSet. The key is that **ArgoCD itself deploys
ArgoCD Applications from Git**, so even ArgoCD’s knowledge of “what to sync” is stored declaratively. This approach
adheres to GitOps – no ad-hoc `argocd app create` commands are needed once the definitions are in Git.

**Bootstrap (App-of-Apps):** The `bootstrap/root-app.yaml` is an ArgoCD Application that uses Argo’s _App-of-Apps_
pattern to point at the `argocd/` folder. It might have a Kustomization or simply point to a directory that contains all
other ApplicationSet and Application manifests. When you apply this single root application to a new cluster’s ArgoCD,
it will recursively create all the Applications/ApplicationSets that manage everything else. As Codefresh notes, this
isn’t strictly required but is very useful for quickly bootstrapping an empty cluster from zero to everything with one
manifest
([Structuring Argo CD Repositories | ArgoCD Best Practices](https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/#:~:text=We%20also%20have%20an%20optional,cluster%20from%20zero%20to%20everything)).
This ensures **disaster recovery** is just: install ArgoCD, apply the bootstrap App, and watch ArgoCD reconstruct the
entire desired state (apps, infrastructure, configurations, etc.). No manual steps beyond that initial apply, which is
exactly what you want for GitOps.

## PR-Based Ephemeral Environments

To support preview environments for feature branches or pull requests, we use a dedicated ArgoCD ApplicationSet (stored
in `argocd/applicationsets/pr-previews.yaml`). This uses the **Pull Request generator** in ArgoCD to dynamically create
an Application for each open PR (with a specific label) and remove it when the PR is closed. In practice, when a
developer opens a PR and labels it (e.g., with “preview”), ArgoCD’s ApplicationSet will detect that PR via the SCM API
and spin up a full environment for that PR. _For each PR, an ArgoCD ApplicationSet with a PR generator creates an
ephemeral application deployment, and cleans it up when the PR is merged or closed
([Creating ephemeral preview apps with Argo CD](https://jmsbrdy.com/blog/previews-with-argo#:~:text=,CD%20Application%20for%20each%20PR))._
The preview ApplicationSet template can reuse the same Kustomize base as dev/staging, but point to a unique overlay or
use the PR branch as the source.

**How it works:** We include a minimal Kustomize overlay (or Kustomize **component**) for “preview” deployments. This
could be as simple as a patch that sets the image tag to the PR’s image and perhaps uses a `${PR_NUMBER}` in resource
names. The ApplicationSet PR generator can provide context variables like the PR branch name, PR number, and commit SHA.
For example, the template might set `targetRevision: "{{head_sha}}"` to deploy the PR’s commit, and use
`path: apps/app1/overlays/dev` (reusing the dev overlay) or a special `apps/app1/overlays/preview` if needed. We also
dynamically create a namespace for the preview (ArgoCD can auto-create namespaces on sync). In our structure, we prefix
preview namespaces with “preview-” and perhaps the branch name or PR number for clarity (e.g., `preview-feature-123`).
When the PR is updated with new commits, ArgoCD will sync the preview environment to the latest PR commit. When the PR
is closed or merged, ArgoCD detects it and **automatically deletes the ephemeral Application** (and we can have a hook
or garbage-collection job to delete the namespace)
([Create Temporary Argo CD Preview Environments Based On Pull Requests](https://codefresh.io/blog/creating-temporary-preview-environments-based-pull-requests-argo-cd-codefresh/#:~:text=Destroying%20the%20temporary%20Argo%20CD,application)).
This workflow means every PR can get a real environment for QA/testing with no manual setup, and it adheres to GitOps
because the PR’s own branch in Git defines what’s deployed.

**Why labeled PRs?** We only deploy for PRs that are labeled (e.g., “deploy-preview”) to ensure that we don’t spin up
environments for every single PR – only those that need a preview. Additionally, we coordinate with CI: the CI pipeline
builds a preview Docker image for the PR and, once ready, applies the label to the PR (or triggers ArgoCD via a
webhook). This ensures ArgoCD deploys only after the image is available, avoiding unnecessary failures
([Create Temporary Argo CD Preview Environments Based On Pull Requests](https://codefresh.io/blog/creating-temporary-preview-environments-based-pull-requests-argo-cd-codefresh/#:~:text=If%20this%20is%20an%20issue,CD%20creates%20the%20temporary%20environment)).
The result is an automated preview environment feature: ephemeral, on-demand, and garbage-collected on PR closure –
great for testing feature branches in isolation.

## Automated Environment Promotion Workflow (Dev → Staging → Prod)

This setup supports **progressive promotion of releases** through environments, gated by health checks. The general
workflow is: when code is merged to the main branch, ArgoCD deploys it to the **dev environment** (continuous deployment
to dev). After the new version is running in dev, it can be **promoted to staging and then prod automatically** if it
passes health criteria. We achieve this with a combination of GitOps automation and **Argo Rollouts** for progressive
delivery:

- **Argo Rollouts for Progressive Delivery:** In each environment, we replace the standard Deployment with an **Argo
  Rollouts** `Rollout` resource (as seen in `app1/base/rollout.yaml`). Argo Rollouts allows advanced deployment
  strategies (blue-green, canary, etc.) and integrates analysis steps. For example, in staging and prod, we might use a
  _canary strategy_ that gradually increases traffic to the new version while running automated health checks (using
  Prometheus, datadog, or custom metrics). If the metrics look good, the Rollout proceeds; if a problem is detected, the
  Rollout will **automatically rollback to the previous stable version**
  (["Service Pauses on Release" is a thing of the past--Non-Stop "Deploy Strategies" by Argo Rollouts | NTT DATA Group](https://www.nttdata.com/global/en/insights/focus/2024/service-pauses-on-release-is-a-thing-of-the-past--non-stop-deploy-strategies-by-argo-rollouts#:~:text=release%2C,process%20and%20reducing%20deployment%20risk)).
  This means even within a single environment, a bad release won’t fully deploy – it’s caught and reverted by the
  Rollouts controller based on real-time health checks. _“Metrics are analyzed to determine whether a release has
  succeeded or failed. If it has failed, it is automatically rolled back.”
  (["Service Pauses on Release" is a thing of the past--Non-Stop "Deploy Strategies" by Argo Rollouts | NTT DATA Group](https://www.nttdata.com/global/en/insights/focus/2024/service-pauses-on-release-is-a-thing-of-the-past--non-stop-deploy-strategies-by-argo-rollouts#:~:text=release%2C,process%20and%20reducing%20deployment%20risk))_
  Argo Rollouts thus ensures that promotions to 100% traffic happen only when the release is healthy, minimizing the
  blast radius of issues.

- **Health-Check Based Promotion to Next Environment:** Once a version is stable in the dev environment, our CI/CD
  pipeline (or ArgoCD Notifications/Events) can promote it to the next stage. A typical pattern is to store the image
  tag (or Git commit) deployed in each environment in Git. For example, we might have a file or Kustomize patch (like a
  `version.yaml`) in the dev overlay that gets updated to the new image tag on merge. After deployment, an automated
  health check (integration tests, or observing Argo Rollouts analysis result) confirms dev is healthy. Then a script
  (as shown in `scripts/promote-to-staging.sh`) or an ArgoCD trigger copies that version tag to the staging overlay
  (e.g., updates `apps/app1/overlays/staging/patch-staging.yaml` with the new image tag). This is done via a Pull
  Request to the monorepo – keeping promotion actions in Git. When that PR is merged, ArgoCD picks up the change and
  deploys the new version to **staging**. The same process repeats for promotion from staging to prod: once the release
  proves stable in staging (possibly after a soak time or additional tests), the image tag is copied to the prod overlay
  manifest, triggering ArgoCD to deploy prod.

- **Auto Rollback and Halt on Failures:** If a deployment fails health checks in an intermediate environment, it won’t
  be promoted forward. For instance, if the canary in staging fails (error rate too high, or a manual QA check fails),
  Argo Rollouts will rollback staging to the previous version automatically. Our promotion pipeline would detect that
  and _not_ advance this release to prod. This essentially automates **promotion with quality gates** – only healthy
  releases progress. In many cases, Argo Rollouts’ built-in analysis (checking metrics like HTTP 5xx rate, latency,
  etc.) can make this decision without human intervention. You can define in the Rollout an AnalysisTemplate that, say,
  checks if error percentage > 1% over 10 minutes; if so, abort and rollback
  (["Service Pauses on Release" is a thing of the past--Non-Stop "Deploy Strategies" by Argo Rollouts | NTT DATA Group](https://www.nttdata.com/global/en/insights/focus/2024/service-pauses-on-release-is-a-thing-of-the-past--non-stop-deploy-strategies-by-argo-rollouts#:~:text=,the%20values%20of%20acquired%20metrics)).
  This ensures that a **failed promotion triggers an immediate rollback** in that environment, and the failure is not
  propagated.

- **Promotion Pipeline Tooling:** The heavy lifting of moving artifacts between environments is handled by Git and
  ArgoCD. Some teams use Argo Workflows or Tekton to implement the promotion pipeline (listening for ArgoCD app health
  or test results, then committing to the repo to promote). Others use ArgoCD’s new _ApplicationSet with plugins_ or
  event hooks. Regardless, the principle is the same: **Git is updated to reflect promotions**, rather than manually
  kubectl applying to the next env. This maintains a full audit trail of what went to staging and when. Codefresh’s
  recommended approach, for example, is copying a version file from one env folder to another to promote a release
  ([How to Model Your GitOps Environments](https://codefresh.io/blog/how-to-model-your-gitops-environments-and-promote-releases-between-them/#:~:text=match%20at%20L422%20Scenario%3A%20Promote,staging%20environment%20in%20the%20US))
  ([How to Model Your GitOps Environments](https://codefresh.io/blog/how-to-model-your-gitops-environments-and-promote-releases-between-them/#:~:text=Scenario%3A%20Promote%20application%20version%20from,staging%20environment%20in%20the%20US))
  – we follow a similar idea by updating the Kustomize overlay for the next environment with the new version.

In summary, **dev → staging → prod promotion is automated and safe**. Dev is updated first; when it’s good (all tests
pass, metrics are healthy), staging is updated; when staging is good, prod is updated. Thanks to Argo Rollouts, each
update in staging/prod is a gradual rollout with automatic rollback on issues, so prod promotions are **progressive and
reversible**. This gives you a CD pipeline that’s both fast (no human needed to approve every step in normal conditions)
and reliable (issues trigger rollbacks and stop promotions).

## Managing Secrets and Configuration Safely

**Secrets:** Storing plain Kubernetes Secrets in Git is not secure, so we incorporate a GitOps-friendly secret
management solution. Common best practices include using **Bitnami Sealed Secrets** or **Mozilla SOPS** to keep
encrypted secrets in the repo
([Secret Management - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/#:~:text=,Vaults)).
For example, you might encrypt your secret values with SOPS and include the encrypted file in the app overlay; a
Kustomize plugin or ArgoCD plugin will decrypt it at deploy time. Alternatively, **External Secrets Operator** can be
used – in this model, your Git repo contains ExternalSecret CRs which reference an external vault (AWS Secrets Manager,
HashiCorp Vault, etc.) to fetch the actual secret values. ArgoCD applies those ExternalSecret CRs, and then the operator
injects the real secrets from the vault into Kubernetes. The ArgoCD docs note that GitOps teams commonly use **Sealed
Secrets, External Secrets Operator, or Vault integration** to handle secrets
([Secret Management - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/#:~:text=,Vaults)).
In our repo structure, a `secrets/` directory could store encrypted secret manifests (or we place them alongside other
manifests, encrypted). We ensure that each environment’s secrets are managed separately – e.g., dev secrets vs prod
secrets are different files (with different keys and access permissions). This structure, combined with something like
Sealed Secrets, means even if someone deploys a new cluster, they can retrieve the necessary secrets (ArgoCD will create
the sealed secret which the cluster can decrypt with the correct private key). **No secrets are ever stored in
plaintext** in Git, satisfying security best practices.

**Config and Params:** Non-secret configuration that differs per environment (feature flags, resource limits, URLs,
etc.) can be handled via ConfigMaps or Kustomize `values.yaml` patches. We might have a `values.yaml` in each overlay
with environment-specific values that the app reads from ConfigMap. This keeps such config under version control and
auditable. If certain settings should not be promoted between envs (e.g., a URL that’s always different in prod vs dev),
we document those in the respective overlay and never override them during promotions. The promotion scripts only carry
over what should move (like image tags or dynamic tuning parameters).

**RBAC:** We enforce **Role-Based Access Control** both at cluster level and within ArgoCD:

- On the cluster, each application runs in its own namespace (notice in the ApplicationSet template we named namespaces
  like `app1-dev`, `app1-staging`, etc.). Each namespace has roles scoped to just that app’s resources. For example,
  app1’s microservice might have a Kubernetes `Role` allowing it to read its own ConfigMaps or write to its own
  resources if needed, but it won’t have access to other namespaces. These Roles and RoleBindings are defined in our
  manifests (could be part of `infrastructure/rbac.yaml` or within each app’s base if app-specific). By defining them in
  Git, we ensure consistent permissions across environments and clusters.
- ArgoCD Projects (configured in `argocd/projects/`) add another RBAC layer for deployment. We can restrict an ArgoCD
  Project to only sync applications in certain namespaces or to certain clusters. For instance, a “prod” project might
  only allow ArgoCD to deploy to the production cluster namespaces, and perhaps locked down so only certain people can
  approve changes (if manual gating was desired). In our strict GitOps setup, ArgoCD auto-syncs everything, but you
  could configure manual sync for prod if policy requires human oversight (still via ArgoCD UI/cli, not
  `kubectl apply`).
- We practice **least privilege**: ArgoCD’s own service account has permissions only to the namespaces it manages,
  developers have access only through Git and ArgoCD (not direct cluster access in day-to-day), and each app’s
  credentials (like database passwords) are handled via the secret solutions mentioned. This way, a compromised app in
  dev, for example, cannot affect resources in prod due to namespace isolation and RBAC.

## Scalability and Maintainability Benefits

This folder structure is designed to scale with your organization’s needs:

- **Adding a new microservice:** Just create a new folder under `apps/` with its base and overlays. ArgoCD’s
  ApplicationSet will automatically detect it and deploy it to the specified environments (assuming you add the overlay
  folders and perhaps adjust a list in the generator if using a static list). There’s no need to modify pipelines or
  write new ArgoCD Application manifests for it – it “plugs in” to the existing framework.
- **Adding a new environment:** Similarly, if tomorrow you add a `uat` environment, you can add an overlay (and
  corresponding cluster config in `infrastructure/overlays/uat`). Then update the ApplicationSet to include `uat` (or if
  using the directory scanner with wildcard, it might even pick it up if the pattern allows). All apps that have a `uat`
  overlay will get deployed there. This is much cleaner than branching your Git repo per environment or duplicating
  manifests – we keep one repo, one branch, multiple folders. (Using folders per environment is a proven approach for
  GitOps that avoids the pitfalls of separate branches for envs
  ([How to Model Your GitOps Environments](https://codefresh.io/blog/how-to-model-your-gitops-environments-and-promote-releases-between-them/#:~:text=match%20at%20L114%20explained%20why,environments%20when%20folders%20are%20used)).)
- **Clarity of source of truth:** At any time, you can see exactly what’s running in each environment by looking at the
  respective overlay in Git. Developers find it easy to understand config differences by comparing overlay patches. If a
  config diverges too much, that’s a sign to refactor into base vs env-specific or use Kustomize components – all of
  which our structure supports.
- **GitOps Confidence:** Since everything needed to rebuild the environment (except perhaps external resources like DNS
  or database data) is in Git, we can recreate any environment from scratch. This also means pull requests against this
  repo are the way to change infrastructure or deployments – enabling code review, audit trails, and integration with CI
  (for linting YAML, validating Kustomize builds, even running ArgoCD dry-runs).
- **Minimal manual work:** On a blank cluster, **one or two commands can restore everything**. For example, after
  setting up ArgoCD, applying the `bootstrap/root-app.yaml` will instantiate all environment infrastructure and
  applications as defined in the repo. In a Codefresh demo, _a single manifest deploys a dozen applications in one shot_
  ([Structuring Argo CD Repositories | ArgoCD Best Practices](https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/#:~:text=bootstrap%20an%20empty%20cluster%20from,zero%20to%20everything))
  – that same power applies here. This makes disaster recovery or spinning up a new stage (like creating a new prod
  cluster in another region) very straightforward.

Finally, using **ArgoCD ApplicationSets** and **Argo Rollouts** in tandem provides a powerful GitOps-driven CD pipeline.
ApplicationSets handle the fan-out to multiple apps/envs (including ephemeral PR environments), and Argo Rollouts
handles the safe, progressive delivery within each environment. The outcome is a monorepo that implements **full
GitOps**: all environments declaratively defined, CI pipelines promoting changes via Git commits, CD systems deploying
automatically, and built-in deployment strategies ensuring stability (with automatic rollback on issues). This structure
is ready for 2025 and beyond – it’s cloud-native, scalable, secure, and minimizes duplication while remaining clear and
discoverable to engineers.

**Sources:**

1. Brdy, J. – _“Creating ephemeral preview apps with Argo CD.”_ (Example of PR-based ephemeral env with ArgoCD
   ApplicationSet)
   ([Creating ephemeral preview apps with Argo CD](https://jmsbrdy.com/blog/previews-with-argo#:~:text=,CD%20Application%20for%20each%20PR))

2. Codefresh – _“Structuring Argo CD Repositories with ApplicationSets.”_ (Three-level GitOps structure: manifest >
   appset > bootstrap for easy recovery)
   ([Structuring Argo CD Repositories | ArgoCD Best Practices](https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/#:~:text=We%20also%20have%20an%20optional,cluster%20from%20zero%20to%20everything))
   ([Structuring Argo CD Repositories | ArgoCD Best Practices](https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/#:~:text=At%20the%20lowest%20level%20we,in%20the%20promotion%20blog%20post))

3. NTT Data – _“Non-Stop Deploy Strategies by Argo Rollouts.”_ (Argo Rollouts canary deployments with automated analysis
   and rollback on failure)
   (["Service Pauses on Release" is a thing of the past--Non-Stop "Deploy Strategies" by Argo Rollouts | NTT DATA Group](https://www.nttdata.com/global/en/insights/focus/2024/service-pauses-on-release-is-a-thing-of-the-past--non-stop-deploy-strategies-by-argo-rollouts#:~:text=release%2C,process%20and%20reducing%20deployment%20risk))
   (["Service Pauses on Release" is a thing of the past--Non-Stop "Deploy Strategies" by Argo Rollouts | NTT DATA Group](https://www.nttdata.com/global/en/insights/focus/2024/service-pauses-on-release-is-a-thing-of-the-past--non-stop-deploy-strategies-by-argo-rollouts#:~:text=,the%20values%20of%20acquired%20metrics))

4. ArgoCD Official Docs – _“Secret Management.”_ (GitOps secret management options like Sealed Secrets, External Secrets
   Operator, Vault)
   ([Secret Management - Argo CD - Declarative GitOps CD for Kubernetes](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/#:~:text=,Vaults))
