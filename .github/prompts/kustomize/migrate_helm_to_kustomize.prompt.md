# Migrate from a Helm-Based to a Kustomize-Based Configuration

**Goal:** Detail a migration plan for converting a Helm-based application configuration to a Kustomize-based setup while
preserving its state.

**Instructions:**

- Explain how to extract configuration values from the Helm setup and transform them into a Kustomize format.
- Include guidelines for handling sensitive data like ConfigMaps and Secrets during the migration.
- Describe a method for comparing the outputs of the two configurations to ensure consistency.
- Outline the steps for replacing the existing configuration with the new one and verifying that the deployed state
  remains stable.

**References:**

- [Helm to Kustomize Migration Guide](../docs/HelmToKustomize.md)
- [GitOps Best Practices](../docs/GitOps-BestPractices.md)
