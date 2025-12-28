# Documentation Website - Domain Guidelines

SCOPE: Docusaurus documentation site and build system
INHERITS FROM: ../AGENTS.md
TECHNOLOGIES: Docusaurus 3.9.2, TypeScript 5.9, React 19, Node.js 20.18+, npm 10.0+

## DOMAIN CONTEXT

Purpose:
Build and maintain the documentation website for the homelab, including architecture documentation, operational guides, and troubleshooting procedures.

Boundaries:
- Handles: Documentation source files (Markdown/MDX), Docusaurus configuration, site assets, build system
- Does NOT handle: Kubernetes manifests (see k8s/), infrastructure provisioning (see tofu/)
- Integrates with: Root repository for documentation updates

Architecture:
- `website/docs/` - Documentation content organized by category
- `website/src/` - Custom React components and CSS
- `website/static/` - Static assets (images, robots.txt, favicon)
- `website/docusaurus.config.ts` - Site configuration
- `website/sidebars.ts` - Documentation navigation structure

## QUICK-START COMMANDS

```bash
cd website

# Install dependencies
npm install

# Start development server (hot reload)
npm start

# Type check TypeScript
npm run typecheck

# Lint markdown and prose
npm run lint:all

# Build for production
npm run build

# Serve production build
npm run serve
```

## TECHNOLOGY CONVENTIONS

### Docusaurus Configuration
- Configuration in `docusaurus.config.ts` (TypeScript)
- Preset: `@docusaurus/preset-classic`
- Plugins: Local search, sitemap, MDX support
- Static generation: All pages pre-rendered at build time

### Content Structure
- Documentation files in `website/docs/` with `.md` or `.mdx` extension
- Use kebab-case for file and directory names
- Include frontmatter with title, description, sidebar_position
- Use relative links for internal navigation: `[text](../other-page.md)`

### React Components
- TypeScript for type safety
- React 19 with hooks for interactive components
- Component files in `website/src/components/`
- Use clsx for conditional class names

### Styling
- CSS files in `website/src/css/`
- Custom theme overrides in Docusaurus config
- Use Tailwind or custom CSS as needed

## PATTERNS

### Documentation Pattern
Write technical documentation in imperative voice with present tense facts. No first-person plural ("we"), no temporal language ("now uses"), no narrative storytelling. State what exists and how it works.

### Frontmatter Pattern
All documentation files include frontmatter with metadata:
```yaml
---
title: Page Title
description: Brief description for SEO
sidebar_position: 10
---
```

### Navigation Pattern
Update `sidebars.ts` to add new documentation pages to navigation. Use sidebar_position to control ordering. Group related pages under category sections.

### Linking Pattern
Use relative links for internal navigation. Use absolute URLs for external resources. Test all links before committing.

### Code Block Pattern
Include code blocks with language tags for syntax highlighting. Test code examples. Provide context and expected output where appropriate.

## TESTING

Strategy:
- Local preview: `npm start` to visually inspect changes
- Type checking: `npm run typecheck` to ensure TypeScript correctness
- Linting: `npm run lint:all` for markdown and prose validation
- Link checking: CI checks for dead links during build

Requirements:
- Site must build successfully: `npm run build`
- TypeScript must type check without errors
- Markdown must pass linting (remark, markdownlint, Vale)
- All internal links must work
- Images must load correctly

Tools:
- npm scripts: Build, test, and lint commands
- Docusaurus dev server: Hot reload preview
- TypeScript compiler: Type checking
- remark: Markdown linting
- Vale: Prose linting
- markdownlint: Markdown style checking

## WORKFLOWS

Development:
- Create documentation files in `website/docs/` with `.md` or `.mdx` extension
- Add frontmatter with metadata
- Write content following documentation style guide
- Include code blocks with language tags
- Test locally: `npm start` to preview changes
- Lint: `npm run lint:all` to check prose and markdown
- Type check: `npm run typecheck` to verify TypeScript
- Update `sidebars.ts` if adding new pages

Build:
- `npm run build` generates static site in `website/build/`
- Build process includes asset optimization and bundling
- Generated files are not committed to Git

Deployment:
- CI builds site via `website-build.yaml` workflow
- Deploy to production (Netlify/Vercel) on merge to main
- Domain configuration in deployment platform

## COMPONENTS

### Documentation Categories
- `getting-started/` - Onboarding and setup guides
- `k8s/` - Kubernetes documentation (applications, infrastructure)
- `tofu/` - OpenTofu infrastructure documentation
- `backup/` - Backup and recovery procedures
- `infrastructure/` - Infrastructure component documentation
- `troubleshooting/` - Common issues and solutions
- `contributing/` - Contribution guidelines

### Site Components
- `src/components/` - Custom React components
- `src/css/` - Custom styles
- `src/data/` - Data files (used by components)
- `src/pages/` - Custom pages (index, etc.)

### Configuration
- `docusaurus.config.ts` - Site configuration
- `sidebars.ts` - Navigation structure
- `tsconfig.json` - TypeScript configuration
- `package.json` - Dependencies and scripts

## ANTI-PATTERNS

Never commit generated build artifacts (`website/build/`, `node_modules/`).

Never use first-person plural ("we", "our") in documentation.

Never use temporal language ("now", "recently", "has been updated") in documentation.

Never break existing links without updating all references.

Never commit untested code examples without running them.

Never skip linting and type checking before committing.

Never add large binary assets to repository. Use external storage and link by URL.

## DOCUMENTATION STYLE

### Voice and Tense
- Use imperative voice for instructions: "Configure the setting", "Run the command"
- Use present tense for facts: "The system uses X", "Kopia uploads data to S3"
- State what exists and how it works, not how it was created

### What to Avoid
- No first-person plural: "We use", "We investigated"
- No temporal language: "Now uses", "Has been updated"
- No narrative storytelling: "We explored X and found that..."
- No status updates: "The system now supports..."

### Comments in Code Files
- State what the setting does, not why you chose it
- Bad: `# We use Kopia because snapshots didn't work`
- Good: `# Kopia filesystem backup to S3`
- When comparison is relevant: Good: `# instead of CSI snapshots`

## CRITICAL BOUNDARIES

Never commit `website/build/` or `node_modules/` directories.

Never add secrets or credentials to documentation files.

Never commit large binary assets. Use external storage and reference by URL.

Never skip `npm run lint:all` and `npm run typecheck` before committing.

Never break existing navigation or internal links.

## REFERENCES

For commit message format, see root AGENTS.md

For Kubernetes concepts, see k8s/AGENTS.md

For infrastructure concepts, see tofu/AGENTS.md

For Docusaurus documentation, see https://docusaurus.io/docs

For TypeScript, see TypeScript documentation
