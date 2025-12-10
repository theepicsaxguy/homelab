# AGENTS.md - Authentik Identity Provider

## 1. Purpose & Scope

This AGENTS.md provides guidance for AI agents working with authentik, the open-source identity provider (IdP) used in this homelab for single sign-on (SSO) and authentication across all applications.

**What this covers:**
- Understanding authentik's role in the homelab infrastructure
- Creating and maintaining authentik blueprints (GitOps-style configuration)
- Writing efficient and correct blueprint YAML files
- Managing applications, users, groups, flows, and providers
- Blueprint YAML tags and their proper usage
- Testing and validation of blueprints

**Key Concept:** Authentik uses **Blueprints** - declarative YAML files that define the entire authentication infrastructure as code. Blueprints work in a GitOps manner, automatically applying configuration changes when files are modified.

## 2. Architecture Overview

### 2.1 Authentik's Role in the Homelab

Authentik serves as the central authentication and authorization system for the homelab:

- **Identity Provider (IdP)**: Provides SSO via OAuth2, SAML, LDAP, and OIDC protocols
- **User Management**: Centralized user accounts, groups, and permissions
- **Application Gateway**: Controls access to all applications (Grafana, ArgoCD, Home Assistant, media services, etc.)
- **Flow-Based Authentication**: Customizable authentication flows (login, MFA, password recovery, consent)
- **Policy Engine**: Fine-grained access control policies per application

### 2.2 Deployment Structure

```
k8s/infrastructure/auth/authentik/
├── AGENTS.md                  # This file
├── kustomization.yaml         # Kustomize configuration
├── values.yaml                # Helm chart values
├── database.yaml              # PostgreSQL database for authentik
├── database-scheduled-backup.yaml
├── httproute.yaml             # Gateway API routing
├── outpost-externalsecret.yaml
├── minio-externalsecret.yaml
├── referencegrant.yaml
├── podmonitor.yaml
└── extra/
    ├── kustomization.yml
    ├── secrets.yml
    └── blueprints/            # Blueprint configuration files
        ├── apps-*.yaml        # Application providers (OAuth2/SAML)
        ├── groups.yaml        # User groups
        ├── users.yaml         # User accounts
        ├── flows-*.yaml       # Custom authentication flows
        ├── brands.yaml        # Branding configuration
        ├── notifications.yaml # Notification settings
        ├── oauth-scopes.yaml  # Custom OAuth scopes
        └── outposts.yaml      # Outpost configurations
```

### 2.3 How Blueprints Work

Blueprints are mounted into the authentik container at `/blueprints` and are:
- **Automatically discovered** when created or modified (via file watch)
- **Applied every 60 minutes** or on-demand via the authentik UI/API
- **Idempotent**: Safe to apply multiple times (creates or updates objects)
- **Atomic**: All entries in a blueprint succeed or fail together (database transaction)
- **Version controlled**: Part of the GitOps workflow

## 3. Quick Start Commands

### 3.1 Validate Blueprint Syntax

```bash
# Validate blueprint YAML schema (requires network access)
# Add this to the top of every blueprint file:
# yaml-language-server: $schema=https://goauthentik.io/blueprints/schema.json

# Build kustomize to check for syntax errors
cd /home/runner/work/homelab/homelab/k8s/infrastructure/auth/authentik
kustomize build --enable-helm .

# Check YAML syntax with yamllint (if available)
yamllint extra/blueprints/*.yaml
```

### 3.2 View Applied Blueprints

```bash
# List all blueprints in the authentik namespace
kubectl get blueprints -n auth

# Describe a specific blueprint instance
kubectl describe blueprint <name> -n auth

# Check authentik pod logs for blueprint application
kubectl logs -n auth -l app.kubernetes.io/name=authentik --tail=100 | grep -i blueprint
```

### 3.3 Test Blueprint Changes

```bash
# After modifying a blueprint, check if it's valid
kustomize build --enable-helm k8s/infrastructure/auth/authentik

# Apply changes via GitOps (commit and push)
git add k8s/infrastructure/auth/authentik/extra/blueprints/<file>.yaml
git commit -m "feat(authentik): update <blueprint-name> blueprint"
git push

# Monitor blueprint application in authentik
kubectl logs -n auth -l app.kubernetes.io/name=authentik -f | grep blueprint
```

## 4. Blueprint File Structure

### 4.1 Schema and Metadata

Every blueprint must follow this structure:

