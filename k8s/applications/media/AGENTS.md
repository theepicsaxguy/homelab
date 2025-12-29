# Media Applications - Category Guidelines

SCOPE: Media management, streaming, and content discovery applications
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: Jellyfin, Immich, arr-stack (Sonarr, Radarr, Prowlarr, Bazarr), Audiobookshelf, Audiobookrequest, Sabnzbd, WhisperASR

## CATEGORY CONTEXT

Purpose:
Deploy and manage media-related applications including media streaming, photo management, content automation, and download management.

Boundaries:
- Handles: Media streaming, content automation, photo management, download managers
- Does NOT handle: Home automation (see automation/), AI applications (see ai/), web utilities (see web/)
- Integrates with: network/ (Gateway API routes), storage/ (PVCs), auth/ (Authentik SSO)

## INHERITED PATTERNS

For general Kubernetes patterns, see k8s/AGENTS.md:
- Storage: proxmox-csi (new), longhorn (legacy)
- Network: Gateway API for external access
- Authentication: Authentik SSO where supported
- Database: CNPG for PostgreSQL with auto-generated credentials
- Backup: Velero for proxmox-csi, Longhorn labels for legacy
- Shared Storage: NFS PV for media libraries

## MEDIA-SPECIFIC PATTERNS

### Content Automation Pattern
arr-stack (Prowlarr, Sonarr, Radarr, Bazarr) automate content discovery, download, and organization. All arr services use shared NFS mount for media libraries. SQLite databases embedded in application PVCs.

### Photo Management Pattern
Immich uses multi-service architecture with CNPG PostgreSQL, Redis, and ML pod. Supports OAuth2 via Authentik. Dual backup: MinIO (local) + Backblaze B2 (offsite).

### Download Manager Pattern
Sabnzbd manages Usenet downloads with PVC for download storage. Uses proxmox-csi for better performance. ExternalSecrets for Usenet server credentials.

### Offline Content Pattern
WhisperASR caches AI models in PVC. Models can be re-downloaded if needed. No public access required.

## COMPONENTS

### Jellyfin
Media streaming server for movies, TV shows, and music. Uses StatefulSet with PVC for configuration and cache. Mounts NFS for media library. Gateway API route for external access.

### Immich
Self-hosted photo and video management with multi-service architecture. Uses CNPG PostgreSQL cluster with 2 instances, Redis for caching, and ML pod for AI features. Dual backup to MinIO and Backblaze B2 via CNPG.

### arr-stack
Automated content discovery and management. Prowlarr manages indexers. Sonarr handles TV series automation. Radarr manages movie automation. Bazarr automates subtitles. All services use shared NFS mount.

### Jellyseerr
Media request management system for movies and TV shows. Integration with arr-stack for automated fulfillment. Gateway API route for external access.

### Audiobookshelf
Self-hosted audiobook streaming and management. Uses PVC for audiobook library. Gateway API route for external access. Optional OAuth2 via Authentik.

### Audiobookrequest
Audiobook request management system with web interface. Uses MongoDB StatefulSet for backend. Gateway API route for external access.

### Sabnzbd
Usenet newsreader and download manager. Uses StatefulSet with PVC for download storage. Gateway API route for external access. ExternalSecrets for Usenet credentials.

### WhisperASR
Speech-to-text transcription using Whisper AI model. Caches models in PVC. CPU-only or GPU-based inference. Internal service, no external access.

## ANTI-PATTERNS

Never backup media libraries via Kubernetes. Media libraries backed up via TrueNAS/NFS separately.

Never use Longhorn for new media applications. Use proxmox-csi for better performance and automatic backups.

Never skip NFS mount for arr services. Shared NFS mount required for media access.

Never expose WhisperASR to public internet. Internal service only.

## REFERENCES

For Kubernetes domain patterns, see k8s/AGENTS.md

For network patterns (Gateway API), see k8s/infrastructure/network/AGENTS.md

For storage patterns, see k8s/infrastructure/storage/AGENTS.md

For CNPG database patterns (Immich), see k8s/infrastructure/database/AGENTS.md

For commit message format, see root AGENTS.md
