# Automation Applications - Category Guidelines

SCOPE: Home automation, IoT, and workflow automation applications
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: Home Assistant, Frigate, MQTT, Zigbee2MQTT, N8N, Hass.io

## CATEGORY CONTEXT

Purpose: Deploy and manage home automation applications including smart home control, IoT device management, video surveillance, and workflow automation.

## INHERITED PATTERNS

For general Kubernetes patterns, see k8s/AGENTS.md:
- Storage: proxmox-csi (new), longhorn (legacy)
- Network: Gateway API for external access
- Authentication: Authentik SSO where supported
- Database: CNPG for PostgreSQL, auto-generated credentials
- Backup: Velero for proxmox-csi, Longhorn labels for legacy

## AUTOMATION-SPECIFIC PATTERNS

### MQTT Pattern
- Internal-only message broker for IoT communication
- All automation apps communicate via MQTT topics
- No external access required
- TCP route with Cilium 1.18+ required for full protocol support

### Zigbee2MQTT Pattern
- Zigbee coordinator (USB device) runs in separate VM (not Kubernetes)
- Kubernetes Zigbee2MQTT app connects to coordinator over network interface only
- Publishes to MQTT broker

### RTSP Stream Pattern
- Frigate ingests camera feeds via RTSP
- RTSP credentials managed via ExternalSecrets
- No public RTSP exposure

### Workflow Orchestration Pattern
- N8N orchestrates cross-system workflows via MQTT and HTTP APIs
- Uses CNPG PostgreSQL database with auto-generated credentials

## APPLICATION-SPECIFIC GUIDANCE

### Home Assistant
**Purpose**: Central smart home automation hub

**Deployment**:
- Hass.io add-on (not standard container)
- PVC for Home Assistant configuration and database
- Gateway API route for external access
- OAuth2 via Authentik for SSO
- ConfigMap for additional configuration

**Architecture**:
- Main Container: Home Assistant application
- ConfigMount: ConfigMap for customization
- Database: SQLite embedded in PVC
- Authentication: Authentik OpenID Connect
- Seed Configuration: InitContainer conditionally copies automations, scripts, scenes, lovelace from ConfigMap

**Seed Configuration**:
The initContainer manages HA-managed configuration files via the `HA_SEED_ON_STARTUP` environment variable:
- `"true"`: Always overwrite files from ConfigMap (useful for force-reset)
- `"false"` or unset: Only copy if files don't exist, allowing Home Assistant to manage its own files

**Resources**: CPU: 2 cores, Memory: 2Gi, Storage: 10Gi PVC

**External Secrets**: `ha_oidc_client_id`, `ha_oidc_client_secret` (Authentik OAuth2)

### Frigate
**Purpose**: Video surveillance with AI object detection

**Deployment**:
- Helm chart deployment (BlakeBlackshear fork)
- PVC for recordings and database
- Gateway API route for web UI
- RTSP stream access for camera ingestion
- Optional GPU support for faster inference

**Hardware Acceleration**:
- NVIDIA GPU: GPU passthrough for faster inference (optional)
- CPU-only: Default mode, slower inference

**Resources**: CPU: 4+ cores, Memory: 4-8Gi, Storage: 50Gi+ PVC, GPU: Optional 1 GPU

**External Secrets**: `frigate-rtsp-credentials` (RTSP username/password)

**Storage Labels**: Daily tier for recordings (no backup for video)

### MQTT
**Purpose**: Message broker for IoT communication

**Deployment**:
- StatefulSet with single replica
- PVC for persistent data
- Gateway API route for external access (optional)
- ExternalSecrets for authentication
- TCP route for MQTT protocol (Cilium 1.18+ required)
- Internal-only communication preferred

**Resources**: CPU: 1 core, Memory: 512Mi, Storage: 1Gi PVC

**Cilium TCP Listener Issue**: See `/k8s/infrastructure/network/AGENTS.md` for details

### Device Passthrough
- No USB device passthrough in Kubernetes
- Zigbee2MQTT coordinator (USB device) runs in separate VM
- Kubernetes Zigbee2MQTT application connects to coordinator over network interface only

### IoT Device Management
**Zigbee2MQTT Device Discovery**:
1. Edit `config/devices.yaml` to add new devices
2. Apply ConfigMap update via GitOps
3. Restart Zigbee2MQTT pod to load new configuration
4. Verify device joins network

**Frigate Camera Configuration**:
1. Edit Helm values file for camera RTSP credentials
2. Update ExternalSecret for RTSP authentication
3. Apply via GitOps
4. Verify camera ingestion in Frigate UI

## AUTOMATION-DOMAIN ANTI-PATTERNS

### Security & Access
- Never expose MQTT to public internet without authentication - use Authentik SSO or restrict to internal only
- Never expose Frigate RTSP streams to public internet - keep internal-only or restrict to trusted networks
- Never skip USB device passthrough for Zigbee coordinator - device cannot function without access to `/dev/ttyUSB0`

### Storage & Data Management
- Never backup video recordings from Frigate - recordings can be regenerated and consume significant storage
- Never use Longhorn for new automation applications - use proxmox-csi for better performance and automatic backups
- Never skip database backup configuration for N8N - configure CNPG backups for workflow data

## REFERENCES

For Kubernetes domain patterns: k8s/AGENTS.md
For network patterns (Gateway API): k8s/infrastructure/network/AGENTS.md
For storage patterns: k8s/infrastructure/storage/AGENTS.md
For authentication patterns (Authentik): k8s/infrastructure/auth/authentik/AGENTS.md
For CNPG database patterns: k8s/infrastructure/database/AGENTS.md
For commit format: /AGENTS.md