# Web Applications - Category Guidelines

SCOPE: Web-based productivity and utility applications
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: BabyBuddy, Pinepods, HeadlessX, Kiwix, Pedrobot

## CATEGORY CONTEXT

Purpose:
Deploy and manage web-based applications for personal productivity, podcast management, offline content access, and bot services.

Boundaries:
- Handles: Web applications for personal use
- Does NOT handle: Media services (see media/), automation (see automation/)
- Integrates with: network/ (Gateway API), storage/ (PVCs), auth/ (Authentik SSO)

## INHERITED PATTERNS

For general Kubernetes patterns, see k8s/AGENTS.md:
- Storage: proxmox-csi (all new web applications)
- Network: Gateway API for external access
- Authentication: Authentik SSO where supported
- Database: CNPG for PostgreSQL with auto-generated credentials
- Backup: Velero automatic backups for proxmox-csi PVCs
- Large Storage: Exclude from backups if re-downloadable (Kiwix)

## WEB-SPECIFIC PATTERNS

### Browser Automation Pattern
HeadlessX runs headless browser tasks with network policy restrictions for security. Requires OAuth2 via Authentik. Isolated namespace for security.

### Podcast Management Pattern
Pinepods uses CNPG PostgreSQL with Valkey (Redis-compatible) for caching. Supports OAuth2 via Authentik. Large PVC for podcast data with dual backup to MinIO and Backblaze B2.

### Offline Content Pattern
Kiwix stores large offline content (Wikipedia ZIM files, 200GB+). Exclude from Velero backups via pod annotation. Content can be re-downloaded.

### Bot Service Pattern
Pedrobot uses MongoDB StatefulSet (not CNPG). External secrets for bot API credentials. No OAuth2 support.

## COMPONENTS

### BabyBuddy
Baby tracking application for infant care logging. Uses StatefulSet with PVC for application data and SQLite database. OAuth2 via Authentik for SSO.

### Pinepods
Self-hosted podcast management and synchronization. Uses CNPG PostgreSQL cluster (2 instances) with Valkey for caching. Large PVC for podcast data. Optional OAuth2 via Authentik. Dual backup to MinIO and Backblaze B2.

### HeadlessX
Browser automation service for headless browser tasks. Uses Deployment with PVC for browser profile and data. Network policy restricts egress to required domains only. OAuth2 via Authentik for SSO. Isolated namespace for security.

### Kiwix
Offline Wikipedia and content reader. Uses Deployment with large PVC for offline content (200GB+ Wikipedia). No external authentication required. Exclude from Velero backups due to size. Content can be re-downloaded.

### Pedrobot
Bot service for Discord. Uses MongoDB StatefulSet for backend. External secrets for bot API credentials. No OAuth2 support.

## ANTI-PATTERNS

Never backup Kiwix content via Velero. Exclude via annotation as content can be re-downloaded.

Never skip network policy for HeadlessX. Restrict egress to required domains only.

Never use Longhorn for new web applications. Use proxmox-csi for automatic backups.

Never expose Pedrobot to public internet without rate limiting.

## REFERENCES

For Kubernetes domain patterns, see k8s/AGENTS.md

For network patterns (Gateway API), see k8s/infrastructure/network/AGENTS.md

For storage patterns, see k8s/infrastructure/storage/AGENTS.md

For CNPG database patterns (Pinepods), see k8s/infrastructure/database/AGENTS.md

For commit message format, see root AGENTS.md
