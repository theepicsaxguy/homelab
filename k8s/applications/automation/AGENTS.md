# Automation Applications - Category Guidelines

SCOPE: Home automation, IoT, and workflow automation applications
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: Home Assistant, Frigate, MQTT, Zigbee2MQTT, N8N, Hass.io

## CATEGORY CONTEXT

Purpose:
Deploy and manage home automation applications including smart home control, IoT device management, video surveillance, and workflow automation.

Boundaries:
- Handles: Home automation, IoT coordination, video surveillance, workflow orchestration
- Does NOT handle: Media services (see media/), AI applications (see ai/)
- Integrates with: network/ (Gateway API), auth/ (Authentik SSO), storage/ (PVCs)

## INHERITED PATTERNS

For general Kubernetes patterns, see k8s/AGENTS.md:
- Storage: proxmox-csi (new), longhorn (legacy)
- Network: Gateway API for external access
- Authentication: Authentik SSO where supported
- Database: CNPG for PostgreSQL, auto-generated credentials
- Backup: Velero for proxmox-csi, Longhorn labels for legacy

## AUTOMATION-SPECIFIC PATTERNS

### MQTT Pattern
Internal-only message broker for IoT communication. All automation apps communicate via MQTT topics. No external access required. TCP route with Cilium 1.18+ required for full protocol support.

### Zigbee2MQTT Pattern
Zigbee coordinator (USB device) runs in separate VM (not Kubernetes). Kubernetes Zigbee2MQTT app connects to coordinator over network interface only, publishes to MQTT broker.

### RTSP Stream Pattern
Frigate ingests camera feeds via RTSP. RTSP credentials managed via ExternalSecrets. No public RTSP exposure.

### Workflow Orchestration Pattern
N8N orchestrates cross-system workflows via MQTT and HTTP APIs. Uses CNPG PostgreSQL database with auto-generated credentials.

## APPLICATION-SPECIFIC GUIDANCE

### Home Assistant

**Purpose**: Central smart home automation hub.

**Deployment**:
- Hass.io add-on (not standard container)
- PVC for Home Assistant configuration and database
- Gateway API route for external access
- OAuth2 via Authentik for SSO
- ConfigMap for additional configuration

**Architecture**:
- **Main Container**: Home Assistant application
- **ConfigMount**: ConfigMap for customization
- **Database**: SQLite embedded in PVC
- **Authentication**: Authentik OpenID Connect

**Configuration Structure**:
- **Main Config**: `configuration.yaml` in ConfigMap
- **Secrets**: Secrets referenced via `!secret` directive
- **Includes**: Automations, scripts, scenes, components
- **Integrations**: Loaded from subdirectories

**Resources**:
- CPU: 2 cores
- Memory: 2Gi
- Storage: 10Gi PVC (Longhorn, GFS backup tier)

**External Secrets**:
- `ha_oidc_client_id`: Authentik OAuth2 client ID
- `ha_oidc_client_secret`: Authentik OAuth2 client secret

**Cilium Workaround**: If using Cilium <1.18, apply HTTPRoute workaround for MQTT.

### Frigate

**Purpose**: Video surveillance with AI object detection.

**Deployment**:
- Helm chart deployment (BlakeBlackshear fork)
- PVC for recordings and database
- Gateway API route for web UI
- RTSP stream access for camera ingestion
- Optional GPU or Coral accelerator support

**Configuration**:
- Helm values file for Frigate settings
- Environment variables for camera credentials
- ConfigMap for custom configuration
- ExternalSecrets for RTSP credentials

**Hardware Acceleration**:
- **Coral**: USB device passthrough for AI inference (optional)
- **NVIDIA GPU**: GPU passthrough for faster inference (optional)
- **CPU-only**: Default mode, slower inference

**Resources**:
- CPU: 4+ cores (for object detection)
- Memory: 4-8Gi
- Storage: 50Gi+ PVC for recordings (proxmox-csi recommended)
- GPU: Optional, 1 GPU if available

**External Secrets**:
- `frigate-rstp-credentials`: RTSP username/password (from envFromSecrets)

**Storage Labels**: Daily tier for recordings (no backup for video)

### MQTT

**Purpose**: Message broker for IoT communication.

**Deployment**:
- StatefulSet with single replica
- PVC for persistent data
- Gateway API route for external access (optional)
- ExternalSecrets for authentication

**Configuration**:
- ConfigMap for MQTT broker settings
- ExternalSecrets for username/password
- TCP route for MQTT protocol (Cilium 1.18+ required)
- No external access required (internal-only)

**Resources**:
- CPU: 1 core
- Memory: 512Mi
- Storage: 1Gi PVC (Longhorn, daily backup tier)

**Cilium TCP Listener Issue**:
For details and workaround, see /k8s/infrastructure/network/AGENTS.md.

### Device Passthrough

No USB device passthrough in Kubernetes. Zigbee2MQTT coordinator (USB device) runs in separate VM. Kubernetes Zigbee2MQTT application connects to coordinator over network interface only.

**Frigate Coral Accelerator** (if applicable):
- USB Coral device for AI inference (optional)
- If used, passed through from host: `/dev/bus/usb`
- Verify device availability on node
- Check pod logs for device detection

### IoT Device Management

**Zigbee2MQTT Device Discovery**:
- Edit `config/devices.yaml` to add new devices
- Apply ConfigMap update via GitOps
- Restart Zigbee2MQTT pod to load new configuration
- Verify device joins network

**Frigate Camera Configuration**:
- Edit Helm values file for camera RTSP credentials
- Update ExternalSecret for RTSP authentication
- Apply via GitOps
- Verify camera ingestion in Frigate UI

## ANTI-PATTERNS

Never expose MQTT to public internet without authentication. Use Authentik SSO or restrict to internal only.

Never skip USB device passthrough for Zigbee coordinator. Device cannot function without access to `/dev/ttyUSB0`.

Never backup video recordings from Frigate. Recordings can be regenerated and consume significant storage.

Never use Longhorn for new automation applications. Use proxmox-csi for better performance and automatic backups.

Never skip database backup configuration for N8N. Configure CNPG backups for workflow data.

Never expose Frigate RTSP streams to public internet. Keep internal-only or restrict to trusted networks.

## REFERENCES

For Kubernetes domain patterns, see k8s/AGENTS.md

For network patterns (Gateway API), see k8s/infrastructure/network/AGENTS.md

For storage patterns, see k8s/infrastructure/storage/AGENTS.md

For authentication patterns (Authentik), see k8s/infrastructure/auth/authentik/AGENTS.md

For CNPG database patterns, see k8s/infrastructure/database/AGENTS.md

For commit message format, see root AGENTS.md
