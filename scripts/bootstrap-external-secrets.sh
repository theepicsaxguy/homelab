#!/bin/bash
set -euo pipefail

################################################################################
# This script installs and verifies cert-manager first, waits for CRD registration,
# then deploys the Cloudflare ClusterIssuer, waits for it, then continues with
# Bitwarden certificate, external-secrets, and related resources.
################################################################################

# Logging Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Required Tools Check
for tool in kubectl jq kustomize; do
    command -v "$tool" &>/dev/null || {
        log_error "$tool is required but not installed."
        exit 1
    }
done

# Verify Cluster Connectivity
if ! kubectl get nodes &>/dev/null; then
    log_error "Cannot access Kubernetes cluster. Check your kubeconfig."
    exit 1
fi

log_success "Tools and cluster connectivity verified."

################################################################################
# Prompt for Cloudflare / Bitwarden Tokens
################################################################################
if [ -z "${CF_API_TOKEN:-}" ]; then
    read -s -p "Enter Cloudflare API Token: " CF_API_TOKEN
    echo
fi
if [ -z "${BW_ACCESS_TOKEN:-}" ]; then
    read -s -p "Enter Bitwarden Access Token: " BW_ACCESS_TOKEN
    echo
fi

################################################################################
# Helper Function: Check Namespace
################################################################################
check_namespace() {
  ns="$1"
  if ! kubectl get ns "$ns" &>/dev/null; then
    log_error "Namespace $ns does not exist."
    exit 1
  fi
  phase=$(kubectl get ns "$ns" -o jsonpath='{.status.phase}')
  if [ "$phase" != "Active" ]; then
    log_error "Namespace $ns is in $phase state."
    exit 1
  fi
}

################################################################################
# Phase 1: Install cert-manager
################################################################################
log_info "Installing cert-manager..."

log_info "Cleaning up old cert-manager webhook secrets and configurations..."
# Delete old CA and TLS secrets
kubectl delete secret cert-manager-webhook-ca cert-manager-webhook-tls -n cert-manager --ignore-not-found=true
# Delete old webhook configurations
kubectl delete validatingwebhookconfiguration cert-manager-webhook --ignore-not-found=true
kubectl delete mutatingwebhookconfiguration cert-manager-webhook --ignore-not-found=true

# Restart cainjector to regenerate fresh CA secrets
kubectl rollout restart deployment cert-manager-cainjector -n cert-manager
kubectl rollout status deployment cert-manager-cainjector -n cert-manager --timeout=180s

# Restart the webhook to pick up the newly-generated secrets
kubectl rollout restart deployment cert-manager-webhook -n cert-manager
kubectl rollout status deployment cert-manager-webhook -n cert-manager --timeout=180s

log_success "Old secrets and webhook configurations removed; cainjector and webhook restarted."

# Verify the old webhook configurations are gone (they will be re-created by the kustomize build)
if kubectl get validatingwebhookconfiguration cert-manager-webhook >/dev/null 2>&1; then
    log_error "ValidatingWebhook still exists after deletion attempt."
    exit 1
fi
if kubectl get mutatingwebhookconfiguration cert-manager-webhook >/dev/null 2>&1; then
    log_error "MutatingWebhook still exists after deletion attempt."
    exit 1
fi
log_success "Verified old webhook configurations are removed."

log_info "Installing cert-manager CRDs explicitly..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.crds.yaml

# Wait for CRDs to establish
CRDS=(
  certificaterequests.cert-manager.io
  certificates.cert-manager.io
  challenges.acme.cert-manager.io
  clusterissuers.cert-manager.io
  issuers.cert-manager.io
  orders.acme.cert-manager.io
)

# Re-apply cert-manager components via kustomize/helm
kustomize build infrastructure/controllers/cert-manager --enable-helm | kubectl apply -f -

# Wait for the webhook deployment to become available
kubectl rollout status deployment cert-manager-webhook -n cert-manager --timeout=300s || {
  log_error "cert-manager-webhook deployment rollout failed"
  exit 1
}
log_success "cert-manager webhook deployment ready."

log_info "Waiting for cert-manager-webhook to become fully available..."
kubectl rollout status deployment cert-manager-webhook -n cert-manager --timeout=300s || {
  log_error "cert-manager-webhook deployment rollout failed"
  exit 1
}

# Short pause to ensure TLS is fully established
sleep 10

# Apply the Cloudflare ClusterIssuer
kubectl apply -f infrastructure/controllers/cert-manager/cloudflare-issuer.yaml
kubectl wait --for=condition=Ready clusterissuer/cloudflare-issuer --timeout=180s || {
    log_error "Cloudflare issuer failed to become ready"
    exit 1
}

# Continue by re-applying cert-manager components (if needed)
kustomize build infrastructure/controllers/cert-manager --enable-helm | kubectl apply -f -

