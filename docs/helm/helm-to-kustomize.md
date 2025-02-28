I am moving away from helm to be able to fully see what is being rendered. To really render all the files etc so we can
use it with our approach. Make sure everything is set in the values file and delete the other files. Then follow this:

# Helm To Kustomize

## Why helm is not declarative

The idea behind declarative infrastructure is that what you define is what gets set up on your system when you are
talking about helm there is a tendency to believe that specifying a value.yaml file is being "declarative" however the
main problem is that these values get injected into templates at runtime, meaning there is an opportunity for divergence
if the templates change. Also, the templates aren't generally kept in the same repo as the values.yaml so when trying to
figure out what is being deployed you have to go chart hunting.

_"Look at that beautiful helm template"_ said nobody, ever

This speaks volumes as let's face it Helm templates are complex and very hard to figure out what is going on.

## The hard to argue upside to Helm

So the question is why use helm then? Well believe it or not putting together all the resources needed for an
application (deployments, service, ingress, validation hooks etc) is a lot of work. My default nginx-ingress install has
11 resources. Remembering all that for each application is difficult, then you start including all the configurable
properties (env, args, commands etc) it's almost impossible to do this every time. This is where helm shines, it allows
to set "sensible" defaults that are configurable via the values if needed. Making installing most applications very
simple, however this comes with a downside, upfront visibility and transparency is lost, you don't generally figure out
what a helm chart has installed until it is up and running on your cluster, making for huge security problems (the same
security issues that you can get when installing pip or npm packages).

## The Way forward

So what is the way forward, we want to keep the awesome magic of Helm but at the same time, if we want to use
methodologies like GitOps, we need a more declarative way. This is where we use a structured approach to convert Helm
charts to Kustomize bases, keeping the configuration clear and maintainable.

## Directory Structure

When converting from Helm to Kustomize, maintain a clear directory structure:

```
your-app/
├── base/
│   └── app/              # Core application manifests
│       ├── configmap.yaml
│       ├── secrets.yaml
│       ├── deployment.yaml
│       └── kustomization.yaml
└── kustomization.yaml    # Root kustomization that references base
```

## Step 1: Helm Template Generation

First, generate the raw Kubernetes manifests from the Helm chart:

```bash
# Add the helm repository if needed
helm repo add repo-name https://charts.example.com
helm repo update

# Template out the manifests
helm template my-release repo-name/chart-name \
  --namespace my-namespace \
  --values values.yaml \
  --output-dir base/app
```

## Step 2: Organize Manifests

Instead of keeping all files in one directory, organize them logically:

1. Move generated files into appropriate subdirectories
2. Separate core components from optional ones
3. Create a base kustomization.yaml that references these files

Example base kustomization.yaml:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - configmap.yaml
  - deployment.yaml
  - service.yaml
```

## Step 3: Root Kustomization

Create a root kustomization.yaml that references your base:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - base/app/
```

## Real World Example: Cilium

Here's how we structured Cilium after converting from Helm:

```
cilium/
├── base/
│   └── cilium/              # Core Cilium manifests
│       ├── cilium-ca-secret.yaml
│       ├── cilium-configmap.yaml
│       ├── cilium-secrets-namespace.yaml
│       ├── ns.yaml
│       └── kustomization.yaml
└── kustomization.yaml       # Root kustomization
```

The core Cilium manifests are organized in their own directory, with a clear separation of:

- Configuration (cilium-configmap.yaml)
- Security (cilium-ca-secret.yaml)
- Namespace resources (ns.yaml, cilium-secrets-namespace.yaml)

This structure makes it easy to:

1. Track changes in version control
2. Review security-sensitive components
3. Maintain configuration separately from deployment logic
4. Apply changes through GitOps tools like ArgoCD

## Best Practices

1. Keep sensitive data separate from configuration
2. Use clear, descriptive filenames
3. Maintain a logical directory structure
4. Document any manual modifications needed after templating
5. Version control all manifests
6. Validate manifests before committing

## Conclusion

Converting from Helm to Kustomize requires more initial setup, but provides:

- Better visibility into deployed resources
- Easier version control and review
- More predictable deployments
- Improved security through transparency
- Better GitOps compatibility

Remember to validate your Kustomize configuration with:

```bash
kubectl apply -k your-app --dry-run=server
```
