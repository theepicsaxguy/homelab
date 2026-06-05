---
name: minecraft-plugin-updater
description: Check and update all Minecraft plugin URLs and build numbers in the homelab k8s plugin list. Use this skill whenever the user wants to update Minecraft plugins, check for outdated plugins, refresh plugin versions, or fix a broken plugin download URL. Triggers on phrases like "update plugins", "check plugin versions", "geyser is outdated", "update minecraft plugins", or any mention of a specific plugin being outdated.
---

# Minecraft Plugin Updater

Run the update script to check every plugin URL against its upstream API and rewrite `plugins.txt` with the latest versions.

## Usage

```bash
python3 scripts/update-plugins.py \
  /home/develop/homelab/k8s/applications/games/minecraft/plugins/plugins.txt
```

The script:
- Fetches the latest version/build from each plugin's upstream API
- Validates each new URL returns HTTP 200 before accepting it
- Rewrites `plugins.txt` in-place with updated URLs
- Prints a clear diff: what changed and what was already up to date
- Skips any plugin whose API is unreachable and warns instead of aborting

## After running

1. Review the printed diff to confirm the changes look right
2. Run `kustomize build --enable-helm /home/develop/homelab/k8s/applications/games/minecraft` to validate
3. Apply: `kubectl apply -k /home/develop/homelab/k8s/applications/games/minecraft`
4. Delete the pod to pick up the new configmap: `kubectl delete pod -n minecraft minecraft-bedrock-0`

## Plugin sources

| Plugin | Source |
|---|---|
| Geyser, Floodgate | GeyserMC downloads API |
| EssentialsX-GUI, FAWE, EssentialsX, Multiverse, Vault | GitHub Releases |
| LuckPerms | ci.lucko.me Jenkins |
| WildLoaders | hub.bg-software.com Jenkins |
| CustomCommands | Modrinth API |
| BedrockGUI (Spiget) | Static redirect — version not tracked |
