#!/bin/bash
set -euo pipefail

################################################################################
# This script installs and verifies cert-manager first, waits for CRD registration,
# then deploys the Cloudflare ClusterIssuer, waits for it, then continues with
# Bitwarden certificate, external-secrets, and related resources.
################################################################################

# Logging Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Required Tools Check
for tool in kubectl jq kustomize; do
    command -v "$tool" &>/dev/null || {
        log_error "$tool is required but not installed."; exit 1;
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
    log_error "Namespace $ns does not exist."; exit 1;
  fi
  phase=$(kubectl get ns "$ns" -o jsonpath='{.status.phase}')
  if [ "$phase" != "Active" ]; then
    log_error "Namespace $ns is in $phase state."; exit 1;
  fi
}

################################################################################
# Phase 1: Install cert-manager
################################################################################
log_info "Installing cert-manager..."

log_info "Cleaning up previous webhook configurations (if exist)..."
kubectl delete validatingwebhookconfiguration cert-manager-webhook --ignore-not-found=true
kubectl delete mutatingwebhookconfiguration cert-manager-webhook --ignore-not-found=true

log_success "Webhook configurations removed."

log_info "Verifying webhook configurations removed..."

if kubectl get validatingwebhookconfiguration cert-manager-webhook >/dev/null 2>&1; then
    log_error "ValidatingWebhook still exists after deletion attempt."; exit 1;
fi

if kubectl get mutatingwebhookconfiguration cert-manager-webhook >/dev/null 2>&1; then
    log_error "MutatingWebhook still exists after deletion attempt."; exit 1;
fi

log_success "Webhook configurations successfully verified as removed."




log_info "Installing cert-manager CRDs explicitly first..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.crds.yaml

# Wait explicitly for CRDs to establish
CRDS=(
  certificaterequests.cert-manager.io
  certificates.cert-manager.io
  challenges.acme.cert-manager.io
  clusterissuers.cert-manager.io
  issuers.cert-manager.io
  orders.acme.cert-manager.io
)
log_info "Waiting for cert-manager CRDs to establish..."
for crd in "${CRDS[@]}"; do
  kubectl wait crd "$crd" --for condition=Established --timeout=180s || {
    log_error "CRD $crd failed to establish"; exit 1;
  }
done
log_success "cert-manager CRDs installed and established."

# Now apply remaining cert-manager components (Helm)
kustomize build infrastructure/controllers/cert-manager --enable-helm | kubectl apply -f -

# Wait explicitly for webhook deployment
kubectl rollout status deployment cert-manager-webhook -n cert-manager --timeout=300s
log_success "cert-manager webhook deployment ready."

# Step 3: Wait for cert-manager-webhook readiness explicitly
log_info "Waiting for cert-manager-webhook to become fully available..."
kubectl rollout status deployment cert-manager-webhook -n cert-manager --timeout=300s || {
  log_error "cert-manager-webhook deployment rollout failed"; exit 1;
}

# Short pause to ensure TLS fully established
sleep 10

# Now ClusterIssuer can safely be applied
kubectl apply -f infrastructure/controllers/cert-manager/cloudflare-issuer.yaml
kubectl wait --for=condition=Ready clusterissuer/cloudflare-issuer --timeout=180s || {
    log_error "Cloudflare issuer failed to become ready"; exit 1;
}

log_success "Cloudflare issuer ready."

# Wait for CRDs to be Established
REQUIRED_CRDS=(
  certificaterequests.cert-manager.io
  certificates.cert-manager.io
  challenges.acme.cert-manager.io
  clusterissuers.cert-manager.io
  issuers.cert-manager.io
  orders.acme.cert-manager.io
)

for crd in "${REQUIRED_CRDS[@]}"; do
  attempt=1
  max_attempts=10
  while [ $attempt -le $max_attempts ]; do
    phase=$(kubectl get crd "$crd" -o jsonpath='{.status.conditions[?(@.type=="Established")].status}' 2>/dev/null || echo "NotFound")
    if [ "$phase" = "True" ]; then
      log_success "CRD $crd is Established."
      break
    else
      log_info "Waiting for CRD $crd to become Established (attempt $attempt/$max_attempts)..."
      sleep 3
      attempt=$((attempt + 1))
    fi
    if [ $attempt -gt $max_attempts ]; then
      log_error "CRD $crd failed to become Established in time."; exit 1
    fi
  done
done
log_info "All cert-manager CRDs are Established."

CERT_NS="cert-manager"
check_namespace "$CERT_NS"

# Wait for cert-manager-webhook deployment to be available
log_info "Waiting for cert-manager-webhook deployment (timeout 300s)..."
kubectl wait deployment cert-manager-webhook -n "$CERT_NS" --for=condition=Available --timeout=300s || {
    log_error "cert-manager-webhook did not become available in time."; exit 1;
}

log_info "Performing rollout status on cert-manager-webhook..."
kubectl rollout status deployment cert-manager-webhook -n "$CERT_NS" --timeout=300s || {
  log_error "cert-manager-webhook failed to become available in time."; exit 1;
}

# Optional short sleep to ensure webhook TLS fully up
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
  log_error "Cloudflare issuer did not become Ready in time."; exit 1;
fi
log_success "Cloudflare issuer is Ready."

################################################################################
# Optional: Deploy a test Certificate to confirm issuance.
# e.g., test-certificate.yaml referencing the cloudflare-issuer.
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
kubectl apply -f infrastructure/controllers/external-secrets/bitwarden-cert.yaml

log_info "Waiting for bitwarden-tls-certs secret in namespace external-secrets..."
kubectl wait secret bitwarden-tls-certs -n external-secrets --for=jsonpath='{.data.tls\.crt}' --timeout=180s || {
    log_error "bitwarden-tls-certs secret did not appear in time."; exit 1;
}
log_success "Bitwarden certificate secret ready."

################################################################################
# Phase 4: Install & Verify external-secrets
################################################################################
EXT_NS="external-secrets"

log_info "Installing external-secrets..."
if ! kustomize build infrastructure/controllers/external-secrets --enable-helm > external-secrets.yaml; then
    log_error "kustomize build failed for external-secrets."; exit 1
fi
kubectl apply -f external-secrets.yaml

check_namespace "$EXT_NS"

log_info "Waiting for external-secrets-webhook deployment (timeout 300s)..."
kubectl wait deployment external-secrets-webhook -n "$EXT_NS" --for=condition=Available --timeout=300s || {
    log_error "external-secrets-webhook did not become available in time."; exit 1;
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
