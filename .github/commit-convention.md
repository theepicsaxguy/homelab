# Commit Message Convention

This repository follows the Conventional Commits specification.

---

Format: `<type>(<scope>): <subject>` `[optional body]` `[optional footer(s)]`

---

Types:

- `feat` → New feature
- `fix` → Bug fix
- `docs` → Documentation update
- `style` → Code formatting (no functional changes)
- `refactor` → Code restructuring (no bug fixes or features)
- `perf` → Performance optimization
- `test` → Test additions or modifications
- `build` → Build system or dependency changes
- `ci` → CI configuration updates
- `chore` → Miscellaneous updates (excluding source code or tests)

---

Scope (Optional): Defines the affected area:

- `k8s`
- `tofu`
- `monitoring`
- `networking`
- `security`

---

Subject Guidelines:

- Use imperative mood (e.g., "add" not "added" or "adds").
- No trailing period.
- Max 72 characters.

---

Breaking Changes (If Any): Use `BREAKING CHANGE: <description>`.

Example: `BREAKING CHANGE: move configuration to new structure.`

---

Examples: `feat(k8s): add Cilium network policy support` `fix(tofu): correct Talos control plane endpoint`
`docs(monitoring): update Grafana dashboard setup guide`
