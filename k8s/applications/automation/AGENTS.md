# Automation Applications - Category Guidelines

SCOPE: Home automation, IoT, and workflow automation applications
INHERITS FROM: ../../AGENTS.md (and ../../../AGENTS.md)
TECHNOLOGIES: Home Assistant, Frigate, MQTT, Zigbee2MQTT, N8N, Hass.io

## INHERITANCE EXPLANATION

This file inherits from k8s/AGENTS.md and root AGENTS.md, which means:
- General Kubernetes patterns from k8s/AGENTS.md already apply (storage, ExternalSecrets, GitOps)
- Universal conventions from root AGENTS.md already apply (commits, PRs, documentation style)
- This file adds automation-specific patterns
- References to parent files are for additional details only

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
Zigbee coordinator runs in separate VM (not Kubernetes). No USB device passthrough in cluster. Zigbee2MQTT app in Kubernetes connects to coordinator over network, publishes to MQTT broker.

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
- Cilium <1.18 drops TCP listeners
- Workaround: Use HTTPRoute until upgrade to 1.18+
- Cilium 1.18+ resolves this issue

### Zigbee2MQTT

**Purpose**: Zigbee device coordinator and MQTT bridge.

**Deployment**:
- Deployment with single replica
- PVC for configuration and state
- USB device passthrough for Zigbee coordinator
- Gateway API route for external access (optional)
- ConfigMap for device configuration

**Configuration**:
- **ConfigMap**: Device configuration, groups, custom converters
- **ZB30.js**: Custom JavaScript converter for Zha-30 devices
- **MQTT Integration**: Publishes to MQTT broker

**Resources**:
- CPU: 1 core
- Memory: 512Mi
- Storage: 1Gi PVC (Longhorn, daily backup tier)
- USB Device: `/dev/ttyUSB0` passthrough

**External Secrets**: None required

### N8N

**Purpose**: Workflow automation and integration platform.

**Deployment**:
- StatefulSet with single replica
- CNPG PostgreSQL database (2 instances)
- PVC for N8N data
- Gateway API route for external access
- ExternalSecrets for database backups and OAuth2

**Database Configuration**:
- CNPG cluster with 2 instances
- Storage: 10Gi (Longhorn, daily backup tier)
- WAL Storage: 2Gi (Longhorn, daily backup tier)
- Plugins: barman-cloud.cloudnative-pg.io for backups
- Scheduled backups: Weekly to MinIO and Backblaze B2

**External Secrets**:
- `n8n-minio-credentials`: MinIO access keys
- `n8n-b2-cnpg-credentials`: Backblaze B2 access keys (2 separate entries)

**Resources**:
- CPU: 2 cores
- Memory: 2Gi
- Storage: 10Gi PVC for N8N data (proxmox-csi recommended)

**OAuth2**: Optional Authentik SSO integration

### Hass.io

**Purpose**: Home Assistant add-on manager for Hass.io platform.

**Deployment**:
- StatefulSet with single replica
- PVC for Hass.io configuration
- Gateway API route for external access
- ConfigMap for Hass.io configuration

**Configuration**:
- ConfigMap for Hass.io settings
- External access via Gateway API
- Authentication via Hass.io platform

**Resources**:
- CPU: 2 cores
- Memory: 2Gi
- Storage: 5Gi PVC (Longhorn, daily backup tier)

## INTEGRATION PATTERNS

### Home Automation Ecosystem

**Communication Flow**:
1. **Zigbee2MQTT**: Discovers Zigbee devices, publishes to MQTT
2. **MQTT**: Message broker for device communication
3. **Home Assistant**: Subscribes to MQTT, processes automation logic
4. **Frigate**: Ingests RTSP streams, publishes object detection to MQTT
5. **N8N**: Orchestrates cross-system workflows via MQTT

**MQTT Topics** (typical pattern):
- `zigbee2mqtt/<device_id>` - Device state updates
- `frigate/<camera>/object_detected` - AI detection events
- `homeassistant/<entity>` - Entity state changes

### Workflow Automation (N8N)

**Integration Points**:
- **MQTT**: Subscribe to device state changes
- **Home Assistant API**: Trigger automations, update entities
- **Frigate API**: Query detection events, configure cameras
- **Webhooks**: External integrations via HTTP endpoints

**Example Workflow**:
- MQTT receives motion event from Frigate
- N8N processes event, checks time of day
- N8N triggers Home Assistant automation via API
- Home Assistant executes automation (lights on, notification)

## BACKUP STRATEGY

### Critical Data (GFS Tier)

**Home Assistant**: GFS backup tier for configuration and database

**N8N**: Daily backup tier for workflow database and data

### Standard Applications (Daily Tier)

**MQTT, Zigbee2MQTT, Hass.io**: Daily backup tier for configuration

**Frigate**: No backup tier for recordings (can be regenerated)
- Configuration PVC: Daily backup tier
- Recordings PVC: No backup (optional, large storage)

### Non-Critical (No Backup)

**Caches and temporary data**: No backup labels

## TESTING

### Automation Application Validation

```bash
# Build automation applications
kustomize build --enable-helm k8s/applications/automation

# Validate specific application
kustomize build --enable-helm k8s/applications/automation/<app>

# Check application pods
kubectl get pods -n <namespace>

# Check application logs
kubectl logs -n <namespace> -l app=<app> -f

# Verify MQTT connectivity
kubectl exec -n mqtt -l app=mosquitto -- mosquitto_sub -h mqtt -t '#'

# Verify Zigbee device discovery
kubectl logs -n zigbee2mqtt -l app=zigbee2mqtt

# Check Home Assistant automations
kubectl exec -n home-assistant -l app=home-assistant -- ha --version
```

## OPERATIONAL PATTERNS

### Cilium TCP Listener Issue

**Problem**: Cilium <1.18 drops pure-TCP Gateway listeners
**Symptom**: MQTT TCP route not working
**Workaround**:
- Use HTTPRoute for MQTT until Cilium upgrade
- Remove workaround after upgrading to Cilium 1.18+

**Fix**: Upgrade Cilium to 1.18 or later

### Device Passthrough

No USB device passthrough in Kubernetes. Zigbee2MQTT coordinator runs in separate VM (not in Kubernetes). Kubernetes Zigbee2MQTT application connects to coordinator over network interface only.

**Frigate Coral Accelerator**:
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
