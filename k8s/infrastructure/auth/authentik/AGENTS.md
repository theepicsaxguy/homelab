# Authentik Identity Provider - Component Guidelines

SCOPE: Authentik identity provider (SSO) and authentication flows
INHERITS FROM: /k8s/AGENTS.md

## COMPONENT CONTEXT

Purpose: Provide centralized authentication and authorization (SSO) for all homelab applications using Authentik as identity provider with GitOps-managed blueprints.

Architecture:
- `k8s/infrastructure/auth/authentik/` - Authentik deployment manifests
- `extra/blueprints/` - Declarative GitOps configuration (users, groups, apps, flows, providers)
- PostgreSQL database: Stores all Authentik data (managed by CNPG)
- Outposts: External auth instances for proxied applications

## INTEGRATION POINTS

### External Services
- **Proxied applications**: Home Assistant, Grafana, Argo CD, media services (use Authentik via OAuth/OIDC)
- **Email provider**: SMTP service for password recovery and notifications
- **User directories**: LDAP/AD integration (optional)

### Internal Services
- **PostgreSQL database**: CNPG-managed database for Authentik data
- **MinIO object storage**: Stores backups and attachments
- **Kubernetes secrets**: Database credentials and API tokens

## COMPONENT PATTERNS

### Blueprint GitOps Pattern
- **Purpose**: Declarative configuration for Authentik
- **Discovery**: YAML files mounted at `/blueprints`, auto-discovered when created/modified
- **Application**: Applied every 60 minutes or on-demand via UI/API
- **Properties**: Idempotent (safe to apply multiple times), atomic (all entries succeed or fail together)

### Blueprint File Structure
- **Version**: Always `1`
- **Metadata**: Name, labels, description
- **Entries**: List of objects to create/update (model, identifiers, attrs, state)
- **Custom YAML tags**: `!KeyOf`, `!Find`, `!Env`, `!File`, `!Context` for dynamic values

### Blueprint Entry States
- `present` (default): Creates if missing, updates `attrs` if exists
- `created`: Creates if missing, never updates (preserves manual changes)
- `must_created`: Creates only if missing, fails if exists (strict validation)
- `absent`: Deletes object (may cascade to related objects)

### Identifiers vs Attrs Pattern
- **`identifiers`**: Used to find existing objects (merged with attrs on creation, used for lookup on update, NOT applied on update)
- **`attrs`**: Used to set attributes on object (merged with identifiers on creation, only these fields modified on update)

### OAuth2 Application Pattern
Create OAuth2 provider in blueprint with:
- Name and client type (confidential/public)
- Redirect URIs with matching mode (strict/regex)
- Client ID and secret from `!Env` tags (ExternalSecrets)
- Token validity settings (access_code, access_token, refresh_token)
- Authorization and invalidation flows (use `!Find` to reference default flows)
- Signing key (use `!Find` to reference self-signed certificate)

### Flow and Stage Pattern
Authentication flows consist of stages (login, MFA, password recovery, consent). Stages reference each other via `!KeyOf` tags. Flows reference stages via `!KeyOf`. Default flows created by Authentik can be referenced with `!Find`.

## DATA MODELS

### Blueprint Models
- `authentik_core.user` - User accounts
- `authentik_core.group` - User groups
- `authentik_flows.flow` - Authentication flows
- `authentik_flows.flowstagebinding` - Flow-to-stage relationships
- `authentik_stages_authenticator.*.stage` - Authenticator stages (TOTP, WebAuthn, etc.)
- `authentik_providers_oauth2.oauth2provider` - OAuth2 providers
- `authentik_providers_saml.samlprovider` - SAML providers
- `authentik_core.application` - Application definitions
- `authentik_blueprints.blueprint` - Blueprint definitions

## WORKFLOWS

