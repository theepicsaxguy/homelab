# Commit Message Convention

This repository follows [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages.

## Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### Types
- feat: New features
- fix: Bug fixes
- docs: Documentation changes
- style: Code style changes (formatting, etc)
- refactor: Code changes that neither fix bugs nor add features
- perf: Performance improvements
- test: Adding or modifying tests
- build: Changes to build system or dependencies
- ci: Changes to CI configuration
- chore: Other changes that don't modify src or test files

### Scope
Optional, describing the section of codebase:
- k8s
- tofu
- monitoring
- networking
- security

### Subject
- Use imperative mood ("add" not "added" or "adds")
- No period at end
- Max 72 characters

### Breaking Changes
Format:
```
BREAKING CHANGE: <description>
```

### Examples
```
feat(k8s): add cilium network policy support

fix(tofu): correct talos control plane endpoint

docs(monitoring): update grafana dashboard setup guide

BREAKING CHANGE: moves configuration to new structure
```
