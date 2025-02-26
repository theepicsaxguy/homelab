#!/bin/bash
set -euo pipefail

echo "Bootstrapping Kubechecks outside of ArgoCD..."

# Create namespace
kubectl create namespace kubechecks --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repository
helm repo add kubechecks https://zapier.github.io/kubechecks/
helm repo update

# Check if GitHub token is provided
if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN environment variable is not set."
    echo "Please set the GITHUB_TOKEN environment variable with a valid GitHub token."
    echo "Example: export GITHUB_TOKEN=your_github_token"
    exit 1
fi

# Create a temporary GitHub token secret for bootstrap (will be managed by sm-operator later)
echo "Creating temporary GitHub token secret for bootstrap..."
kubectl create secret generic kubechecks-vcs-token \
  --namespace kubechecks \
  --from-literal=KUBECHECKS_VCS_TOKEN="$GITHUB_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

# Install Kubechecks with configuration from documentation
echo "Installing Kubechecks via Helm..."
helm upgrade --install kubechecks kubechecks/kubechecks \
  --namespace kubechecks \
  --set config.argocd.apiServerAddr=argocd-server.argocd.svc \
  --set config.argocd.namespace=argocd \
  --set config.argocd.repositoryEndpoint=argocd-repo-server.argocd.svc:8081 \
  --set config.argocd.repositoryInsecure=true \
  --set config.vcs.type=github \
  --set config.kubernetes.type=local \
  --set config.monitorAllApplications=true \
  --set config.logLevel=info

echo "Kubechecks bootstrap complete."
echo "The temporary GitHub token secret will be replaced by the Bitwarden Secrets Manager."
echo "Ensure the BitwardenSecret resource is correctly configured with github/kubechecks-github-token."
