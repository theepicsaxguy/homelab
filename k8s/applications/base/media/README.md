# Media Applications Stack

Home entertainment done the hard way! 🎬

## Applications

### Jellyfin

- Open-source media streaming
- Hardware transcoding enabled
- Optimized for performance

### \*arr Stack

- Sonarr: TV series management
- Radarr: Movie management
- Prowlarr: Indexer management
- All configured for high availability

## Storage Configuration

```yaml
persistence:
  media:
    storageClass: 'fast-storage'
    size: '1Ti'
  metadata:
    storageClass: 'ssd-storage'
    size: '100Gi'
```

## Network Considerations

- Direct container storage access
- Optimized for local network streaming
- External access via Cloudflared

## Resource Allocation

| App      | CPU  | Memory | Storage |
| -------- | ---- | ------ | ------- |
| Jellyfin | 4C   | 4Gi    | 2Ti     |
| Sonarr   | 1C   | 1Gi    | 10Gi    |
| Radarr   | 1C   | 1Gi    | 10Gi    |
| Prowlarr | 500m | 512Mi  | 5Gi     |

## Security

- Zero-trust network model
- Authentication required
- No direct internet exposure
- Encrypted storage

## Performance Tweaks

1. Jellyfin:

   - GPU passthrough
   - Direct storage IO
   - Optimized transcoding paths

2. \*arr Stack:
   - Shared SQLite on SSD
   - Persistent connections
   - Cache optimizations

## Monitoring

- Media server metrics
- Transcode performance
- Storage utilization
- Network throughput

## Known Issues

1. Initial library scan CPU spikes

   - Mitigation: Resource limits
   - Status: Managed via HPA

2. SQLite contention
   - Mitigation: SSD storage
   - Status: Monitoring in place

## Future Plans

- [ ] Improved metadata caching
- [ ] Cross-node GPU sharing
- [ ] Advanced transcode queuing
- [ ] Library replication

May your buffers be full and your transcodes be swift! 🚀
