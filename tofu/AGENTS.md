# OpenTofu Infrastructure - Domain Guidelines

SCOPE: Infrastructure provisioning, VM management, and cluster bootstrapping
INHERITS FROM: /AGENTS.md
TECHNOLOGIES: OpenTofu (Terraform fork), Proxmox API, Talos Linux, Cloud-init

## DOMAIN CONTEXT

Purpose:
Provision and manage all infrastructure resources including virtual machines, networking, load balancers, and Talos Linux cluster bootstrapping.

Boundaries:
- Handles: VM provisioning, Proxmox resources, Talos configuration, load balancer setup, CSI plugin bootstrap
- Does NOT handle: Kubernetes manifests (see k8s/), container images (see images/)
- Integrates with: k8s/ (cluster configuration references), tofu/bootstrap/ (infrastructure resources)

Architecture:
- `tofu/` - Main OpenTofu configuration with variables, providers, and modules
- `tofu/talos/` - Talos Linux machine configuration and cluster bootstrap
- `tofu/lb/` - Load balancer configuration
- `tofu/bootstrap/` - Bootstrap modules for cluster infrastructure (Proxmox CSI plugin, persistent volumes)
- `tofu/output/` - Generated configuration files (kube-config, talos-machine-config) - not committed

## QUICK-START COMMANDS

```bash
cd tofu

# Format terraform files
tofu fmt

# Validate configuration
tofu validate

# Create an execution plan (read-only)
tofu plan -out=tfplan

# Show plan human-readable
tofu show -no-color tfplan

# Apply changes (only with explicit authorization)
tofu apply
```

## TECHNOLOGY CONVENTIONS

### Resource Naming
- Use `snake_case` for resource names and variables
- Use descriptive names: `talos_cluster_k8s`, `proxmox_vm_worker`
- Maintain consistency with existing patterns in the codebase

### State Management
- State files (`terraform.tfstate`) are generated during `tofu apply`
- Do not commit state files to Git
- State backups exist in repository for historical reference (read-only)
- Use remote backend for production state management

### Variables
- Define sensitive values in `.tfvars` files (do not commit with real credentials)
- Use `terraform.tfvars.example` as template
- Include descriptions for all variables and outputs
- Use `locals` for computed values used multiple times

### Provider Configuration
- Proxmox provider manages VMs and storage
- Talos provider manages cluster bootstrap
- Other providers as needed (DNS, certificates)
- See `tofu/providers.tf` for provider setup

## PATTERNS

### VM Provisioning Pattern
Define VMs in `tofu/virtual-machines.tf` with node types (control-plane, worker). Use Cloud-init for initial configuration. Reference VM configurations in Talos cluster setup.

### Talos Configuration Pattern
Generate Talos machine configurations using `talos_config` data sources. Use `config-machine.tf` for node-specific configs. Inline manifests bootstrap cluster components (Cilium, cluster secrets).

### Network Pattern
Define network resources in tofu modules. Use static IPs for critical infrastructure (load balancer, control-plane nodes). Reference IPs in configuration files.

### Bootstrap Pattern
Use `tofu/bootstrap/` modules to create prerequisite infrastructure:
- Proxmox CSI plugin user, role, and API token
- Static persistent volumes for legacy workloads (rarely used)

## TESTING

Strategy:
- Static validation: `tofu fmt` and `tofu validate`
- Plan review: `tofu plan` output reviewed by humans
- No automated tests for infrastructure code

Requirements:
- All `.tf` files must be formatted
- Configuration must validate successfully
- Plans must be reviewed before applying

Tools:
- tofu fmt: Format code
- tofu validate: Validate configuration syntax
- tofu plan: Show planned changes
- tofu show: Display plan in human-readable format

## WORKFLOWS

Development:
- Create branch from main
- Edit Terraform files in `tofu/` directory
- Run `tofu fmt` to format code
- Run `tofu validate` to check syntax
- Run `tofu plan -out=tfplan` to generate plan
- Review plan output carefully
- Create PR with plan output attached

Build:
- No build step for Terraform code
- Validation happens via `tofu fmt` and `tofu validate`

Deployment:
- Infra changes require human authorization and review
- Apply with `tofu apply` only after plan approval
- Include rollback plan in PR description
- Major changes require migration runbook

## COMPONENTS

### Main Configuration
- `main.tf` - Root module and resource references
- `providers.tf` - Provider configurations
- `variables.tf` - Variable definitions
- `output.tf` - Output values

### Infrastructure Modules
- `bootstrap.tf` - Bootstrap infrastructure resources
- `talos/` - Talos Linux cluster configuration
  - `config-machine.tf` - Machine-specific configurations
  - `config-cluster.tf` - Cluster-wide configuration
  - `config-secrets.tf` - Cluster secrets
  - `image.tf` - Talos image configuration
  - `virtual-machines.tf` - VM definitions
  - `upgrade-nodes.tf` - Node upgrade logic
- `lb/` - Load balancer configuration
- `bootstrap/` - Bootstrap modules
  - `proxmox-csi-plugin/` - Proxmox CSI user/role/token
  - `volumes/persistent-volume/` - Static volume provisioning
- `output/` - Generated configuration files (not committed)
  - `kube-config.yaml` - Kubernetes cluster config
  - `talos-config.yaml` - Talos cluster config
  - `talos-machine-config-*.yaml` - Per-node Talos configs

### Configuration Files
- `config.auto.tfvars` - Variable values (do not commit with secrets)
- `talos_image.auto.tfvars` - Talos image configuration
- `nodes.auto.tfvars` - Node definitions
- `defaults.tf` - Default variable values
- `backend.tf` - State backend configuration

## ANTI-PATTERNS

Never commit secrets or credentials to Terraform files. Use variables and `.tfvars` files with placeholder values.

Never run `tofu apply` without reviewing the plan output. Always understand what will change before applying.

Never modify state files manually. Use Terraform commands to manage state.

Never use resource `destroy` without careful planning. Understand what depends on the resource.

Never skip `tofu fmt` or `tofu validate` before committing. Code must be formatted and validated.

Never apply infra changes without human authorization and review. Infra changes require approval.

Never hardcode values that should be variables. Use variables for environment-specific configuration.

## SAFETY BOUNDARIES

Never commit secrets or credential material to `tofu/` directory.

Never modify state files (`terraform.tfstate`) directly.

Never run `tofu apply` without explicit human authorization and plan review.

Never delete resources without understanding dependencies and impact.

Never change variables in `config.auto.tfvars` without updating `terraform.tfvars.example`.

## REFERENCES

For commit message format, see root AGENTS.md

For Kubernetes manifests, see k8s/AGENTS.md

For Talos Linux configuration, see Talos documentation

For Proxmox API provider, see Terraform Proxmox provider documentation
