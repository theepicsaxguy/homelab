# LiteLLM - Agent Guidelines

## Purpose
AI model proxy with enterprise SSO integration, role-based access control, and team management.

## Configuration Architecture

### Authentication Methods
1. **JWT Authentication** (Primary) - Uses JWT role mapping from Authentik groups
2. **OAuth SSO** (Fallback) - Direct authentication via environment variables  
3. **Header-based** (Fallback) - Custom SSO proxy integration

### Required Files
- `proxy_server_config.yaml` - Main LiteLLM configuration
- `deployment.yaml` - Environment variables and container settings
- `AGENTS.md` - This file (agent guidelines)

## Configuration Rules

### JWT Authentication Setup
When `enable_jwt_auth: true`, must have:
```yaml
general_settings:
  enable_jwt_auth: true
  
litellm_jwtauth:
  user_roles_jwt_field: "groups"  # Authentik groups claim
  user_allowed_roles:
    - proxy_admin      # Required for admin_only UI access
    - internal_user
    - internal_user_viewer  # Fallback role
    - customer
  jwt_litellm_role_map:
    - jwt_role: "Litellm Admins"      # Authentik group
      litellm_role: "proxy_admin"        # Mapped role
    - jwt_role: "Litellm Users"
      litellm_role: "internal_user"
```

**Required environment variables:**
```yaml
env:
- name: JWT_PUBLIC_KEY_URL
  value: "https://sso.peekoff.com/.well-known/openid-configuration/jwks"
- name: GENERIC_SCOPE
  value: "openid profile email groups"  # Must include groups
```

### OAuth Fallback Setup
When JWT authentication is disabled:
```yaml
generic_oauth:
  scope: "openid profile email groups"
  user_role_field: "groups"  # Must contain direct LiteLLM role values
```

## Agent Guidelines

### When Working with SSO Issues
1. **ALWAYS verify authentication method precedence** - JWT vs OAuth vs headers
2. **Check `enable_jwt_auth` status** - Required for JWT role mapping
3. **Validate scopes include `groups`** - Required for role information
4. **Ensure `user_allowed_roles` includes all fallback roles**
5. **Test JWT token payload** to verify group claims are present

### Common Failure Patterns
- `internal_user_viewer` despite admin group → Missing `enable_jwt_auth: true`
- Role mapping ignored → JWT auth not enabled, OAuth active
- Access denied with `admin_only` → User lacks `proxy_admin` role

### Testing Requirements
Before marking SSO issues as resolved:
- [ ] JWT authentication is enabled
- [ ] Groups scope is included in OAuth request
- [ ] Authentik user is in correct group
- [ ] JWT token contains groups claim
- [ ] Role mapping is applied correctly
- [ ] User receives expected `proxy_admin` role
- [ ] Admin UI access works

### Implementation Checklist
- [ ] All authentication methods configured (JWT + OAuth fallback)
- [ ] Role mappings include all expected groups
- [ ] Environment variables set for JWT validation
- [ ] Fallback roles allowed in configuration
- [ ] UI access mode matches allowed roles

## DO NOT
- Commit historical fixes to AGENTS.md
- Remove working configurations for "simplification"
- Assume role mapping works without testing
- Change authentication methods without understanding precedence

## REQUIRED VERIFICATION
Any changes to authentication or role mapping MUST:
1. Verify JWT token contents with debug endpoint
2. Test with actual Authentik admin user
3. Confirm admin UI access with `proxy_admin` role
4. Validate fallback behavior for non-admin users

## Security Requirements
- All SSO configurations must use HTTPS endpoints
- Groups claim must be validated before role assignment
- Default roles should be most restrictive possible
- Admin access should require explicit role assignment