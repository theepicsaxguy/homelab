# LiteLLM - Agent Guidelines

## SSO Role Mapping Issue Resolution

### Problem
Users in Authentik `Litellm Admins` group receiving `internal_user_viewer` role instead of `proxy_admin`, causing access denied to admin UI with error: "User not allowed to access proxy. User role=internal_user_viewer, proxy mode=admin_only"

### Root Cause Analysis
The issue stemmed from **authentication method misconfiguration**:

1. **JWT role mapping configured** but **JWT authentication NOT enabled**
2. **OAuth SSO active** but expecting direct LiteLLM role values, not Authentik group names  
3. **Missing `enable_jwt_auth: true`** caused JWT role mapping to be ignored
4. **OAuth fallback** assigned deprecated `internal_user_viewer` role instead of applying configured mapping

### Key Configuration Points

#### JWT Authentication Requirements
```yaml
general_settings:
  enable_jwt_auth: true  # ⚠️ REQUIRED for JWT role mapping to work
  
  litellm_jwtauth:
    user_roles_jwt_field: "groups"  # Field containing Authentik groups
    user_allowed_roles:
      - proxy_admin           # Required for admin_only UI access
      - internal_user
      - internal_user_viewer
      - customer
    jwt_litellm_role_map:
      - jwt_role: "Litellm Admins"     # Authentik group name
        litellm_role: "proxy_admin"         # Mapped LiteLLM role
      - jwt_role: "Litellm Users"       # Authentik group name  
        litellm_role: "internal_user"         # Mapped LiteLLM role
```

#### OAuth SSO Configuration
```yaml
env:
- name: GENERIC_SCOPE
  value: "openid profile email groups"  # Include groups for JWT claims
- name: JWT_PUBLIC_KEY_URL  # Required for JWT token validation
  value: "https://sso.peekoff.com/.well-known/openid-configuration/jwks"

generic_oauth:
  scope: "openid profile email groups"  # Must include groups
  user_role_field: "groups"          # Field containing role info
```

### Authentication Method Precedence
1. **JWT Authentication** (if `enable_jwt_auth: true`) - Uses JWT role mapping
2. **OAuth SSO** (if JWT disabled) - Uses direct role values, expects `proxy_admin` not group names
3. **Header-based** - Fallback for custom SSO proxies

### Common Issues & Solutions

| Issue | Cause | Fix |
|--------|--------|------|
| `internal_user_viewer` role despite admin group | JWT auth not enabled, role mapping ignored | Add `enable_jwt_auth: true` |
| Missing groups in JWT token | `groups` scope missing from OAuth | Include `groups` in all scope configurations |
| Role mapping not applied | Wrong auth method active | Verify which auth method is being used |

### Troubleshooting Checklist

- [ ] `enable_jwt_auth: true` in `general_settings`
- [ ] `JWT_PUBLIC_KEY_URL` environment variable set
- [ ] `groups` scope included in all OAuth configurations
- [ ] Authentik user is in correct group (`Litellm Admins`)
- [ ] `proxy_admin` role in `user_allowed_roles` list
- [ ] `ui_access_mode: admin_only` requires `proxy_admin` role

### Configuration Files
- **Main config**: `proxy_server_config.yaml`
- **Deployment env**: `deployment.yaml` 
- **Authentik blueprint**: `apps-litellm.yaml`

### Expected Behavior After Fix
1. User authenticates via Authentik SSO
2. JWT token includes `groups: ["Litellm Admins"]` claim
3. JWT authentication enabled and processes role mapping
4. `"Litellm Admins" → "proxy_admin"` mapping applied
5. User gains admin UI access with `proxy_admin` role