```yaml
# yaml-language-server: $schema=https://goauthentik.io/blueprints/schema.json
# yamllint disable-file
# prettier-ignore-start
# eslint-disable
---
version: 1                          # Required: always 1
metadata:
  name: Example Blueprint           # Required: human-readable name
  labels:                           # Optional: special labels control behavior
    blueprints.goauthentik.io/instantiate: "true"  # Auto-instantiate (default: true)
    blueprints.goauthentik.io/description: "Brief description"
    blueprints.goauthentik.io/system: "true"  # System blueprint (don't modify)
context:                            # Optional: default context variables
  foo: bar
entries:                            # Required: list of objects to create/update
  - model: authentik_flows.flow    # Required: model in app.model notation
    state: present                  # Optional: present|created|must_created|absent
    id: flow-id                     # Optional: ID for !KeyOf references
    identifiers:                    # Required: unique identifier(s)
      slug: my-flow
    attrs:                          # Optional: attributes to set
      name: My Flow
      designation: authentication
    conditions:                     # Optional: conditions for evaluation
      - !Context some_var
    permissions:                    # Optional: object-level permissions (v2024.8+)
      - permission: inspect_flow
        user: !Find [authentik_core.user, [username, akadmin]]
```

### 4.2 Entry States

The `state` field controls how entries are managed:

| State | Behavior |
|-------|----------|
| `present` (default) | Creates if missing, updates `attrs` if exists (overwrites specified fields) |
| `created` | Creates if missing, never updates (preserves manual changes) |
| `must_created` | Creates only if missing, fails if exists (strict validation) |
| `absent` | Deletes the object (may cascade to related objects) |

**Best Practice:** Use `present` for most cases. Use `created` for objects with auto-generated fields (like OAuth client secrets) that shouldn't be overwritten.

### 4.3 Identifiers vs Attrs

Understanding the difference is critical:

- **`identifiers`**: Used to **find** existing objects (OR logic if multiple)
  - On creation: merged with `attrs` to create the object
  - On lookup: used to match existing objects
  - On update: NOT applied (only `attrs` are updated)
  
- **`attrs`**: Used to **set** attributes on the object
  - On creation: merged with `identifiers`
  - On update: only these fields are modified (others unchanged)

**Example:**
```yaml
- model: authentik_providers_oauth2.oauth2provider
  identifiers:
    name: my-app  # Used to find the provider
  attrs:
    # Only these fields are updated on existing providers
    redirect_uris:
      - url: https://app.example.com/callback
    client_id: !Env MY_APP_CLIENT_ID
    # Auto-generated fields like client_secret are NOT overwritten
```

## 5. YAML Custom Tags Reference

Authentik blueprints support custom YAML tags for dynamic values and references.

### 5.1 Core Tags

#### `!KeyOf` - Reference Another Entry
References the primary key of an entry defined earlier in the same blueprint.

```yaml
- id: my-flow
  model: authentik_flows.flow
  identifiers:
    slug: my-flow
  attrs:
    name: My Flow

- model: authentik_flows.flowstagebinding
  identifiers:
    target: !KeyOf my-flow  # References the flow's primary key
    stage: !KeyOf my-stage
  attrs:
    order: 10
```

**Error if:** No matching `id` found in the blueprint.

#### `!Find` - Lookup Existing Object
Searches for an existing object in the database and returns its primary key.

```yaml
# Find by single field
flow: !Find [authentik_flows.flow, [slug, default-authentication-flow]]

# Find by multiple fields (key-value pairs)
user: !Find [authentik_core.user, [username, admin]]

# Use with context variables
flow: !Find [authentik_flows.flow, [!Context property_name, !Context property_value]]
```

**Format:** `!Find [model_name, [field1, value1], [field2, value2], ...]`
**Error if:** No matching object found.

#### `!FindObject` - Lookup with Full Data (v2025.8+)
Like `!Find`, but returns serialized object data instead of just the primary key.

```yaml
flow_designation: !AtIndex [
  !FindObject [authentik_flows.flow, [slug, default-password-change]],
  designation
]
```

#### `!Env` - Environment Variable
Reads from environment variables. Supports default values.

```yaml
# Simple usage
password: !Env MY_PASSWORD

# With default value
password: !Env [MY_PASSWORD, default-value]
```

**Best Practice:** Use for secrets and configuration that varies per environment. Set via `envFrom` in `values.yaml`.

