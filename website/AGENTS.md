# Documentation Website - Domain Guidelines

SCOPE: Docusaurus documentation site and build system
INHERITS FROM: /AGENTS.md
TECHNOLOGIES: Docusaurus 3.9.2, TypeScript 5.9, React 19, Node.js 20.18+, npm 10.0+

**PREREQUISITE: You must have read /AGENTS.md before working in this domain.**

## DOMAIN CONTEXT

Purpose: Build and maintain documentation website for homelab, including architecture documentation, operational guides, and troubleshooting procedures.

Architecture:
- `website/docs/` - Documentation content organized by category
- `website/src/` - Custom React components and CSS
- `website/static/` - Static assets
- `website/docusaurus.config.ts` - Site configuration
- `website/sidebars.ts` - Documentation navigation structure

## QUICK-START COMMANDS

```bash
cd website

# Install dependencies
npm install

# Development server (hot reload)
npm start

# Type check and linting
npm run typecheck
npm run lint:all

# Build for production
npm run build

# Serve production build
npm run serve
```

## PATTERNS

### Content Structure
- Documentation files in `website/docs/` with `.md` or `.mdx` extension
- Use kebab-case for file and directory names
- Include frontmatter with title, description, sidebar_position
- Use relative links for internal navigation: `[text](../other-page.md)`

### Frontmatter Pattern
All documentation files include frontmatter with title, description for SEO, and sidebar_position for navigation ordering.

### Navigation Pattern
Update `sidebars.ts` to add new documentation pages. Use sidebar_position to control ordering. Group related pages under category sections.

### Linking Pattern
- Use relative links for internal navigation
- Use absolute URLs for external resources
- Never reference AGENTS.md files in documentation
- Only link to files in `website/docs/` directory
- Verify relative paths are correct before committing

## TESTING

- Local preview: `npm start` to visually inspect changes
- Type checking: `npm run typecheck` to ensure TypeScript correctness
- Linting: `npm run lint:all` for markdown and prose validation
- Requirements: Site builds successfully, TypeScript type checks, markdown lints, internal links work

## WORKFLOWS

**Development:**
- Create documentation files in `website/docs/`
- Add frontmatter with title, description, sidebar_position
- Test locally with `npm start`
- Lint with `npm run lint:all`
- Type check with `npm run typecheck`
- Update `sidebars.ts` if adding new pages

**Build & Deploy:**
- `npm run build` generates static site in `website/build/`
- CI builds site via `website-build.yaml` workflow
- Deploy to production on merge to main

## COMPONENTS

### Site Structure
- `src/components/` - Custom React components
- `src/css/` - Custom styles
- `src/data/` - Data files
- `src/pages/` - Custom pages

### Configuration
- `docusaurus.config.ts` - Site configuration
- `sidebars.ts` - Navigation structure
- `tsconfig.json` - TypeScript configuration
- `package.json` - Dependencies and scripts

## WEBSITE-DOMAIN ANTI-PATTERNS

### Build & Asset Management
- Never commit build artifacts (`website/build/`, `node_modules/`)
- Never add large binary assets - use external storage and link by URL
- Never use deprecated Docusaurus config options - follow current Docusaurus v4 API

### Content & Navigation
- Never break existing navigation or internal links
- Never reference AGENTS.md files from documentation
- Never use unescaped special characters in MDX content
- Never skip linting and type checking before committing

## REFERENCES

For commit format: /AGENTS.md
## Documentation Philosophy

### Learning Through Documentation
Documentation isn't just reference - it's where learning happens. Clear explanations of enterprise patterns transform implementation into education.

### Production Documentation Standards
Enterprise environments require:
- Comprehensive change documentation
- Architecture decision records (ADRs)
- Operational runbooks
- Recovery procedures

### Cross-Domain Sync Triggers
Documentation updates required when:
- **tofu changes**: Infrastructure documentation must reflect new patterns
- **k8s changes**: Application documentation must capture new workflows
- **images changes**: Container security documentation must update

### Enterprise Content Standards
- Every complex pattern needs explanation of "why"
- Every anti-pattern needs production consequence explanation
- Every workflow needs learning objective context

## REFERENCES

For documentation writing: website/docs/AGENTS.md
For Kubernetes concepts: k8s/AGENTS.md
For infrastructure: tofu/AGENTS.md
For Docusaurus: https://docusaurus.io/docs