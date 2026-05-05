---
name: cilium-hubble
description: Check Cilium network policy drops and flow visibility using Hubble. Use when the user asks whether a namespace or workload is being blocked by Cilium, wants to inspect dropped flows, or needs to verify that Cilium network policies are allowing expected traffic (e.g. "is redis blocked?", "check if litellm can reach qdrant", "why can't app A talk to app B?", "check cilium hubble for namespace X").
---

# Cilium Hubble Flow Check

## Workflow

1. Run `scripts/hubble-check.sh <namespace> [namespace2 ...]`
2. Inspect the output in order:
   - **Hubble status** — confirms relay is reachable and all nodes are connected. If `Connected Nodes` is less than total nodes, results may be incomplete.
   - **Dropped flows** — policy-denied traffic. Empty output is only trustworthy if the sanity check below shows real flows.
   - **Recent flows (sanity check)** — confirms Hubble is actually returning data for that namespace. If this is also empty, the namespace may have no recent traffic or the query is wrong — do not conclude "no drops" without investigating.

## Key rules

- Always verify Hubble status before trusting empty DROPPED results. An empty result from a disconnected relay is a false negative.
- If the sanity-check recent flows are also empty, check that the namespace name is correct and that pods are running.
- For cross-namespace connectivity (app A → app B), run the check on both namespaces and look for DROPPED flows on the destination side.
- Hubble stores a rolling flow buffer. For intermittent issues, increase `--last` or add `--since 5m`.

## Manual commands (when not using the script)

```bash
# Port-forward relay (run in background)
kubectl -n kube-system port-forward svc/hubble-relay 4245:80 &

# Status
hubble status

# Dropped flows
hubble observe --namespace <ns> --verdict DROPPED --last 100

# All flows (sanity check)
hubble observe --namespace <ns> --last 10
```