#### `!File` - Read File Contents
Reads contents from a file path. Supports default values.

```yaml
# Simple usage
certificate: !File /path/to/cert.pem

# With default value
certificate: !File [/path/to/cert.pem, default-content]
```

#### `!Context` - Access Context Variables
Accesses blueprint context variables (built-in or user-defined).

```yaml
# Built-in contexts
enabled: !Context goauthentik.io/enterprise/licensed  # Boolean
models: !Context goauthentik.io/rbac/models          # Dictionary

# With default value
value: !Context [foo, default-value]
```

### 5.2 String Manipulation Tags

#### `!Format` - String Formatting
Python-style string formatting with `%` operator.

```yaml
name: !Format [my-policy-%s, !Context instance_name]
# Result: my-policy-production

model: !Format [
  "authentik_stages_authenticator_%s.authenticator%sstage",
  !Value 0,
  !Value 0
]
# Result: authentik_stages_authenticator_totp.authenticatortotpstage
```

### 5.3 Conditional Tags

#### `!If` - Conditional Values
Evaluates a condition and returns one of two values.

```yaml
# Short form: return condition value as boolean
required: !If [true]

# Full form: condition, true_value, false_value
required: !If [!Context feature_enabled, true, false]

# Complex example with nested structures
attributes: !If [
  !Context enable_feature,
  {
    # When true
    feature: enabled,
    nested: !Format ["value-%s", !Context name]
  },
  [
    # When false
    list, of, values
  ]
]
```

#### `!Condition` - Boolean Logic
Combines multiple conditions with boolean operators.

```yaml
conditions:
  - !Condition [OR, !Context var1, !Context var2]
  - !Condition [AND, true, !Env FEATURE_ENABLED]
  - !Condition [NOT, !Context disabled]

# Valid modes: AND, NAND, OR, NOR, XOR, XNOR
# Complex nested conditions
required: !Condition [
  AND,
  !Context instance_name,
  !Find [authentik_flows.flow, [slug, my-flow]],
  "string value",
  123
]
```

### 5.4 Iteration Tags

#### `!Enumerate`, `!Index`, `!Value` - Loop Over Collections
Iterate over sequences or mappings to generate multiple entries.

```yaml
# Generate a sequence from a mapping
configuration_stages: !Enumerate [
  !Context map_of_stage_names,  # Input: {totp: "TOTP", webauthn: "WebAuthn"}
  SEQ,  # Output type: SEQ or MAP
  !Find [
    !Format ["authentik_stages_authenticator_%s.stage", !Index 0],
    [name, !Value 0]
  ]
]
# Result:
# configuration_stages:
#   - <pk of totp stage>
#   - <pk of webauthn stage>

# Generate a mapping from a sequence
example: !Enumerate [
  !Context list_of_names,  # Input: ["alice", "bob"]
  MAP,  # Output a mapping
  [
    !Index 0,  # Key: index (0, 1, ...)
    !Value 0   # Value: item from sequence
  ]
]
# Result:
# example:
#   0: alice
#   1: bob

# Nested enumeration
example: !Enumerate [
  ["foo", "bar"],
  MAP,
  [
    !Index 0,
    !Enumerate [
      !Value 1,  # Depth 1: refers to parent enumerate
      SEQ,
      !Format ["%s: (index: %d, letter: %s)", !Value 1, !Index 0, !Value 0]
    ]
  ]
]
# Result:
# 0:
#   - "foo: (index: 0, letter: f)"
#   - "foo: (index: 1, letter: o)"
#   - "foo: (index: 2, letter: o)"
# 1:
#   - "bar: (index: 0, letter: b)"
#   - "bar: (index: 1, letter: a)"
#   - "bar: (index: 2, letter: r)"
```

**Key Points:**
- `!Index <depth>`: Returns the index (sequence) or key (mapping) at the specified depth
- `!Value <depth>`: Returns the value at the specified depth
- Depth 0 = current enumerate, depth 1 = parent enumerate, etc.
- **Cannot** iterate over `!Index 0` or `!Value 0` (cannot iterate over self)

#### `!AtIndex` - Access Specific Index (v2024.12+)
Access a specific index in a sequence or mapping.

```yaml
# From sequence
first_item: !AtIndex [["first", "second", "third"], 0]  # "first"

# From mapping
value: !AtIndex [{"foo": "bar", "other": "value"}, "foo"]  # "bar"

# With default value
safe_access: !AtIndex [["first"], 100, "default"]  # "default"
default_value: !AtIndex [["first"], 100]  # Error: index out of range
```

