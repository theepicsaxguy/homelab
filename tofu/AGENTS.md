# OpenTofu Infrastructure - Domain Guidelines

SCOPE: Infrastructure provisioning, VM management, and cluster bootstrapping
INHERITS FROM: /AGENTS.md
TECHNOLOGIES: OpenTofu (Terraform fork), Proxmox API, Talos Linux, Cloud-init

**PREREQUISITE: You must have read /AGENTS.md before working in this domain.**

## DOMAIN CONTEXT

Purpose: Provision and manage all infrastructure resources including VMs, networking, load balancers, and Talos Linux cluster bootstrapping.

Architecture:
- `tofu/` - Main OpenTofu configuration with variables, providers, modules
- `tofu/talos/` - Talos Linux machine configuration and cluster bootstrap
- `tofu/lb/` - Load balancer configuration
- `tofu/bootstrap/` - Bootstrap modules for cluster infrastructure

## QUICK-START COMMANDS

```bash
cd tofu

# Format and validate
tofu fmt
tofu validate

# Plan and review
tofu plan -out=tfplan
tofu show -no-color tfplan

# Apply (only with explicit authorization)
tofu apply
```

## PATTERNS

### VM Provisioning Pattern
Define VMs in `tofu/virtual-machines.tf` with node types (control-plane, worker). Use Cloud-init for initial configuration.

### Talos Configuration Pattern
Generate Talos machine configs using `talos_config` data sources. Use `config-machine.tf` for node-specific configs. Inline manifests bootstrap cluster components.

### Network Pattern
Define network resources in tofu modules. Use static IPs for critical infrastructure (load balancer, control-plane nodes).

### Bootstrap Pattern
Use `tofu/bootstrap/` modules to create prerequisite infrastructure:
- Proxmox CSI plugin user, role, and API token
- Static persistent volumes for legacy workloads

## TESTING

- Static validation: `tofu fmt` and `tofu validate`
- Plan review: `tofu plan` output reviewed by humans
- Requirements: All files formatted, configuration validates, plans reviewed before applying

## WORKFLOWS

**Development:**
- Edit Terraform files in `tofu/` directory
- Run `tofu fmt` and `tofu validate`
- Generate plan with `tofu plan -out=tfplan`
- Review plan and create PR with plan output

**Deployment:**
- Infra changes require human authorization and review
- Apply with `tofu apply` only after plan approval
- Include rollback plan in PR description

## COMPONENTS

### Main Configuration
- `main.tf` - Root module and resource references
- `providers.tf` - Provider configurations
- `variables.tf` - Variable definitions
- `output.tf` - Output values

### Infrastructure Modules
- `talos/` - Talos Linux cluster configuration
  - `config-machine.tf` - Machine-specific configurations
  - `config-cluster.tf` - Cluster-wide configuration
  - `virtual-machines.tf` - VM definitions
- `lb/` - Load balancer configuration
- `bootstrap/` - Bootstrap modules

### Configuration Files
- `config.auto.tfvars` - Variable values (do not commit with secrets)
- `nodes.auto.tfvars` - Node definitions
- `defaults.tf` - Default variable values
- `backend.tf` - State backend configuration

## TOFU-DOMAIN ANTI-PATTERNS

### Security & Safety
- Never commit secrets to Terraform files - use variables and `.tfvars`
- Never modify state files manually - use Terraform commands
- Never run `tofu apply` without reviewing plan output
- Never apply infra changes without human authorization and review

### Configuration Management
- Never use `--auto-approve` flag - always require human confirmation
- Never use targeted apply (`-target=...`) unless explicitly approved
- Never delete resources without understanding dependencies
- Never hardcode values that should be variables
- Never skip `tofu fmt` or `tofu validate` before committing

## REFERENCES

## Enterprise Learning Philosophy

### Infrastructure as Learning
Proxmox + Talos + OpenTofu represents enterprise infrastructure patterns. VM lifecycle management, API-driven configuration, and immutable infrastructure are production skills.

### Production-Grade Decisions
- **Talos vs standard Linux**: Immutable OS teaches enterprise security patterns
- **OpenTofu vs manual**: IaC teaches enterprise scalability and audit requirements
- **API-driven vs GUI**: Automation teaches enterprise operational patterns

### Cross-Domain Integration
Infrastructure changes enable application deployment through:
1. VM provisioning → Kubernetes nodes
2. Network configuration → Application connectivity  
3. Storage setup → Application persistence
4. Cluster bootstrapping → Argo CD GitOps pipeline activation

### Enterprise Recovery Patterns
- State backup/recovery teaches enterprise disaster recovery
- Configuration drift detection teaches enterprise compliance
- Version-controlled infrastructure teaches enterprise change management

## REFERENCES

For commit format: /AGENTS.md
For Kubernetes manifests: k8s/AGENTS.md
For Talos Linux: Talos documentation
For Proxmox API: Terraform Proxmox provider documentation