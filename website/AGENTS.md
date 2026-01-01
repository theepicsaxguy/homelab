# Documentation Website - Domain Guidelines

SCOPE: Docusaurus documentation site and build system
INHERITS FROM: /AGENTS.md
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
- **Broken link handling**: Use `markdown.hooks.onBrokenMarkdownLinks` instead of deprecated `onBrokenMarkdownLinks` (Docusaurus v4 compatibility)

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

### Frontmatter Pattern
All documentation files include frontmatter with title, description for SEO, and sidebar_position for navigation ordering. Frontmatter begins and ends with triple hyphens.

### Navigation Pattern
Update `sidebars.ts` to add new documentation pages to navigation. Use sidebar_position to control ordering. Group related pages under category sections.

### Linking Pattern
Use relative links for internal navigation. Use absolute URLs for external resources. Test all links before committing.

**Linking rules**:
- Never reference AGENTS.md files in documentation - these are for coding agents only
- Only link to files in `website/docs/` directory
- Use relative paths like `[text](../other-page.md)` for internal docs
- Verify links resolve to existing files before committing

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
- Add frontmatter with title, description, sidebar_position
- Write content following guidelines in website/docs/AGENTS.md
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

Never skip linting and type checking before committing.

Never add large binary assets to repository. Use external storage and link by URL.

Never break existing navigation or internal links.

Never use deprecated Docusaurus config options. Follow current Docusaurus v4 API.

Never reference AGENTS.md files from documentation - AGENTS.md are for AI coding guidance only.

Never use unescaped special characters in MDX content (e.g., `<`, `>`, `&`). Use JSX expressions or HTML entities when needed.

## CRITICAL BOUNDARIES

Never commit `website/build/` or `node_modules/` directories.

Never add secrets or credentials to documentation files.

Never commit large binary assets. Use external storage and reference by URL.

Never skip `npm run lint:all` and `npm run typecheck` before committing.

Never break existing navigation or internal links.

## REFERENCES

For commit message format, see root AGENTS.md

For documentation writing guidelines, see website/docs/AGENTS.md

For Kubernetes concepts, see k8s/AGENTS.md

For infrastructure concepts, see tofu/AGENTS.md

For Docusaurus documentation, see https://docusaurus.io/docs
