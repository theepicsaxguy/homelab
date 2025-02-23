# Commit Message Convention

This repository follows the Conventional Commits specification.

---

### Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

The subject is a concise summary of the change. The body (if needed) provides additional details or lists key
modifications. The footer is used for metadata like `BREAKING CHANGE:`.

---

### Types

- feat → Introduces a new feature
- fix → Resolves a bug
- docs → Updates documentation
- style → Code formatting (no functional changes)
- refactor → Improves code structure (no bug fixes or features)
- perf → Enhances performance
- test → Adds or modifies tests
- build → Adjusts build system or dependencies
- ci → Updates CI configuration
- chore → Miscellaneous changes (excluding source code or tests)

---

### Scope (Optional)

Defines the affected area of the change:

- k8s
- tofu
- monitoring
- networking
- security

---

### Subject Guidelines

- Use imperative mood (e.g., "add" not "added" or "adds").
- No trailing period.
- Max 72 characters.

---

### Body (If Needed)

Use a body if additional explanation is required:

- Explain why the change was made.
- Highlight significant modifications.
- Use bullet points if listing multiple adjustments.

---

### Breaking Changes (If Any)

Use:

```
BREAKING CHANGE: <description>
```

Example:

```
BREAKING CHANGE: move configuration to new structure.
```

---

### Examples

#### Single Change

```
feat(k8s): add Cilium network policy support
```

#### Multiple Related Changes in One Commit (Using a Body)

```
feat(k8s): add Cilium network policy support

- Added default network policies to improve security
- Fixed egress rule configuration to prevent unintended traffic blocks
- Optimized policy selectors for better performance
```

#### Breaking Change

```
refactor(k8s): restructure configuration handling

BREAKING CHANGE: moved all network policy definitions to a new directory.
```
