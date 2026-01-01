# Authentik Identity Provider - Component Guidelines

SCOPE: Authentik identity provider (SSO) and authentication flows
INHERITS FROM: /k8s/AGENTS.md

## COMPONENT CONTEXT

Purpose:
Provide centralized authentication and authorization (SSO) for all homelab applications using Authentik as identity provider with GitOps-managed blueprints.

Boundaries:
- Handles: Authentik deployment, blueprint configuration, SSO/OAuth/SAML providers, user management, authentication flows
- Does NOT handle: Application-specific auth implementations (apps use Authentik via OAuth/OIDC), general Kubernetes infrastructure
- Delegates to: k8s/AGENTS.md for general Kubernetes patterns

Architecture:
- `k8s/infrastructure/auth/authentik/` - Authentik deployment manifests
- `extra/blueprints/` - Declarative GitOps configuration (users, groups, apps, flows, providers)
- PostgreSQL database: Stores all Authentik data (managed by CNPG)
- Outposts: External auth instances for proxied applications

File Organization:
- `k8s/infrastructure/auth/authentik/` - Root directory with main manifests
  - `kustomization.yaml` - Kustomize configuration
  - `values.yaml` - Helm chart values
  - `database.yaml` - CNPG PostgreSQL cluster
  - `httproute.yaml` - Gateway API routing
  - `extra/` - Additional configuration
    - `blueprints/` - Blueprint YAML files (GitOps configuration)

## INTEGRATION POINTS

External Services:
- Proxied applications: Home Assistant, Grafana, Argo CD, media services, etc. (use Authentik via OAuth/OIDC)
- Email provider: SMTP service for password recovery and notifications
- User directories: LDAP/AD integration (optional)

Internal Services:
- PostgreSQL database: CNPG-managed database for Authentik data
- MinIO object storage: Stores backups and attachments
- Kubernetes secrets: Database credentials and API tokens

APIs Consumed:
- PostgreSQL: Persistent data storage
- SMTP: Email notifications
- OAuth/OIDC providers: External identity providers (Google, GitHub, etc.)

APIs Provided:
- OAuth2 authorization endpoint
- SAML assertion consumer service
- OIDC discovery endpoint
- Application management API (via blueprints)
- User management API (via blueprints)

## COMPONENT-SPECIFIC PATTERNS

### Blueprint GitOps Pattern
Authentik uses blueprints for declarative configuration. Blueprints are YAML files mounted into container at `/blueprints`. Auto-discovered when created or modified. Applied every 60 minutes or on-demand via UI/API. Idempotent (safe to apply multiple times). Atomic (all entries succeed or fail together in database transaction).

### Blueprint File Structure
Every blueprint follows this schema:
- Version: Always `1`
- Metadata: Name, labels, description
- Entries: List of objects to create/update (model, identifiers, attrs, state)
- Custom YAML tags: `!KeyOf`, `!Find`, `!Env`, `!File`, `!Context` for dynamic values

### Blueprint Entry States
State field controls how entries are managed:
- `present` (default): Creates if missing, updates `attrs` if exists
- `created`: Creates if missing, never updates (preserves manual changes)
- `must_created`: Creates only if missing, fails if exists (strict validation)
- `absent`: Deletes object (may cascade to related objects)

### Identifiers vs Attrs Pattern
Understanding difference is critical:
- `identifiers`: Used to find existing objects (merged with attrs on creation, used for lookup on update, NOT applied on update)
- `attrs`: Used to set attributes on object (merged with identifiers on creation, only these fields modified on update)

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

### User and Group Pattern
Users and groups defined in blueprints with `identifiers` (username, email, name). Groups organize users for permissions. Applications reference groups for access control. Users can belong to multiple groups.

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

Development:
- Create blueprint file: `k8s/infrastructure/auth/authentik/extra/blueprints/<name>.yaml`
- Add schema reference at top: `# yaml-language-server: $schema=https://goauthentik.io/blueprints/schema.json`
- Define entries with models, identifiers, attrs, and state
- Use `!KeyOf` to reference entries within same blueprint
- Use `!Find` to lookup existing Authentik objects (flows, stages, certificates)
- Use `!Env` for secrets (from ExternalSecrets)
- Test blueprint syntax: `kustomize build --enable-helm k8s/infrastructure/auth/authentik`
- Commit changes: GitOps applies blueprints automatically

Testing:
- Validate blueprint YAML syntax: `yamllint extra/blueprints/*.yaml` (if available)
- Build kustomization: `kustomize build --enable-helm k8s/infrastructure/auth/authentik`
- Check blueprint logs: `kubectl logs -n auth -l app.kubernetes.io/name=authentik --tail=100 | grep -i blueprint`
- Monitor blueprint application in Authentik UI (System → Blueprints)
- Verify objects created: Check Authentik UI or API

