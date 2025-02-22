### **GitHub Copilot Context & Instructions**

This repository manages a **GitOps-focused homelab infrastructure**, using:

- **Kubernetes** (Talos)
- **OpenTofu** (Terraform)
- **ArgoCD-based deployments**
- **Monitoring & Security components**

---

## **Key Preferences**

### **Infrastructure Patterns**

- **GitOps-Only**: All infrastructure is declaratively managed.
- **Networking**: Use **Cilium** over Talos' default setup.
- **Performance-First**: Optimize for minimal overhead.

---

## **Repository Structure**

### **Kubernetes (`k8s/`)**

- **Applications** → `k8s/apps/` (e.g., auth, monitoring)
- **Infra Components** → `k8s/infra/` (e.g., DNS, networking)
- **ArgoCD** → `k8s/argocd/` (ApplicationSets, configs)

### **OpenTofu (`tofu/`)**

- **Clusters** → `tofu/kubernetes/`
- **Stateful Apps** → `tofu/apps/`
- **IoT/Home Assistant** → `tofu/home-assistant/`

---

## **Development Workflow**

- **Commits**: Follow [Conventional Commits](https://www.conventionalcommits.org/)
- **CI/CD**: Enforce commit standardization via GitHub Actions.
- **Code Quality**: Clean, best-practice code **without inline comments**.

---

## **Best Practices & Documentation Sync**

Whenever **code changes**, Copilot must:

1. **Verify & update documentation** to prevent drift.
2. **Ensure accuracy in READMEs & architectural overviews.**
3. **Check for outdated information & revise as needed.**
4. **Preserve GitOps principles (declarative, version-controlled, reproducible).**
5. **Assess the impact on infrastructure before recommending changes.**
6. **Follow Kubernetes best practices for manifests & resource allocation.**
7. **Consider monitoring & security implications.**

**All changes must result in a consistent, fully documented state.**

---

### **Conventions**

- **Group Kubernetes apps by functionality**.
- **Use Kustomization for overlays**.
- **Follow ArgoCD ApplicationSet patterns**.
- **Separate Stateful & Stateless IaC components**.
- **Adhere to OpenTofu best practices**.
