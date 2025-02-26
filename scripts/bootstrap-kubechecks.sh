#!/bin/bash
set -euo pipefail

echo "Bootstrapping Kubechecks before ArgoCD takeover..."

if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN environment variable is not set."
    echo "Please set the GITHUB_TOKEN environment variable with a valid GitHub token."
    echo "Example: export GITHUB_TOKEN=your_github_token"
    exit 1
fi

# Create namespace and set up initial resources
echo "Creating kubechecks namespace..."
kubectl create namespace kubechecks --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repository
echo "Adding Kubechecks Helm repository..."
helm repo add kubechecks https://zapier.github.io/kubechecks/
helm repo update

# Create a temporary bootstrap secret (will be replaced by sm-operator)
echo "Creating temporary bootstrap secret..."
kubectl create secret generic kubechecks-vcs-token \
  --namespace kubechecks \
  --from-literal=KUBECHECKS_VCS_TOKEN="$GITHUB_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

# Install Kubechecks with proper configuration
echo "Installing Kubechecks via Helm..."
helm upgrade --install kubechecks kubechecks/kubechecks \
  --namespace kubechecks \
  --set "securityContext.allowPrivilegeEscalation=false" \
  --set "securityContext.capabilities.drop[0]=ALL" \
  --set "securityContext.runAsNonRoot=true" \
  --set "securityContext.seccompProfile.type=RuntimeDefault" \
  --set "podSecurityContext.runAsNonRoot=true" \
  --set "podSecurityContext.runAsUser=1000" \
  --set "podSecurityContext.fsGroup=1000" \
  --set "config.argocd.apiServerAddr=argocd-server.argocd.svc" \
  --set "config.argocd.namespace=argocd" \
  --set "config.argocd.repositoryEndpoint=argocd-repo-server.argocd.svc:8081" \
  --set "config.argocd.repositoryInsecure=true" \
  --set "config.vcs.type=github" \
  --set "config.kubernetes.type=local" \
  --set "config.monitorAllApplications=true" \
  --set "config.logLevel=info" \
  --set "config.showDebugInfo=false" \
  --set "config.enableKubeconform=true" \
  --set "config.enablePreupgrade=true" \
  --set "config.repoRefreshInterval=5m" \
  --set "config.maxConcurrentChecks=32" \
  --set "config.maxQueueSize=1024" \
  --set "config.tidyOutdatedCommentsMode=hide" \
  --set "config.worstKubeconformState=panic" \
  --set "config.worstPreupgradeState=panic" \
  --wait

echo "Kubechecks bootstrap complete."
echo "The temporary GitHub token secret will be replaced by the Bitwarden Secrets Manager."
echo "Ensure your BitwardenSecret resource is properly configured in Git."
echo ""
echo "Important notes:"
echo "1. ArgoCD will now take over the management of Kubechecks"
echo "2. The sm-operator will manage the GitHub token secret"
echo "3. All further configuration changes must be made through Git"