### Development
1. Create blueprint file: `k8s/infrastructure/auth/authentik/extra/blueprints/<name>.yaml`
2. Add schema reference: `# yaml-language-server: $schema=https://goauthentik.io/blueprints/schema.json`
3. Define entries with models, identifiers, attrs, and state
4. Use `!KeyOf` to reference entries within same blueprint
5. Use `!Find` to lookup existing Authentik objects
6. Use `!Env` for secrets (from ExternalSecrets)
7. Test blueprint syntax: `kustomize build --enable-helm k8s/infrastructure/auth/authentik`
8. Commit changes (GitOps applies blueprints automatically)

### Testing
- Validate blueprint YAML syntax: `yamllint extra/blueprints/*.yaml`
- Build kustomization: `kustomize build --enable-helm k8s/infrastructure/auth/authentik`
- Check blueprint logs: `kubectl logs -n auth -l app.kubernetes.io/name=authentik --tail=100 | grep -i blueprint`
- Monitor blueprint application in Authentik UI (System → Blueprints)

## CONFIGURATION

### Required
- PostgreSQL database (CNPG cluster) with external secret
- Blueprint files in `extra/blueprints/` directory
- External secrets for SMTP credentials, application client secrets
- Self-signed certificate key for OAuth signing

### Optional
- LDAP/AD integration for user directory
- External identity providers (Google, GitHub) for OAuth
- Custom authentication flows and stages
- Email provider for notifications
- Outposts for proxied applications

## BREAKING CHANGES

### Authentik 2024.8 Property Mapping Model Changes
- **Issue**: Removed `authentik_core.propertymapping` for OAuth2 property mappings
- **Fix**: Update OAuth2 property mapping references to use `authentik_providers_oauth2.scopemapping` with `[scope_name, "..."]`
- **Example**:
  ```yaml
  # OLD (fails in 2024.8+)
  property_mappings:
    - !Find [authentik_core.propertymapping, [name, "authentik default OAuth Mapping: OpenID 'openid'"]]
  
  # NEW (works in 2024.8+)
  property_mappings:
    - !Find [authentik_providers_oauth2.scopemapping, [scope_name, "openid"]]
  ```

## YAML CUSTOM TAGS REFERENCE

### Core Tags
- `!KeyOf` - Reference primary key of entry defined earlier in same blueprint
- `!Find` - Lookup existing object in database by model and fields
- `!FindObject` - Lookup with full data (v2025.8+), returns serialized object
- `!Env` - Read from environment variables, supports default values
- `!File` - Read file contents, supports default values
- `!Context` - Access blueprint context variables (built-in or user-defined)

### String Manipulation
- `!Format` - Python-style string formatting with `%` operator

### Conditional Tags
- `!If` - Evaluates condition and returns one of two values
- `!Condition` - Combines multiple conditions with boolean operators

### Iteration Tags
- `!Enumerate` - Loop over sequences or mappings to generate multiple entries
- `!Index <depth>` - Returns index (sequence) or key (mapping) at specified depth
- `!Value <depth>` - Returns value at specified depth
- `!AtIndex` - Access specific index in sequence or mapping (v2024.12+)

## AUTHENTIK-DOMAIN ANTI-PATTERNS

### Blueprint Management
- Never create blueprints without proper schema reference
- Never use incorrect model references (check breaking changes)
- Never create circular dependencies between blueprints
- Never assume blueprint application is instant - check logs and UI

### Configuration & Security
- Never commit secrets to blueprint files - use `!Env` tags with ExternalSecrets
- Never share ExternalSecret entries across applications
- Never create OAuth providers without proper redirect URIs
- Never skip testing blueprint syntax before committing

## GOTCHAS

- Blueprint auto-generated fields (like OAuth client secrets) are NOT overwritten on update if state is `present`
- Blueprint identifiers use OR logic if multiple fields specified; attrs use AND logic
- Blueprint `!Find` fails if no matching object found - use with `!If` for conditional lookups
- Blueprint `!KeyOf` references must match an `id` field defined earlier in same blueprint
- Multiple blueprints can conflict if they modify same objects

## REFERENCES

For general Kubernetes patterns: k8s/AGENTS.md
For commit format: /AGENTS.md
For CNPG database patterns: k8s/AGENTS.md
For Authentik documentation: https://goauthentik.io/docs/
For blueprint schema: https://goauthentik.io/blueprints/schema.json