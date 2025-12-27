# AGENTS.md - Authentik Identity Provider

## 1. Purpose & Scope

This AGENTS.md provides guidance for AI agents working with authentik, the open-source identity provider (IdP) used in
this homelab for single sign-on (SSO) and authentication across all applications.

**What this covers:**

- Understanding authentik's role in the homelab infrastructure
- Creating and maintaining authentik blueprints (GitOps-style configuration)
- Writing efficient and correct blueprint YAML files
- Managing applications, users, groups, flows, and providers
- Blueprint YAML tags and their proper usage
- Testing and validation of blueprints

**Key Concept:** Authentik uses **Blueprints** - declarative YAML files that define the entire authentication
infrastructure as code. Blueprints work in a GitOps manner, automatically applying configuration changes when files are
modified.

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
- **Atomic**: All entries in a blueprint succeed or fail together (database transaction using Django's atomic wrapper)
- **Version controlled**: Part of the GitOps workflow
- **Discovery order is not guaranteed** - dependencies between blueprints should use meta models for proper ordering

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
version: 1 # Required: always 1
metadata:
  name: Example Blueprint # Required: human-readable name
  labels: # Optional: special labels control behavior
    blueprints.goauthentik.io/instantiate: 'true' # Auto-instantiate (default: true)
    blueprints.goauthentik.io/description: 'Brief description'
    blueprints.goauthentik.io/system: 'true' # System blueprint (don't modify)
context: # Optional: default context variables
  foo: bar
entries: # Required: list of objects to create/update
  - model: authentik_flows.flow # Required: model in app.model notation
    state: present # Optional: present|created|must_created|absent
    id: flow-id # Optional: ID for !KeyOf references
    identifiers: # Required: unique identifier(s)
      slug: my-flow
    attrs: # Optional: attributes to set
      name: My Flow
      designation: authentication
    conditions: # Optional: conditions for evaluation
      - !Context some_var
    permissions: # Optional: object-level permissions (v2024.8+)
      - permission: inspect_flow
        user: !Find [authentik_core.user, [username, akadmin]]
```

### 4.2 Entry States

The `state` field controls how entries are managed:

| State               | Behavior                                                                    |
| ------------------- | --------------------------------------------------------------------------- |
| `present` (default) | Creates if missing, updates `attrs` if exists (overwrites specified fields) |
| `created`           | Creates if missing, never updates (preserves manual changes)                |
| `must_created`      | Creates only if missing, fails if exists (strict validation)                |
| `absent`            | Deletes the object (may cascade to related objects)                         |

**Best Practice:** Use `present` for most cases. Use `created` for objects with auto-generated fields (like OAuth client
secrets) that shouldn't be overwritten.

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
    name: my-app # Used to find the provider
  attrs:
    # Only these fields are updated on existing providers
    redirect_uris:
      - url: https://app.example.com/callback
    client_id: !Env MYAPP_CLIENT_ID
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
    target: !KeyOf my-flow # References the flow's primary key
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

**Format:** `!Find [model_name, [field1, value1], [field2, value2], ...]` **Error if:** No matching object found.

#### `!FindObject` - Lookup with Full Data (v2025.8+)

Like `!Find`, but returns serialized object data instead of just the primary key. Available in authentik v2025.8 and
later.

```yaml
flow_designation: !AtIndex [!FindObject [authentik_flows.flow, [slug, default-password-change]], designation]
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
enabled: !Context goauthentik.io/enterprise/licensed # Boolean
models: !Context goauthentik.io/rbac/models # Dictionary

# With default value
value: !Context [foo, default-value]
```

### 5.2 String Manipulation Tags

#### `!Format` - String Formatting

Python-style string formatting with `%` operator.

```yaml
name: !Format [my-policy-%s, !Context instance_name]
# Result: my-policy-production

model: !Format ['authentik_stages_authenticator_%s.authenticator%sstage', !Value 0, !Value 0]
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
required: !Condition [AND, !Context instance_name, !Find [authentik_flows.flow, [slug, my-flow]], 'string value', 123]
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
first_item: !AtIndex [['first', 'second', 'third'], 0] # "first"

# From mapping
value: !AtIndex [{ 'foo': 'bar', 'other': 'value' }, 'foo'] # "bar"

# With default value
safe_access: !AtIndex [['first'], 100, 'default'] # "default"
default_value: !AtIndex [['first'], 100] # Error: index out of range
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
      name: k8s.peekoff.com/apps/myapp
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


Use Openwiki mcp for more details.
```
