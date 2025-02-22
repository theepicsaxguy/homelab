# Project Documentation Guidelines 📚

## Documentation First Approach

When documenting this project, follow these core principles:

1. **Fact-Based Documentation**: Every technical decision must be documented with:

   - Concrete reasoning
   - Performance implications
   - Security considerations
   - Resource requirements

2. **Infrastructure Components**: Document each layer with:

   ```yaml
   component:
     purpose: 'What it does'
     dependencies: ['Required components']
     configuration: 'Key settings'
     performance: 'Resource usage/limits'
   ```

3. **Performance Metrics**: Always include:
   - Resource consumption baselines
   - Scaling thresholds
   - Bottleneck identification
   - Optimization opportunities

## Documentation Structure

### 1. Project Overview

- Architecture diagrams (preferably in `.svg` format)
- Component relationships
- Network flow diagrams
- Security boundaries
- Resource allocation

### 2. Infrastructure Layer

Document with focus on:

- Talos configuration and customizations
- Cilium networking setup and policies
- Storage configurations and CSI implementation
- Security policies and network boundaries

### 3. Application Platform

Detail:

- ArgoCD deployment patterns
- Application lifecycle management
- Resource quotas and limits
- Service mesh configurations

### 4. Monitoring & Operations

Include:

- Alert thresholds
- Common failure scenarios
- Recovery procedures
- Performance benchmarks

## Best Practices

1. **Code Examples**: Include minimal, focused examples:

   ```hcl
   # Example: Show only relevant configuration
   resource "example" {
     key_setting = value    # Why this value?
     performance = setting  # Performance impact
   }
   ```

2. **Performance Documentation**:

   - Document baseline metrics
   - Include scaling thresholds
   - Note resource constraints
   - List optimization options

3. **Security Documentation**:
   - Document access patterns
   - List security boundaries
   - Include network policies
   - NO SECRETS OR CREDENTIALS

## Contribution Requirements

1. **GitOps Changes**:

   - All changes must be in Git
   - Include clear commit messages
   - Reference related issues/tickets

2. **Code Updates**:

   - Document version updates
   - Note breaking changes
   - Include migration steps
   - List compatibility requirements

3. **Performance Updates**:
   - Document baseline changes
   - Note resource implications
   - Include benchmark results

## Documentation Location Guidelines

1. **Code-level Documentation**:

   - Place next to code (same directory)
   - Use meaningful file names
   - Include version information

2. **Architecture Documentation**:

   - Store in `/docs` directory
   - Use SVG for diagrams
   - Link related documents

3. **Operational Documentation**:
   - Include in respective service folders
   - Document failure scenarios
   - Add recovery procedures

Remember: Documentation should be concise, factual, and maintainable. When in doubt, document the "why" not just the
"what". 🎯
