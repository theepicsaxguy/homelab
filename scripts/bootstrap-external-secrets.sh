#!/bin/bash
set -euo pipefail

# Bootstrap External Secrets Operator with Bitwarden Integration
# This script follows GitOps principles and only performs validation and checking steps
# Any actual changes to resources should be committed to Git and applied via ArgoCD

# Color setup
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

# Check if running as root - we need kubectl access
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root or with sudo"
   exit 1
fi

# Verify kubectl access
log_info "Verifying kubectl access..."
if ! kubectl get nodes &>/dev/null; then
    log_error "Cannot access Kubernetes cluster. Check your kubeconfig."
    exit 1
fi

# Check for cert-manager installation
log_info "Checking for cert-manager..."
if ! kubectl get namespace cert-manager &>/dev/null; then
    log_error "cert-manager namespace not found. Please deploy cert-manager first."
    log_info "cert-manager should be deployed through ArgoCD as part of infrastructure components."
    exit 1
fi

if ! kubectl get pods -n cert-manager -l app=cert-manager &>/dev/null; then
    log_error "cert-manager pods not found. Check cert-manager deployment."
    exit 1
fi
log_success "cert-manager appears to be installed correctly."

# Check for external-secrets namespace
log_info "Checking for external-secrets namespace..."
if ! kubectl get namespace external-secrets &>/dev/null; then
    log_warn "external-secrets namespace not found. Creating it for ArgoCD to manage..."
    kubectl create namespace external-secrets
    log_info "Namespace created, but remember all further resources should be deployed by ArgoCD."
fi

# Verify issuer resources
log_info "Checking for self-signed issuer in external-secrets namespace..."
if ! kubectl get issuer -n external-secrets selfsigned-issuer &>/dev/null; then
    log_warn "Self-signed issuer not found in external-secrets namespace."
    log_info "Make sure the issuer is defined in Git and will be applied by ArgoCD."
else
    log_success "Self-signed issuer found."
fi

# Check for certificate resource
log_info "Checking for bitwarden-sdk-cert certificate..."
if ! kubectl get certificate -n external-secrets bitwarden-sdk-cert &>/dev/null; then
    log_warn "bitwarden-sdk-cert certificate not found."
    log_info "Make sure the certificate is defined in Git and will be applied by ArgoCD."
else
    log_success "Certificate resource found."
fi

# Check for certificate secret
log_info "Checking for bitwarden-tls-certs secret..."
if ! kubectl get secret -n external-secrets bitwarden-tls-certs &>/dev/null; then
    log_warn "bitwarden-tls-certs secret not found. This should be created by cert-manager."
    log_info "If this persists after ArgoCD reconciliation, check cert-manager logs."
else
    log_success "Certificate secret exists."

    # Check for required keys in secret
    SECRET_KEYS=$(kubectl get secret -n external-secrets bitwarden-tls-certs -o jsonpath='{.data}' | jq 'keys')
    if [[ $SECRET_KEYS != *"tls.crt"* || $SECRET_KEYS != *"tls.key"* || $SECRET_KEYS != *"ca.crt"* ]]; then
        log_warn "bitwarden-tls-certs secret is missing required keys (tls.crt, tls.key, ca.crt)."
        log_info "Check cert-manager logs and certificate definition in Git."
    else
        log_success "Certificate secret has all required keys."
    fi
fi

# Check for Bitwarden SDK server pods
log_info "Checking for bitwarden-sdk-server pods..."
if ! kubectl get pods -n external-secrets -l app.kubernetes.io/name=bitwarden-sdk-server &>/dev/null; then
    log_warn "No bitwarden-sdk-server pods found."
    log_info "Make sure the Bitwarden SDK Server is defined in Git and will be applied by ArgoCD."
else
    SDK_PODS=$(kubectl get pods -n external-secrets -l app.kubernetes.io/name=bitwarden-sdk-server -o jsonpath='{.items[*].status.phase}')
    if [[ $SDK_PODS == *"Running"* ]]; then
        log_success "Bitwarden SDK Server is running."
    else
        log_warn "Bitwarden SDK Server pods exist but are not in Running state."
        log_info "Check pod status with: kubectl describe pods -n external-secrets -l app.kubernetes.io/name=bitwarden-sdk-server"
    fi
fi

# Check for SecretStore resource
log_info "Checking for Bitwarden SecretStore..."
if ! kubectl get secretstore -n external-secrets bitwarden-secretsmanager &>/dev/null; then
    log_warn "bitwarden-secretsmanager SecretStore not found."
    log_info "Make sure the SecretStore is defined in Git and will be applied by ArgoCD."
else
    log_success "SecretStore resource exists."
fi

# Summary
echo ""
echo "=============================="
echo "External Secrets Bootstrap Check"
echo "=============================="
echo ""
log_info "Bootstrap validation complete. Remember these key points:"
echo ""
echo "1. All resources should be managed by ArgoCD"
echo "2. No manual changes should be applied to the cluster"
echo "3. If issues persist, check the documentation at docs/security/external-secrets-bootstrap.md"
echo ""
log_info "For detailed troubleshooting of cert-manager issues:"
echo "kubectl logs -n cert-manager deployment/cert-manager"
echo ""
log_info "For detailed troubleshooting of external-secrets issues:"
echo "kubectl logs -n external-secrets deployment/external-secrets"
echo ""

exit 0