## 6. Common Blueprint Patterns

### 6.1 Creating an OAuth2 Application

Complete example for adding a new OAuth2-based application:

```yaml
# yaml-language-server: $schema=https://goauthentik.io/blueprints/schema.json
version: 1
metadata:
  name: Apps - My Application
entries:
  # 1. Create user group for the application
  - id: myapp-users
    model: authentik_core.group
    identifiers:
      name: My App Users
    attrs:
      name: My App Users

  # 2. Create OAuth2 provider
  - id: myapp-provider
    model: authentik_providers_oauth2.oauth2provider
    identifiers:
      name: k8s.pc-tips.se/apps/myapp
    attrs:
      # Find default flows
      authorization_flow: !Find [
        authentik_flows.flow,
        [slug, "default-provider-authorization-implicit-consent"]
      ]
      signing_key: !Find [
        authentik_crypto.certificatekeypair,
        [name, "authentik Self-signed Certificate"]
      ]
      invalidation_flow: !Find [
        authentik_flows.flow,
        [slug, "default-provider-invalidation-flow"]
      ]
      
      # OAuth2 configuration
      client_type: confidential  # or "public"
      redirect_uris:
        - url: https://myapp.example.com/oauth/callback
          matching_mode: strict  # or "regex"
      
      # Secrets from environment
      client_id: !Env MYAPP_CLIENT_ID
      client_secret: !Env MYAPP_CLIENT_SECRET
      
      # Token validity
      access_code_validity: minutes=1
      access_token_validity: minutes=5
      refresh_token_validity: days=30
      
      # User identifier mode
      sub_mode: hashed_user_id  # or "user_id", "user_username", "user_email"
      
      # Standard OpenID scopes
      property_mappings:
        - !Find [authentik_core.propertymapping, [name, "authentik default OAuth Mapping: OpenID 'openid'"]]
        - !Find [authentik_core.propertymapping, [name, "authentik default OAuth Mapping: OpenID 'profile'"]]
        - !Find [authentik_core.propertymapping, [name, "authentik default OAuth Mapping: OpenID 'email'"]]

  # 3. Create application
  - id: myapp-application
    model: authentik_core.application
    identifiers:
      slug: myapp
    attrs:
      name: My Application
      group: Applications  # UI grouping category
      description: My awesome application
      icon: https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/myapp.png
      provider: !KeyOf myapp-provider
      policy_engine_mode: any  # "any" or "all" - how policy bindings are evaluated

  # 4. Bind group to application (authorization)
  - model: authentik_policies.policybinding
    identifiers:
      target: !KeyOf myapp-application
      group: !Find [authentik_core.group, [name, "My App Users"]]
    attrs:
      order: 1  # Lower order = evaluated first
```

**Add to secrets:**
```yaml
# In extra/secrets.yml (ExternalSecret configuration)
MYAPP_CLIENT_ID: <generate-random-id>
MYAPP_CLIENT_SECRET: <generate-random-secret>
```

### 6.2 Creating Users and Groups

```yaml
# yaml-language-server: $schema=https://goauthentik.io/blueprints/schema.json
version: 1
metadata:
  name: Users - New User
entries:
  # Create the user
  - id: user-john
    model: authentik_core.user
    identifiers:
      username: john.doe
    attrs:
      username: john.doe
      name: John Doe
      email: !Env JOHN_EMAIL
      password: !Env JOHN_PASSWORD  # Hashed automatically
      is_active: true
      groups:
        # Add user to groups
        - !Find [authentik_core.group, [name, "Grafana Users"]]
        - !Find [authentik_core.group, [name, "ArgoCD Viewers"]]
        - !Find [authentik_core.group, [name, "Media Users"]]
```

**Note:** Passwords in blueprints are automatically hashed. Never commit plaintext passwords.

### 6.3 Creating Custom Authentication Flows

