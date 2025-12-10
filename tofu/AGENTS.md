# OpenTofu (tofu/) - Agent Guidelines

This `AGENTS.md` covers the `tofu/` directory which contains OpenTofu/Terraform configuration used to provision VMs, networking, and cluster bootstrapping.

## Purpose & Scope

- Scope: `tofu/` (all TF files, modules, and generated outputs).
- Goal: enable an agent to validate, format, and review Terraform changes as text, and prepare a safe plan for human review.

## Quick-start Commands

Run these commands from the `tofu/` directory.

```bash
# Format terraform files
tofu fmt

# Validate configuration
tofu validate

# Create an execution plan (read-only)
tofu plan -out=tfplan

# Show plan human-readable
tofu show -no-color tfplan
```

Notes:
- Do not run `tofu apply` unless you are authorized and changes are approved by humans.
- The repository contains `terraform.tfstate*` backups — treat these as read-only and never commit state changes.

## Structure & Examples

- `tofu/` holds variables, provider blocks, and modules for Talos, load balancer, and node definitions.
- Example files: `main.tf`, `providers.tf`, `output.tf`, `config.auto.tfvars`.

## Safety & Boundaries

- Never commit secrets to `tofu/` or change `config.auto.tfvars` with real credentials.
- State files (`terraform.tfstate`, backups) are present in the repo for historical reasons; do not edit them.
- Major infra changes must include a migration/runbook and be performed by an operator with access to the target platform.

## How to Propose Changes

1. Create a branch and edit Terraform files only as text.
2. Run `tofu fmt` and `tofu validate` locally and attach plan output to the PR as evidence.
3. Request human review from the infra team and include a rollback plan.

## Tests & Validation

- Static: `tofu validate` and `tofu fmt`.
- Human review: `tofu plan` outputs must be reviewed before applying.

## Code Style & Patterns

- Use consistent naming: `snake_case` for resource names and variables
- Group related resources in separate files (e.g., `network.tf`, `compute.tf`)
- Use variables for values that differ between environments
- Include descriptions for all variables and outputs
- Use `locals` for computed values used multiple times
- Reference existing resources: see `main.tf`, `providers.tf` for patterns

## Pre-Merge Checklist

Before merging OpenTofu/Terraform changes, verify:

- [ ] All `.tf` files are formatted: `tofu fmt` reports no changes
- [ ] Configuration validates: `tofu validate` passes
- [ ] Plan has been generated and reviewed: `tofu plan` output attached to PR
- [ ] No secrets or credentials in code (use variables and `.tfvars` files)
- [ ] State files (`.tfstate`) are not modified or committed
- [ ] Changes include rollback plan and migration steps
- [ ] Variables have descriptions and appropriate defaults
- [ ] Outputs are defined for values needed by other systems
- [ ] Changes reviewed by infra team with platform access
- [ ] Breaking changes documented with upgrade path

---

