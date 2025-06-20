1. Repo map

k8s/ – Kubernetes manifests (infrastructure/, applications/)

tofu/ – OpenTofu / Proxmox infra code

website/ – Docusaurus docs & TypeScript

.github/ – CI, commit rules


2. Commit & PR format

type(scope): subject     # feat(apps)!: bump API; fix(k8s): correct replica count

Valid types: feat fix chore docs style refactor test perf.  Use ! for breaking changes.
PR title = first commit line.

3. Local validation (run only what you touched)

Change type	Run before commit

*.tf or files under tofu/	tofu fmt && tofu validate
Kubernetes YAML under k8s/	kustomize build --enable-helm <dir> for each changed folder
website/ TS / docs	npm install && npm run typecheck && npm run lint
Any new container image refs	Pin explicit tag (no latest)


If you didn’t touch it, you don’t need to run its check—keep feedback loops tight.

4. Scope & quality rules

Keep diff < 200 LOC when possible; one concern per PR.

Edit source files only—never rendered output, live clusters, or Talos configs.

Leave code cleaner than you found it (DRY, KISS, SRP, etc.).

Use ExternalSecrets (Bitwarden) for all secrets; cert-manager for TLS.

Version-pin every image / module.

No inline code comments—if something really needs explaining, put it in docs.


5. Documentation

Update docs only for significant behaviour changes.
Changing a value from 20 → 40 isn’t worth a doc edit.

Follow the existing doc templates and tone: conversational, honest, no jargon.

Docs live in website/docs/; keep titles, front-matter, and meta tags consistent with the style guide.


6. PR body checklist

1. What & why – brief, human-friendly summary.


2. Validation evidence – paste the commands you actually ran (see table) and their success output.


3. Impact radius – mention anything that needs follow-up or watcher attention.



7. If blocked

Ask for the missing file, variable, or spec instead of guessing.


---

Guiding principles: DRY • SoC • KISS • YAGNI • SRP • Encapsulation • Modularity • Fail-Fast • Clean Code.