```yaml
# yaml-language-server: $schema=https://goauthentik.io/blueprints/schema.json
version: 1
metadata:
  name: Flows - Custom Login
entries:
  # 1. Create the flow
  - id: custom-login-flow
    model: authentik_flows.flow
    identifiers:
      slug: custom-login-flow
    attrs:
      name: Custom Login Flow
      title: "Welcome to My Homelab"
      designation: authentication  # authentication|authorization|invalidation|enrollment|unenrollment|recovery|stage_configuration
      policy_engine_mode: all  # all|any
      compatibility_mode: false

  # 2. Create/reference stages
  - id: identification-stage
    model: authentik_stages_identification.identificationstage
    identifiers:
      name: custom-identification
    attrs:
      user_fields:
        - email
        - username
      password_stage: !KeyOf password-stage

  - id: password-stage
    model: authentik_stages_password.passwordstage
    identifiers:
      name: custom-password
    attrs:
      configure_flow: !Find [authentik_flows.flow, [slug, default-password-change]]

  - id: mfa-stage
    model: authentik_stages_authenticator_validate.authenticatorvalidatestage
    identifiers:
      name: custom-mfa

  - id: login-stage
    model: authentik_stages_user_login.userloginstage
    identifiers:
      name: custom-login
    attrs:
      session_duration: seconds=0  # Use authentik default

  # 3. Bind stages to flow (order matters!)
  - model: authentik_flows.flowstagebinding
    identifiers:
      target: !KeyOf custom-login-flow
      stage: !KeyOf identification-stage
    attrs:
      order: 10

  - model: authentik_flows.flowstagebinding
    identifiers:
      target: !KeyOf custom-login-flow
      stage: !KeyOf password-stage
    attrs:
      order: 20

  - model: authentik_flows.flowstagebinding
    identifiers:
      target: !KeyOf custom-login-flow
      stage: !KeyOf mfa-stage
    attrs:
      order: 30

  - model: authentik_flows.flowstagebinding
    identifiers:
      target: !KeyOf custom-login-flow
      stage: !KeyOf login-stage
    attrs:
      order: 100
```

### 6.4 Modifying Default Flows

To customize default flows without replacing them:

```yaml
# yaml-language-server: $schema=https://goauthentik.io/blueprints/schema.json
version: 1
metadata:
  name: Flows - Customize Default Authentication
entries:
  # Add a custom stage to the default authentication flow
  - id: custom-notification-stage
    model: authentik_stages_prompt.promptstage
    identifiers:
      name: custom-welcome-notification
    attrs:
      fields:
        - field_key: notification
          label: Welcome Message
          type: static
          placeholder: "Welcome to the homelab!"

  # Insert the stage into the flow
  - model: authentik_flows.flowstagebinding
    identifiers:
      target: !Find [authentik_flows.flow, [slug, default-authentication-flow]]
      stage: !KeyOf custom-notification-stage
    attrs:
      order: 5  # Insert before identification (order 10)
```

**Warning:** Be careful when modifying system flows. Test thoroughly.

### 6.5 Using State for Safety

```yaml
# Safe: Create only if it doesn't exist (preserve manual changes)
- model: authentik_providers_oauth2.oauth2provider
  state: created  # Never updates
  identifiers:
    name: my-provider
  attrs:
    client_type: confidential
    # client_id and client_secret are auto-generated
    # Using state: created preserves them on subsequent applies

# Strict: Fail if object already exists
- model: authentik_core.application
  state: must_created  # Fail if exists
  identifiers:
    slug: critical-app
  attrs:
    name: Critical Application
    
# Cleanup: Remove an object
- model: authentik_core.application
  state: absent  # Delete the object
  identifiers:
    slug: old-app-to-remove
```

## 7. Blueprint Best Practices

### 7.1 Writing Efficient Blueprints

1. **Use `identifiers` for Uniqueness**
   - Choose stable identifiers (slug, name) that won't change
   - Avoid using auto-generated IDs in identifiers
   
2. **Minimize `attrs` to Required Fields**
   - Only specify fields you want to control
   - Let authentik use defaults for optional fields
   - Avoid setting fields that are auto-generated (unless necessary)

3. **Order Entries by Dependency**
   - Define objects before referencing them with `!KeyOf`
   - Groups before users, providers before applications, flows before bindings

4. **Use `id` for Internal References**
   - Assign `id` to entries you'll reference with `!KeyOf`
   - Use descriptive IDs (e.g., `myapp-provider`, not `provider1`)

5. **Use `!Find` for External References**
   - Reference objects from other blueprints with `!Find`
   - Always verify the object exists before applying

### 7.2 Security Best Practices

1. **Never Hardcode Secrets**
   ```yaml
   # ❌ BAD
   client_secret: "my-super-secret-password"
   
   # ✅ GOOD
   client_secret: !Env MYAPP_CLIENT_SECRET
   ```

