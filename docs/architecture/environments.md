# Environment Architecture

This document describes the environment configuration patterns used across the infrastructure.

## Environment Structure

The infrastructure follows a three-environment pattern:

- **Development (dev-infra)**
  - Allows empty applications
  - Used for testing and development
  - Resource limits are relaxed

- **Staging (staging-infra)**
  - Mirrors production configuration
  - Used for pre-production validation
  - Strict resource limits enforced

- **Production (prod-infra)**
  - Strict resource limits and configuration
  - No empty applications allowed
  - High availability requirements

## Environment-Specific Customizations

Each environment inherits from the base infrastructure in `k8s/infra/base` and applies specific customizations through:

- Namespace assignments
- Resource limit patches
- Environment-specific labels
- Security configurations

## ApplicationSet Management

Environments are managed through ArgoCD ApplicationSets with:

- Environment-specific sync policies
- Automated pruning and self-healing
- Retry policies for resilience
- Environment-specific empty application policies