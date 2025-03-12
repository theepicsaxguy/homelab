#!/bin/bash
set -euo pipefail

# Bootstrap External Secrets Operator with Bitwarden Integration using an internal issuer.
# After bootstrap, all changes should be managed via ArgoCD.

# Color setup for logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

##############################
# Pre-checks
##############################

# Check for required tools: kubectl and jq
if ! command -v kubectl &>/dev/null; then
    log_error "kubectl is required but not installed. Exiting."
    exit 1
fi

if ! command -v jq &>/dev/null; then
    log_error "jq is required but not installed. Please install jq and try again."
    exit 1
fi

# Verify kubectl access
log_info "Verifying kubectl access..."
if ! kubectl get nodes &>/dev/null; then
    log_error "Cannot access Kubernetes cluster. Check your kubeconfig."
    exit 1
fi

# Check that cert-manager is installed by verifying the namespace and pod readiness
log_info "Checking for cert-manager namespace..."
if ! kubectl get namespace cert-manager &>/dev/null; then
    log_error "cert-manager namespace not found. Please deploy cert-manager first via ArgoCD."
    exit 1
fi

log_info "Waiting for cert-manager pods to be ready..."
kubectl wait --for=condition=Ready --timeout=120s pod -l app=cert-manager -n cert-manager || {
    log_error "cert-manager pods did not become ready in time."
    exit 1
}
log_success "cert-manager is installed and ready."

##############################
# Patch cert-manager webhook CA bundles
##############################

log_info "Patching cert-manager webhook configurations with proper CA bundle..."
WEBHOOK_CA=$(kubectl get secret -n cert-manager cert-manager-webhook-ca -o jsonpath='{.data.ca\.crt}' || true)
if [ -z "$WEBHOOK_CA" ]; then
    log_error "Failed to retrieve CA bundle from secret 'cert-manager-webhook-ca'."
    exit 1
fi

# Patch all validating webhook configurations containing 'cert-manager'
VALIDATING_WEBHOOKS=$(kubectl get validatingwebhookconfigurations -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep cert-manager || true)
if [ -n "$VALIDATING_WEBHOOKS" ]; then
    for wh in $VALIDATING_WEBHOOKS; do
        log_info "Patching validating webhook configuration: $wh"
        kubectl patch validatingwebhookconfiguration "$wh" --type='json' \
            -p='[{"op": "replace", "path": "/webhooks/0/clientConfig/caBundle", "value": "'"$WEBHOOK_CA"'"}]' \
            || log_warn "Failed to patch validating webhook configuration $wh."
    done
else
    log_warn "No validating webhook configurations containing 'cert-manager' found."
fi

# Patch all mutating webhook configurations containing 'cert-manager'
MUTATING_WEBHOOKS=$(kubectl get mutatingwebhookconfigurations -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep cert-manager || true)
if [ -n "$MUTATING_WEBHOOKS" ]; then
    for wh in $MUTATING_WEBHOOKS; do
        log_info "Patching mutating webhook configuration: $wh"
        kubectl patch mutatingwebhookconfiguration "$wh" --type='json' \
            -p='[{"op": "replace", "path": "/webhooks/0/clientConfig/caBundle", "value": "'"$WEBHOOK_CA"'"}]' \
            || log_warn "Failed to patch mutating webhook configuration $wh."
    done
else
    log_warn "No mutating webhook configurations containing 'cert-manager' found."
fi

log_success "Cert-manager webhook configurations patched."

##############################
# Setup certificate chain
##############################

# 1. Create bootstrap issuer (ClusterIssuer)
log_info "Creating bootstrap issuer..."
kubectl apply -f k8s/infrastructure/controllers/cert-manager/bootstrap-issuer.yaml

log_info "Waiting for bootstrap issuer to be registered..."
for i in {1..12}; do
    if kubectl get clusterissuer bootstrap-issuer &>/dev/null; then
        log_success "Bootstrap issuer is registered."
        break
    else
        log_info "Waiting for bootstrap issuer (attempt $i)..."
        sleep 5
    fi
    if [ $i -eq 12 ]; then
        log_error "Timeout waiting for bootstrap issuer."
        exit 1
    fi
done

# Debug: print details of the bootstrap issuer
log_info "Bootstrap issuer details:"
kubectl describe clusterissuer bootstrap-issuer