2. **Use Environment Variables for Sensitive Data**
   - Configure via `envFrom` in `values.yaml`
   - Source from ExternalSecret resources
   - Never commit `.env` files with real values

3. **Validate Redirect URIs**
   ```yaml
   redirect_uris:
     - url: https://trusted-domain.com/callback
       matching_mode: strict  # Exact match only
   ```

4. **Set Appropriate Token Validity**
   ```yaml
   access_code_validity: minutes=1      # Short-lived auth codes
   access_token_validity: minutes=5     # Short-lived access tokens
   refresh_token_validity: days=30      # Longer-lived refresh tokens
   ```

5. **Use Groups for Access Control**
   - Create dedicated groups per application
   - Bind groups to applications via `policybinding`
   - Never grant access to "all users" unless necessary

### 7.3 Testing Blueprints

1. **Syntax Validation**
   ```bash
   # Use VS Code with YAML extension for real-time validation
   # Add to VS Code settings.json:
   {
     "yaml.schemas": {
       "https://goauthentik.io/blueprints/schema.json": ["**/blueprints/*.yaml"]
     }
   }
   ```

2. **Kustomize Build Test**
   ```bash
   kustomize build --enable-helm k8s/infrastructure/auth/authentik
   ```

3. **Dry Run in Authentik UI**
   - Upload blueprint via Admin UI → Customization → Blueprints
   - Click "Apply" and review the diff
   - Check for errors or warnings

4. **Monitor Application**
   ```bash
   # Watch authentik logs during blueprint application
   kubectl logs -n auth -l app.kubernetes.io/name=authentik --tail=100 -f | grep -i blueprint
   
   # Check blueprint status
   kubectl get blueprintinstance -n auth
   kubectl describe blueprintinstance <name> -n auth
   ```

5. **Test Authentication Flow**
   - After applying application blueprints, test the full OAuth flow
   - Verify redirect URIs, token issuance, and user attributes
   - Check application logs for authentication errors

### 7.4 Common Mistakes to Avoid

1. **❌ Using `state: present` with Auto-Generated Fields**
   ```yaml
   # BAD: Will regenerate client_secret on every apply
   - model: authentik_providers_oauth2.oauth2provider
     state: present
     identifiers:
       name: my-provider
     attrs:
       client_type: confidential
       # client_secret is auto-generated but will be reset!
   ```
   **Fix:** Use `state: created` for providers with auto-generated secrets.

2. **❌ Forgetting to Set `id` for `!KeyOf` References**
   ```yaml
   # BAD: No way to reference this flow
   - model: authentik_flows.flow
     identifiers:
       slug: my-flow
   
   # GOOD: Can reference with !KeyOf my-flow
   - id: my-flow
     model: authentik_flows.flow
     identifiers:
       slug: my-flow
   ```

3. **❌ Using Wrong Model Names**
   - Always check the schema: https://goauthentik.io/blueprints/schema.json
   - Common models:
     - `authentik_core.user`
     - `authentik_core.group`
     - `authentik_core.application`
     - `authentik_flows.flow`
     - `authentik_providers_oauth2.oauth2provider`
     - `authentik_providers_saml.samlprovider`
     - `authentik_policies.policybinding`

4. **❌ Not Handling Blueprint Conditions**
   ```yaml
   # BAD: Entry always applied, even if feature is disabled
   - model: authentik_core.application
     attrs:
       name: Experimental Feature
   
   # GOOD: Only apply if feature is enabled
   - model: authentik_core.application
     conditions:
       - !Env ENABLE_EXPERIMENTAL_FEATURES
     attrs:
       name: Experimental Feature
   ```

5. **❌ Circular Dependencies**
   ```yaml
   # BAD: Flow A references Flow B, Flow B references Flow A
   - id: flow-a
     attrs:
       recovery_flow: !KeyOf flow-b
   - id: flow-b
     attrs:
       recovery_flow: !KeyOf flow-a
   ```
   **Fix:** Use `!Find` for one of the references to break the cycle.

## 8. Available Models Reference

Common authentik models for blueprints:

### 8.1 Core Models
- `authentik_core.user` - User accounts
- `authentik_core.group` - User groups
- `authentik_core.application` - Applications visible in the app launcher
- `authentik_core.token` - API tokens
- `authentik_core.propertymapping` - Attribute mappings

