# **Commit Message Convention**

This repository follows the [Conventional Commits](https://www.conventionalcommits.org/) specification.

---

## **Format**

```text
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### **Types**

- **feat** → New features
- **fix** → Bug fixes
- **docs** → Documentation updates
- **style** → Code formatting (no functional changes)
- **refactor** → Code restructuring (no bug fixes or features)
- **perf** → Performance optimizations
- **test** → Test additions/modifications
- **build** → Build system or dependency changes
- **ci** → CI configuration updates
- **chore** → Miscellaneous updates (excluding src/tests)

---

## **Scope (Optional)**

Specifies the affected area of the codebase:

- **k8s**
- **tofu**
- **monitoring**
- **networking**
- **security**

---

## **Subject Guidelines**

- **Use imperative mood** (e.g., "add" not "added" or "adds").
- **No trailing period**.
- **Max 72 characters**.

---

## **Breaking Changes**

If a commit introduces breaking changes, include:

```text
BREAKING CHANGE: <description>
```

---

## **Examples**

```text
feat(k8s): add Cilium network policy support

fix(tofu): correct Talos control plane endpoint

docs(monitoring): update Grafana dashboard setup guide

BREAKING CHANGE: move configuration to new structure
```
