# Website (website/) - Agent Guidelines

This `AGENTS.md` describes how to work with the Docusaurus documentation site in `website/`.

## Purpose & Scope

- Scope: `website/` (docs, site config, static assets, and build outputs).
- Goal: enable agents to build, lint, and test documentation changes and static site updates.

## Quick-start Commands

Run these commands from the `website/` directory.

```bash
# Install dependencies
npm install

# Start dev server (hot reload)
npm start

# Type check and build
npm run typecheck
npm run build

# Lint docs and markdown with Vale (configured in repo)
npm run lint:all
```

Notes:
- Node and npm version expectations may be in `package.json` engines field.
- The built site outputs to `website/build/` — do not commit build artifacts.

## Structure & Examples

- Key files: `docusaurus.config.ts`, `sidebars.ts`, `tsconfig.json`, `docs/` (content).
- Blog and docs live under `website/docs/` and `website/blog/` respectively.

## Tests & Validation

- Local: `npm start` to visually inspect pages; `npm run typecheck` to ensure TS correctness.
- CI: `website-build.yaml` workflow performs a production build and link-checks. Ensure PRs update docs without breaking the build.

## How to Make Docs Changes

1. Edit or add `.md`/`.mdx` files under `website/docs/`.
2. Run `npm run lint:all` and `npm run typecheck` locally.
3. Open a PR. Include a brief summary of changes and the pages affected.

## Code Style & Patterns

- Use MDX format for interactive documentation components
- Follow naming: kebab-case for files and directories (e.g., `getting-started.md`)
- Use frontmatter for page metadata (title, description, sidebar position)
- Reference existing docs for patterns: `website/docs/` structure
- Use relative links for internal navigation: `[text](../other-page.md)`
- Include code blocks with language tags for syntax highlighting
- Use Docusaurus components (Admonitions, Tabs) for rich content

## Boundaries

- Do not commit `website/build/` or other generated output.
- Do not add large binary assets to the repo; use external storage and reference by URL.

## Pre-Merge Checklist

Before merging documentation changes, verify:

- [ ] Site builds successfully: `npm run build` passes
- [ ] TypeScript type checking passes: `npm run typecheck`
- [ ] Markdown linting passes: `npm run lint:all`
- [ ] Local dev server shows changes correctly: `npm start`
- [ ] Internal links work and don't create 404s
- [ ] Code examples are tested and accurate
- [ ] Images are optimized and appropriately sized
- [ ] Frontmatter includes title and description
- [ ] Changes don't break existing navigation/sidebar
- [ ] No build artifacts committed (`website/build/`, `node_modules/`)

---