### 8.2 Flows and Stages
- `authentik_flows.flow` - Authentication/authorization flows
- `authentik_flows.flowstagebinding` - Bind stages to flows
- `authentik_stages_identification.identificationstage` - User identification
- `authentik_stages_password.passwordstage` - Password validation
- `authentik_stages_authenticator_validate.authenticatorvalidatestage` - MFA validation
- `authentik_stages_authenticator_totp.authenticatortotpstage` - TOTP setup
- `authentik_stages_authenticator_webauthn.authenticatorwebauthnstage` - WebAuthn setup
- `authentik_stages_user_login.userloginstage` - User login action
- `authentik_stages_consent.consentstage` - User consent for OAuth
- `authentik_stages_prompt.promptstage` - Custom forms/prompts
- `authentik_stages_email.emailstage` - Email sending

### 8.3 Providers
- `authentik_providers_oauth2.oauth2provider` - OAuth2/OIDC provider
- `authentik_providers_saml.samlprovider` - SAML provider
- `authentik_providers_proxy.proxyprovider` - Forward auth/proxy provider
- `authentik_providers_ldap.ldapprovider` - LDAP provider
- `authentik_providers_radius.radiusprovider` - RADIUS provider
- `authentik_providers_scim.scimprovider` - SCIM provider

### 8.4 Policies
- `authentik_policies.policybinding` - Bind policies to objects
- `authentik_policies_expression.expressionpolicy` - Python expression policies
- `authentik_policies_event_matcher.eventmatcherpolicy` - Event matching
- `authentik_policies_password.passwordpolicy` - Password requirements
- `authentik_policies_reputation.reputation` - Reputation tracking

### 8.5 Sources (External Auth)
- `authentik_sources_oauth.oauthsource` - OAuth source (login via Google, GitHub, etc.)
- `authentik_sources_saml.samlsource` - SAML source
- `authentik_sources_ldap.ldapsource` - LDAP source

### 8.6 Other
- `authentik_crypto.certificatekeypair` - SSL certificates
- `authentik_events.notificationrule` - Event notifications
- `authentik_outposts.outpost` - Remote outposts
- `authentik_brands.brand` - Branding/tenants

**Full Reference:** https://goauthentik.io/docs/blueprints/models

## 9. VS Code Configuration

For optimal blueprint editing, add this to `.vscode/settings.json`:

```json
{
  "yaml.schemas": {
    "https://goauthentik.io/blueprints/schema.json": [
      "k8s/infrastructure/auth/authentik/extra/blueprints/*.yaml"
    ]
  },
  "yaml.customTags": [
    "!Condition sequence",
    "!Context scalar",
    "!Enumerate sequence",
    "!Env scalar",
    "!File scalar",
    "!File sequence",
    "!Find sequence",
    "!Format sequence",
    "!If sequence",
    "!Index scalar",
    "!KeyOf scalar",
    "!Value scalar",
    "!AtIndex scalar",
    "!FindObject sequence"
  ]
}
```

## 10. Troubleshooting

### 10.1 Blueprint Not Applied

**Symptoms:** Changes to blueprint files don't appear in authentik.

**Solutions:**
1. Check if file is mounted:
   ```bash
   kubectl exec -n auth <authentik-pod> -- ls /blueprints/
   ```

2. Check authentik logs:
   ```bash
   kubectl logs -n auth -l app.kubernetes.io/name=authentik --tail=200 | grep -i blueprint
   ```

3. Manually trigger blueprint discovery:
   - Admin UI → Customization → Blueprints → Click "Refresh" icon

4. Check for syntax errors:
   ```bash
   kustomize build --enable-helm k8s/infrastructure/auth/authentik
   ```

### 10.2 Blueprint Apply Failed

**Symptoms:** Blueprint shows error in authentik UI or logs.

**Common Errors:**

1. **"Field not declared in schema"**
   - Check model name spelling
   - Verify field exists for the model version
   - Consult schema: https://goauthentik.io/blueprints/schema.json

2. **"!KeyOf reference not found"**
   - Ensure entry with matching `id` exists before the reference
   - Check for typos in the `id` value

3. **"!Find returned no results"**
   - Object doesn't exist yet
   - Use `!KeyOf` if defined in same blueprint
   - Verify identifier field/value are correct

4. **"!Env variable not found"**
   - Check environment variable is set in `values.yaml` `envFrom`
   - Verify ExternalSecret is created and synced
   - Check secret exists: `kubectl get secret <name> -n auth`