log_success "Cloudflare issuer ready."

# Wait for CRDs to be fully established (redundant but included for safety)
REQUIRED_CRDS=(
  certificaterequests.cert-manager.io
  certificates.cert-manager.io
  challenges.acme.cert-manager.io
  clusterissuers.cert-manager.io
  issuers.cert-manager.io
  orders.acme.cert-manager.io
)


CERT_NS="cert-manager"
check_namespace "$CERT_NS"

log_info "Waiting for cert-manager-webhook deployment (timeout 300s)..."
kubectl wait deployment cert-manager-webhook -n "$CERT_NS" --for=condition=Available --timeout=300s || {
    log_error "cert-manager-webhook did not become available in time."
    exit 1
}
log_info "Performing rollout status on cert-manager-webhook..."
kubectl rollout status deployment cert-manager-webhook -n "$CERT_NS" --timeout=300s || {
  log_error "cert-manager-webhook failed to become available in time."
  exit 1
}

# Optional short sleep to ensure webhook TLS is fully up
sleep 5
log_success "cert-manager is installed, CRDs established, and webhook ready."

################################################################################
# Phase 2: Create Cloudflare Secret + Cloudflare Issuer
################################################################################
log_info "Creating Cloudflare API token secret in namespace $CERT_NS..."
kubectl -n "$CERT_NS" create secret generic cloudflare-api-token \
    --from-literal=cloudflare_api_token="$CF_API_TOKEN" \
    --dry-run=client -o yaml | kubectl apply -f -
log_success "Cloudflare token secret created (or unchanged)."

log_info "Applying cloudflare-issuer.yaml..."
kubectl apply -f infrastructure/controllers/cert-manager/cloudflare-issuer.yaml

log_info "Waiting for cloudflare-issuer to become Ready (timeout 180s)..."
if ! kubectl wait --for=condition=Ready clusterissuer/cloudflare-issuer --timeout=180s; then
  log_error "Cloudflare issuer did not become Ready in time."
  exit 1
fi
log_success "Cloudflare issuer is Ready."

################################################################################
# Optional: Deploy a test Certificate to confirm issuance.
################################################################################
if [ -f "test-certificate.yaml" ]; then
  log_info "Applying test-certificate.yaml for a test domain..."
  kubectl apply -f test-certificate.yaml
  log_info "Check: kubectl describe certificate test-certificate -n $CERT_NS"
fi

################################################################################
# Phase 3: Deploy Bitwarden certificate & verify
################################################################################
log_info "Deploying Bitwarden certificate..."
kubectl apply -f infrastructure/controllers/external-secrets/namespace.yaml
kubectl apply -f infrastructure/controllers/external-secrets/bitwarden-cert.yaml

log_info "Waiting for bitwarden-tls-certs secret in namespace external-secrets..."
kubectl wait secret bitwarden-tls-certs -n external-secrets --for=jsonpath='{.data.tls\.crt}' --timeout=180s || {
    log_error "bitwarden-tls-certs secret did not appear in time."
    exit 1
}
log_success "Bitwarden certificate secret ready."

################################################################################
# Phase 4: Install & Verify external-secrets
################################################################################
EXT_NS="external-secrets"

log_info "Installing external-secrets..."
if ! kustomize build infrastructure/controllers/external-secrets --enable-helm > external-secrets.yaml; then
    log_error "kustomize build failed for external-secrets."
    exit 1
fi
kubectl apply -f external-secrets.yaml

check_namespace "$EXT_NS"

log_info "Waiting for external-secrets-webhook deployment (timeout 300s)..."
kubectl wait deployment external-secrets-webhook -n "$EXT_NS" --for=condition=Available --timeout=300s || {
    log_error "external-secrets-webhook did not become available in time."
    exit 1
}
log_success "external-secrets is installed."

################################################################################
# Phase 5: Create Bitwarden Access Token + SecretStore
################################################################################
log_info "Creating Bitwarden access token secret in $EXT_NS..."
kubectl -n "$EXT_NS" create secret generic bitwarden-access-token \
    --from-literal=token="$BW_ACCESS_TOKEN" \
    --dry-run=client -o yaml | kubectl apply -f -
log_success "Bitwarden token secret created (or unchanged)."

log_info "Deploying Bitwarden SecretStore..."
kubectl apply -f infrastructure/controllers/external-secrets/bitwarden-store.yaml
log_success "Bitwarden SecretStore deployed."

################################################################################
# Final Verification
################################################################################
log_info "Listing pods in $CERT_NS and $EXT_NS..."
kubectl get pods -n "$CERT_NS"
kubectl get pods -n "$EXT_NS"

log_success "All steps completed. Bootstrap finished successfully!"