Deployment:
- Blueprints auto-discover when files change in Git
- Argo CD syncs blueprint files to cluster
- Authentik applies blueprints every 60 minutes or on-demand
- Monitor logs for blueprint application errors
- Validate objects appear in Authentik UI

## CONFIGURATION

Required:
- PostgreSQL database (CNPG cluster) with external secret
- Blueprint files in `extra/blueprints/` directory
- External secrets for SMTP credentials, application client secrets
- Self-signed certificate key for OAuth signing

Optional:
- LDAP/AD integration for user directory
- External identity providers (Google, GitHub) for OAuth
- Custom authentication flows and stages
- Email provider for notifications
- Outposts for proxied applications

## BREAKING CHANGES

### Authentik 2024.8 Property Mapping Model Changes

**Issue**: Authentik 2024.8 removed `authentik_core.propertymapping` as a valid model for OAuth2 property mappings. Using this model in blueprints causes `!Find` to return `None`, resulting in "Invalid pk 'None' - object does not exist" errors.

**Impact**: OAuth2 provider blueprints that reference default scope mappings (openid, profile, email, offline_access) using `!Find` tags will fail blueprint validation.

**Fix**: Update OAuth2 property mapping references to use the correct model and field:
- **Old model**: `authentik_core.propertymapping` with `[name, "..."]`
- **New model**: `authentik_providers_oauth2.scopemapping` with `[scope_name, "..."]`

**Example fix**:
```yaml
# OLD (fails in 2024.8+)
property_mappings:
  - !Find [
      authentik_core.propertymapping,  # ❌ Incorrect model
      [name, "authentik default OAuth Mapping: OpenID 'openid'"],
    ]

# NEW (works in 2024.8+)
property_mappings:
  - !Find [authentik_providers_oauth2.scopemapping, [scope_name, "openid"]]
  - !Find [authentik_providers_oauth2.scopemapping, [scope_name, "profile"]]
  - !Find [authentik_providers_oauth2.scopemapping, [scope_name, "email"]]
  - !Find [authentik_providers_oauth2.scopemapping, [scope_name, "offline_access"]]
```

**Reference**: [Authentik 2024.8 Release Notes](https://docs.goauthentik.io/releases/2024.8/) - See "Removed enum values" section under API Changes

Environment Variables:
- Database credentials (from CNPG auto-generated secret)
- SMTP settings (from ExternalSecrets)
- Secret key for encryption
- Redis configuration (if using Redis)
- Outpost tokens (if using outposts)

## YAML CUSTOM TAGS REFERENCE

### Core Tags
- `!KeyOf` - Reference primary key of entry defined earlier in same blueprint
- `!Find` - Lookup existing object in database by model and fields
- `!FindObject` - Lookup with full data (v2025.8+), returns serialized object instead of just primary key
- `!Env` - Read from environment variables, supports default values
- `!File` - Read file contents, supports default values
- `!Context` - Access blueprint context variables (built-in or user-defined)

### String Manipulation
- `!Format` - Python-style string formatting with `%` operator

### Conditional Tags
- `!If` - Evaluates condition and returns one of two values (short form returns boolean, full form with true/false values)
- `!Condition` - Combines multiple conditions with boolean operators (AND, OR, NAND, NOR, XOR, XNOR, NOT)

### Iteration Tags
- `!Enumerate` - Loop over sequences or mappings to generate multiple entries
- `!Index <depth>` - Returns index (sequence) or key (mapping) at specified depth
- `!Value <depth>` - Returns value at specified depth
- `!AtIndex` - Access specific index in sequence or mapping (v2024.12+)

## KNOWN ISSUES

Blueprint discovery order is not guaranteed. Dependencies between blueprints should use meta models or manual ordering.

External secrets with `!Env` tags require envFrom in values.yaml to inject into container.

Blueprint errors can prevent application of entire blueprint file (atomic transaction). Test individual entries if errors occur.

## GOTCHAS

Blueprint auto-generated fields (like OAuth client secrets) are NOT overwritten on update if state is `present`. Use `created` state for objects with auto-generated fields that shouldn't change.

Blueprint identifiers use OR logic if multiple fields specified (matches any field). Attrs use AND logic (all fields must match).

Blueprint `!Find` fails if no matching object found. Use with `!If` for conditional lookups.

Blueprint `!KeyOf` references must match an `id` field defined earlier in same blueprint. Verify ID names are correct.

Blueprint application is not instant. Check logs and UI to verify completion after file changes.

Multiple blueprints can conflict if they modify same objects. Use unique identifiers and coordinate between blueprints.

## REFERENCES

For general Kubernetes patterns, see k8s/AGENTS.md

For commit message format, see root AGENTS.md

For CNPG database patterns, see k8s/AGENTS.md

For Authentik documentation, see https://goauthentik.io/docs/

For blueprint schema, see https://goauthentik.io/blueprints/schema.json

For OpenWiki/Authentik guidance, use MCP docs tools with Context7/DeepWiki
