# ArgoCD ApplicationSets

The conductor of our Kubernetes orchestra! 🎵

## Overview

This directory contains the ApplicationSets that manage our entire GitOps deployment strategy. Think of it as the master
control panel for our homelab.

## Structure

```yaml
sets:
  infrastructure:
    wave: 1 # Bootstrap components first
    components:
      - network
      - storage
      - auth
      - monitoring

  applications:
    wave: 2 # Apps deploy after infra
    components:
      - media
      - development
      - external
```

## Sync Waves

| Wave | Purpose        | Components              | Timeout |
| ---- | -------------- | ----------------------- | ------- |
| 0    | CRDs           | Crossplane, Operators   | 5m      |
| 1    | Infrastructure | Network, Storage, Auth  | 10m     |
| 2    | Core Services  | Monitoring, Controllers | 10m     |
| 3    | Applications   | Media, Dev, External    | 15m     |

## Performance Features

- Progressive sync strategy
- Automated health checks
- Parallel processing where safe
- Resource pruning enabled

## Failure Handling

```yaml
retry:
  limit: 5
  backoff:
    duration: 5s
    factor: 2
    maxDuration: 3m
```

## Health Checks

- Kubernetes resources
- Custom health probes
- Dependency validation
- Network connectivity

## Usage

### Manual Sync

```bash
# Rarely needed thanks to GitOps!
argocd app sync -l argocd.argoproj.io/instance=apps
```

### Status Check

```bash
# View sync status
argocd app list
```

## Best Practices

1. Always use waves
2. Define clear dependencies
3. Set appropriate timeouts
4. Use labels consistently

## Troubleshooting

Common issues and solutions:

1. Sync Stuck

   - Check dependencies
   - Verify CRDs
   - Review logs

2. Health Check Failed
   - Check resource state
   - Verify network policies
   - Review pod logs

## Pro Tips

- Use `argocd app diff` before manual syncs
- Watch sync waves with `argocd app watch`
- Use `--cascade` carefully with deletions
- Keep your Git history clean

Remember: In GitOps we trust, but always keep a backup plan! 🎯
