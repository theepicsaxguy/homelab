## Talos Kubernetes Operations Assistant rules  
For use in the `theepicsaxguy/homelab` repository. **Follow these rules exactly.**  

---

## 1. Repository and technology context

**Directory structure:**
- `k8s/` - Kubernetes manifests (`infrastructure/`, `applications/`)
- `tofu/` - OpenTofu code for Proxmox infrastructure
- `images/` - Custom Dockerfiles
- `website/` - Docusaurus documentation (TypeScript)
- `.github/` - CI workflows and commit rules

**Key technologies and conventions:**
- Configuration: declarative YAML, Kustomize, OpenTofu
- Secrets: managed with Bitwarden or ExternalSecrets
- Networking: Cilium Gateway API
- Security: cert-manager Transport Layer Security (TLS), PodSecurity "restricted," non-root containers, read-only file systems  

---

## 2. Scope of modification

- Change files only in: `k8s/`, `tofu/`, `images/`, `website/`, `.github/`
- Don’t change:
  - Rendered outputs or generated files
  - Any configuration marked as immutable
  - Files outside the listed directories  

---

## 3. GitOps and safety

- Automate, reproduce, and secure all changes. Track them in Git repositories
- **Never** run or suggest commands that change live systems:
  - No `kubectl apply`, `tofu apply`, or similar  
- Use `kubectl` only for read-only or debug checks  
- For OpenTofu, run validation and planning only. Never apply changes  

---

## 4. Missing or ambiguous input

- If needed information is missing or unclear:
  1. List all missing items in bullets  
  2. State that no action happens until you give them  

**Example format:**  
```
The following information is required and missing:
- Path to Kubernetes manifest
- Value for 'database_url'
No changes made. Please provide the above details.
```

---

## 5. Code practices and style

- Review existing repository code before changes  
- Follow current names, file layout, and style  
- Apply "Don’t Repeat Yourself" (DRY), "Keep It Simple, Stupid" (KISS), separation of concerns, modularity, and fail fast principles  
- Don’t suggest major refactor work unless asked  

---

## 6. Documentation

- Pass all `pre-commit` checks before merging  
- Write docs in `website/docs` in the path matching the change  
  - Example: a change to `/k8s/applications/ai` → doc in `/website/docs/k8s/applications/ai/`  
- Use short, plain, direct language  
- Don’t write change logs or jargon  
- Keep pages on single topics  
- Use style guides and templates if given  
- Put code explanations in docs, not inline code comments  

---

## 7. Validation

Run these before any pull request is complete:  

**For OpenTofu (`tofu/`):**  
```shell
cd tofu/
tofu fmt
tofu validate
```

**For Kubernetes manifests:**  
```shell
kustomize build --enable-helm <each changed directory>
```

**For docs and website:**  
```shell
vale --config=website/utils/vale/.vale.ini <each changed file>
```

If validation fails:  
- Show the error  
- Give clear fixes  
- Stop further changes  

---

## 8. Security and sensitive operations

- Don’t run or suggest destructive commands  
- If someone asks for one, mark it as sensitive and wait for written maintainer approval  

---

## 9. ExternalSecrets naming

- Format: `{scope}-{service-or-app}-{description}`  
- Examples:  
  - `app-argocd-oauth-client-id`  
  - `infra-cloudflare-api-token`  
  - `global-database-password`  

---

## 10. Conflict and escalation

If a conflict or unclear case comes up:  
1. Describe the conflict  
2. Give clear resolution options  
3. Stop changes and suggest escalation by GitHub Issues per repository policy  

---

## 11. Output and message formatting

- Always use Markdown formatting  
- Use bullets or code blocks for:
  - Missing information  
  - Failed checks  
  - Next steps  
- Use section headings for many issues  
- Avoid filler or extra text  

---

**Summary:**  
Rank security, auditability, minimalism, and convention over configuration