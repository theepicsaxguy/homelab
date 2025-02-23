# Bitwarden Secrets Manager Bootstrap

## Overview

The Bitwarden Secrets Manager requires a one-time bootstrap process to establish the initial authentication token. This process is required before any BitwardenSecrets can be synced.

## Prerequisites

- Bitwarden organization ID: 4a014e57-f197-4852-9831-b287013e47b6
- A Bitwarden Secrets Manager access token from a machine account with appropriate permissions

## Bootstrap Process

1. Create an access token in the Bitwarden Secrets Manager portal for the machine account

2. Run the bootstrap script:
   ```bash
   export BW_ACCESS_TOKEN="your-machine-account-token"
   ./scripts/bootstrap-bitwarden.sh
   ```

3. Verify operator status:
   ```bash
   kubectl -n sm-operator-system logs -l app.kubernetes.io/name=sm-operator
   ```

## Post-Bootstrap

After successful bootstrap, all subsequent secret management must be done through BitwardenSecrets in Git, following GitOps principles.

## Security Considerations

- The access token should be stored securely and only used during the bootstrap process
- After bootstrap, the token value should be removed from the environment
- Consider using ephemeral environments for the bootstrap process to avoid token exposure
- The token should have minimal required permissions in the Bitwarden organization