5. **"Circular dependency detected"**
   - Use `!Find` instead of `!KeyOf` for one direction
   - Restructure blueprints to break the cycle

### 10.3 OAuth Application Not Working

**Checklist:**
1. Verify redirect URIs match exactly (including trailing slash)
2. Check client_id and client_secret are set correctly
3. Confirm user is in the authorized group
4. Verify policy bindings are present and in correct order
5. Check application logs for OAuth error codes
6. Test with authentik's built-in OAuth test client

### 10.4 User Cannot Access Application

**Checklist:**
1. User is in the required group:
   ```bash
   kubectl exec -n auth <authentik-pod> -- ak user --username <user> list_groups
   ```

2. Group is bound to application via policybinding
3. Policy engine mode is `any` (not `all` unless multiple policies)
4. User account is active (not disabled)
5. Check authentik event log in Admin UI for denial reasons

## 11. Examples from This Repository

### 11.1 Reference Existing Blueprints

This homelab has several production blueprints you can reference:

- **Groups:** `extra/blueprints/groups.yaml` - Application-specific groups
- **Users:** `extra/blueprints/users.yaml` - Admin and standard users
- **Grafana:** `extra/blueprints/apps-grafana.yaml` - OAuth2 provider with role mapping
- **ArgoCD:** `extra/blueprints/apps-argocd.yaml` - OAuth2 with admin/viewer groups
- **Media Apps:** `extra/blueprints/apps-media.yaml` - Complex multi-app configuration
- **Home Assistant:** `extra/blueprints/apps-home-assistant.yaml` - OAuth2 with group mapping
- **Custom Flow:** `extra/blueprints/flows-default-provider-authorization-one-time-consent.yaml`
- **Outposts:** `extra/blueprints/outposts.yaml` - Remote authentik outposts

### 11.2 Secrets Management

Secrets are managed via ExternalSecret resources:

```bash
# View secret configuration
cat extra/secrets.yml

# Check synced secrets
kubectl get secret authentik-blueprint-secrets -n auth -o yaml
```

Environment variables are injected via `values.yaml`:
```yaml
global:
  envFrom:
    - secretRef:
        name: authentik-core-secrets
    - secretRef:
        name: authentik-blueprint-secrets
```

## 12. Deployment Checklist

Before deploying new blueprints:

- [ ] Blueprint file has schema declaration: `# yaml-language-server: $schema=...`
- [ ] Blueprint file has linter/formatter disable comments if needed
- [ ] All referenced models exist in authentik schema
- [ ] All `!KeyOf` references have corresponding `id` fields
- [ ] All `!Find` references point to existing objects (or created in same blueprint)
- [ ] All `!Env` variables are defined in secrets
- [ ] No hardcoded secrets in blueprint files
- [ ] Entry order respects dependencies (groups before users, providers before apps)
- [ ] Identifiers are stable and unique
- [ ] `state` field is appropriate (use `created` for auto-generated fields)
- [ ] Redirect URIs are correct and use `matching_mode: strict`
- [ ] Token validity periods are appropriate for security
- [ ] Policy bindings exist for application access control
- [ ] Blueprint validates with `kustomize build --enable-helm`
- [ ] Git commit message follows conventional commits format
- [ ] Tested in authentik UI before committing

## 13. Additional Resources

- **Authentik Documentation:** https://goauthentik.io/docs/
- **Blueprint Schema:** https://goauthentik.io/blueprints/schema.json
- **Model Reference:** https://goauthentik.io/docs/blueprints/models
- **YAML Tags Guide:** https://goauthentik.io/docs/blueprints/tags
- **Default Blueprints:** Check authentik container at `/blueprints/default/`
- **Community Blueprints:** https://github.com/goauthentik/authentik/tree/main/blueprints

---

## Agent Safety Notes

- **Never commit secrets:** Always use `!Env` for sensitive data
- **Never modify system blueprints:** Files with `blueprints.goauthentik.io/system: "true"` label
- **Test before production:** Validate all blueprints in a test environment first
- **Backup before major changes:** Export authentik configuration via Admin UI
- **Monitor after deployment:** Watch logs and test authentication flows
- **Use GitOps workflow:** All changes via Git, never manual `kubectl apply`

For questions or issues with authentik blueprints, consult the authentik documentation or open an issue in the homelab repository.
