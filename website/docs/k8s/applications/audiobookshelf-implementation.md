---
title: 'Audiobookshelf Deployment Notes'
---

Audiobookshelf runs as a StatefulSet in the media namespace. It manages audiobooks and podcasts with persistent metadata
storage.

## Image

The deployment uses the official `ghcr.io/advplyr/audiobookshelf:latest` image. The container listens on port 80.

## Configuration

Audiobookshelf stores its configuration in `/config` on a Longhorn PersistentVolumeClaim. The application manages its
own configuration through the web interface.

## Storage

Storage is split across three volume types:

- `/config` uses a 5 Gi Longhorn PVC for application configuration and database
- `/metadata` uses a 20 Gi Longhorn PVC for book covers, metadata cache, and transcoded audio files
- `/audiobooks` and `/podcasts` mount subdirectories from the shared `media-share` NFS volume at
  `audiobookshelf/audiobooks` and `audiobookshelf/podcasts` respectively

The NFS share provides ReadWriteMany access so media files remain accessible to multiple pods and can be managed
externally. Longhorn PVCs persist through pod restarts. `/tmp` stays ephemeral for scratch space.

## Network

The service exposes port 13378 externally while targeting the container port 80. HTTPRoute provides both internal and
external gateway access at `audiobookshelf.peekoff.com`.

## Security

The pod runs as user 2501 (matching other media applications) with:

- `runAsNonRoot: true`
- `readOnlyRootFilesystem: true`
- `seccompProfile: RuntimeDefault`
- All capabilities dropped

File system group ownership uses `fsGroup: 2501` with `OnRootMismatch` policy for efficient permission handling.

## Upgrades

Update the image tag in the StatefulSet manifest. The volumeClaimTemplates ensure configuration and metadata persist
across updates.

## Debug

Use `kubectl logs` to view application logs or `kubectl exec` for interactive access.
