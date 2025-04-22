## Conventions & Instructions

### 1. Deployment Tools

- Use **only** Kustomize, Helm (via Kustomize), or ArgoCD for all deployments.
- **Never** use manual `helm install` or direct Helm CLI commands.
- **kubectl** is allowed **solely** for testing, validation, or troubleshooting—**never** for deployment or resource
  modification.

### 2. Troubleshooting Workflow

- **Step 1:** Collect and present relevant logs, status, and error messages.
- **Step 2:** Based on the collected evidence, propose solutions **only** if evidence is sufficient.
  - Do **not** recommend fixes based solely on symptoms without evidence.
  - Explicitly **cite the supporting evidence** for each recommendation.

### 3. Secrets Management

- Define all secrets using `ExternalSecret` resources.
- Always reference the `ClusterSecretStore` named `bitwarden-backend`.
- Precisely map all secret keys to their respective remote keys.

### 4. Service Exposure

- Expose all services **exclusively** with the Cilium Gateway API using `HTTPRoute` resources.
  - Use the `internal` gateway for local network access outside the cluster.
  - Use the `external` gateway for public/internet-facing services.
- Always specify hostnames and routing rules clearly and correctly.

### 5. Helm Chart Management

- Manage Helm charts using the `helmCharts` block in Kustomize **only**.
- For every chart, specify:
  - Chart name
  - Repository
  - Version
  - Release name
  - Namespace
  - Values file

### 6. Debugging & Restrictions

- Use BusyBox for network troubleshooting tasks as required.
- **Never** use manual SSH access (Talos prohibits it).
- **Never** create YAML or manifest files solely for debugging purposes.

### 7. Deviation & Documentation

- **If any convention must be violated:**
  - Explicitly state the deviation, cite the instruction being overridden, and provide a justification.
  - Where possible, suggest how to return to full compliance.

---

## Enforcement & Response Rules

- **Always** follow the above conventions for every recommendation and output.
- If a request violates a convention:
  - Do **not** fulfill the request as stated.
  - **Explain** which convention is being violated.
  - **Suggest** a compliant alternative.
- For all tasks, **reason step by step**, making your process and decisions explicit.
- If an instruction or request is ambiguous, **ask clarifying questions before proceeding**.

---

## Output Expectations

- Follow the conventions, workflow, and formatting explicitly.
- Structure responses with clear steps or bullet points.
- **Do not repeat information unnecessarily.**
- Clearly separate each phase of troubleshooting, guidance, or documentation.
- If information is missing or context is inadequate, explain what is needed from the user.
