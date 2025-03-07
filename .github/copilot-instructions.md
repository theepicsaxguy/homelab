# GitHub Copilot Context & Instructions

This repository manages a **GitOps-only** homelab infrastructure using:

- **Kubernetes (Talos)**
- **OpenTofu (Terraform)**
- **ArgoCD-based deployments**
- **Monitoring and security components**

## 🔹 Core Principles

### 1️⃣ **GitOps-Only: No Manual Changes**

- **All infrastructure changes must be defined in Git and applied automatically.**
- **ArgoCD is the only deployment mechanism.**
  - `kubectl` is for troubleshooting only—no manual `kubectl apply` or `helm install`.
  - Any required state changes **must be committed to Git** before being applied.
- **All changes must maintain a reproducible, fully documented state.**

---

## 🔹 Repository Structure & Rules

### 🏗 **Kubernetes (k8s/)**

#### **🔹 ArgoCD (k8s/argocd/)**

- The **only** entry point for deployments.
- Uses **ApplicationSets** for dynamic app management.
- All apps **must** be declared here—no individual ArgoCD app definitions.

#### **🔹 Applications (k8s/applications/)**

- Functional workloads (e.g., authentication, monitoring).
- Must use **Kustomization overlays**—no raw manifests.

#### **🔹 Infrastructure Components (k8s/infrastructure/)**

- Covers networking, DNS, storage, and foundational services.
- **Networking must use Cilium**—Talos' default networking is prohibited.
- **Ingress is managed via ArgoCD** using predefined templates.

#### **🔹 Monitoring & Security (k8s/monitoring/)**

- Includes **Prometheus, Loki, Falco**, and similar components.
- **Self-healing and alerting must be prioritized.**

---

### 🌍 **OpenTofu (tofu/)**

#### **🔹 Clusters (tofu/kubernetes/)**

- Defines **Talos cluster configurations**.
- **Control planes must be immutable**—rebuild via GitOps if necessary.

#### **🔹 Stateful Apps (tofu/applications/)**

- Covers workloads **requiring persistent storage**.
- All storage **must be declared here**—no in-cluster storage changes.

#### **🔹 IoT & Home Assistant (tofu/home-assistant/)**

- Covers home automation & IoT deployments.
- Terraform is used **only** for provisioning external dependencies.

---

### 📖 **Documentation (docs/)**

#### **🔹 Architecture (docs/architecture/)**

- Defines high-level infrastructure design.

#### **🔹 Best Practices (docs/best-practices/)**

- Covers GitOps, ArgoCD, Kubernetes, and OpenTofu guidelines.

---

## 🔹 Development Workflow

### 📝 **READMEs (README.md)**

- Must **always** reflect the current state of the repository.

### 🚀 **CI/CD & Automation**

- **GitHub Actions** enforce commit standardization.
- **ArgoCD enforces state reconciliation & prevents configuration drift.**

### 📌 **Best Practices & Documentation Sync**

Every code change **must**:

1. **Verify & update documentation** to prevent drift.
2. **Maintain GitOps principles**—no manual interventions.
3. **Follow Kubernetes best practices** for manifests & resource allocation.
4. **Ensure ArgoCD ApplicationSets** are structured correctly.
5. **Assess security & monitoring implications** before merging.

---

## 🔹 Conventions & Best Practices

✅ Kubernetes apps **must** be grouped by functionality. ✅ **Kustomization overlays are mandatory**—no raw manifests.
✅ **ArgoCD ApplicationSets** must be used—direct ArgoCD app definitions are forbidden. ✅ **Terraform follows OpenTofu
best practices**—modular, declarative configurations.

---

## 🚨 Enforcement Rules

❌ **`kubectl` is strictly for troubleshooting.**

- Allowed: **Getting logs, checking state, bootstrapping.**
- **State must always match Git.**
- If a change is required, **it must go through Git.**

❌ **Manual edits to cluster resources are not permitted.**

- **Only allowed in emergency recovery**—must be reverted via Git.

❌ **ArgoCD is the single source of truth.**

- **No exceptions.**

✅ **All implementations must be correct before merging.**