# 2. Create bootstrap CA certificate
log_info "Creating bootstrap CA certificate..."
kubectl apply -f k8s/infrastructure/controllers/cert-manager/bootstrap-ca.yaml

log_info "Waiting for CA secret 'bootstrap-ca' in cert-manager namespace..."
for i in {1..12}; do
    if kubectl get secret -n cert-manager bootstrap-ca &>/dev/null; then
        log_success "CA secret 'bootstrap-ca' is available."
        break
    else
        log_info "Attempt $i: CA secret not found. Showing certificate status:"
        kubectl describe certificate bootstrap-ca -n cert-manager || log_warn "Certificate bootstrap-ca not found yet."
        sleep 5
    fi
    if [ $i -eq 12 ]; then
        log_error "Timeout waiting for CA secret to be created."
        exit 1
    fi
done

# 3. Create CA issuer (ClusterIssuer)
log_info "Creating CA issuer..."
kubectl apply -f k8s/infrastructure/controllers/cert-manager/bootstrap-ca-issuer.yaml

log_info "Waiting for CA issuer to be registered..."
for i in {1..12}; do
    if kubectl get clusterissuer ca-issuer &>/dev/null; then
        log_success "CA issuer is registered."
        break
    else
        log_info "Waiting for CA issuer (attempt $i)..."
        sleep 5
    fi
    if [ $i -eq 12 ]; then
        log_error "Timeout waiting for CA issuer."
        exit 1
    fi
done

# Debug: print details of the CA issuer
log_info "CA issuer details:"
kubectl describe clusterissuer ca-issuer

##############################
# Setup External Secrets
##############################

# 4. Ensure external-secrets namespace exists
log_info "Ensuring 'external-secrets' namespace exists..."
if ! kubectl get namespace external-secrets &>/dev/null; then
    kubectl create namespace external-secrets
    log_success "Namespace 'external-secrets' created."
else
    log_info "Namespace 'external-secrets' already exists."
fi

# 5. Create Bitwarden certificate
log_info "Creating Bitwarden certificate..."
kubectl apply -f k8s/infrastructure/controllers/external-secrets/bitwarden-cert.yaml

log_info "Waiting for Bitwarden certificate secret 'bitwarden-tls-certs' in external-secrets namespace..."
for i in {1..12}; do
    if kubectl get secret -n external-secrets bitwarden-tls-certs &>/dev/null; then
        log_success "Bitwarden certificate secret is available."
        break
    else
        log_info "Waiting for Bitwarden certificate secret (attempt $i)..."
        sleep 5
    fi
    if [ $i -eq 12 ]; then
        log_error "Timeout waiting for Bitwarden certificate secret."
        exit 1
    fi
done

# 6. Verify certificate secret contains required keys
log_info "Verifying Bitwarden certificate secret contents..."
SECRET_KEYS=$(kubectl get secret -n external-secrets bitwarden-tls-certs -o jsonpath='{.data}' | jq -r 'keys | .[]')
REQUIRED_KEYS=("tls.crt" "tls.key" "ca.crt")
for key in "${REQUIRED_KEYS[@]}"; do
    if ! echo "$SECRET_KEYS" | grep -q "$key"; then
        log_error "Certificate secret is missing required key: $key"
        exit 1
    fi
done
log_success "Bitwarden certificate secret contains all required keys."

# 7. Ensure Bitwarden access token secret exists
log_info "Ensuring Bitwarden access token secret exists..."
if ! kubectl get secret -n external-secrets bitwarden-access-token &>/dev/null; then
    if [ -z "${BW_ACCESS_TOKEN:-}" ]; then
        log_error "BW_ACCESS_TOKEN environment variable not set. Please export BW_ACCESS_TOKEN."
        exit 1
    fi
    kubectl create secret generic bitwarden-access-token \
        --namespace external-secrets \
        --from-literal=token="$BW_ACCESS_TOKEN"
    log_success "Bitwarden access token secret created."
else
    log_info "Bitwarden access token secret already exists."
fi

# 8. Apply the Bitwarden SecretStore configuration
log_info "Applying Bitwarden SecretStore configuration..."
kubectl apply -f k8s/infrastructure/controllers/external-secrets/bitwarden-store.yaml

log_success "Bootstrap process complete. ArgoCD will now manage the External Secrets deployment."
log_info "Verify the deployment with: kubectl get pods -n external-secrets"
