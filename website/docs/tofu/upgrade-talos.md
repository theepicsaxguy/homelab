---
title: 'Upgrade Talos Cluster Version Using Tofu'
---

This guide walks through how I safely upgrade my Talos Kubernetes cluster to a new version using Tofu. The process upgrades each node individually by setting `update = true`, and only updates the `version` once all nodes have been upgraded.

:::info
Never revert `update` to `false` before completing the upgrade across all nodes. Doing so will recreate that node using the older `version`.
:::

## Prerequisites

- `tofu` CLI installed and authenticated
- Existing Talos cluster deployed using Tofu and modules
- The desired Talos version defined in `update_version` under `image`
- Backup etcd snapshots or ensure application tolerance to node recreation

## Overview of workflow

1. Sequentially set `update = true` on each node, one at a time
2. Run `tofu apply` after each change to upgrade that node
3. After all nodes have `update = true` and are upgraded, change the `version` fields
4. Reset all `update` flags to `false`
5. Final `tofu apply` to persist the upgrade state

## Upgrade one node at a time

1. **Edit `main.tf`:** Set `update = true` for the *first* node.

   ```hcl
   "ctrl-00" = {
     ...
     update = true
   }

2. **Apply the change:**

   ```bash
   tofu apply
   ```

3. **Verify the node is back online and healthy:**

   ```bash
   talosctl -n 10.25.150.11 get machines
   ```

4. **Repeat steps 1–3 for the next node, adding `update = true` without modifying previous ones.**
   Do **not** set `update = false` on any already-upgraded nodes.

   Example after upgrading two nodes:

   ```hcl
   "ctrl-00" = {
     ...
     update = true
   }

   "ctrl-01" = {
     ...
     update = true
   }
   ```

5. **Continue until all nodes (control plane and worker) have `update = true`.**

## Finalize the version change

6. **Edit `main.tf` and set the permanent Talos version:**

   ```hcl
   image = {
     version        = "v1.10.2"
     update_version = "v1.10.2"
     ...
   }

   cluster = {
     ...
     talos_version = "v1.10.2"
   }
   ```

7. **Reset all nodes’ `update` flags back to `false`:**

   ```hcl
   "ctrl-00" = {
     ...
     update = false
   }
   ```

8. **Apply the final state:**

   ```bash
   tofu apply
   ```

## Verify the upgrade

1. **Check Talos version on each node:**

   ```bash
   talosctl version -n <node-ip>
   ```

   Output should show `v1.10.2` for every node.

2. **Verify Kubernetes nodes:**

   ```bash
   kubectl get nodes -o wide
   ```

   Confirm all nodes are `Ready` and on the expected version.

## Optional: Revert a node (rollback)

If you need to rollback a specific node before finalizing the version:

- Leave `version` untouched
- Set that node’s `update = false`
- Run `tofu apply`

This recreates the node using the `version`, effectively rolling it back.
