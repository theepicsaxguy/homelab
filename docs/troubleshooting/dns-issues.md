## What Has Been Tested

### CoreDNS

- **Functionality Test:**
  - A dedicated test pod (`dns-check`/`dns-test`) used `nslookup` to query external domains (e.g. _google.com_ and
    _github.com_).
  - Internal service names (like `kubernetes.default.svc.kube.pc-tips.se`) resolved correctly.
- **Log Analysis:**
  - Logs showed repeated `i/o timeout` errors when CoreDNS attempted to reach an upstream IP (`169.254.116.108:53`).
- **Configuration Update:**
  - The CoreDNS ConfigMap was modified to forward external queries to `unbound.kube-system.svc.kube.pc-tips.se:53`
    instead of the host’s `/etc/resolv.conf`.

### Unbound

- **ConfigMap Adjustments:**
  - Updated to forward queries to external resolvers (Cloudflare 1.1.1.1 and Google 8.8.8.8).
  - Verbosity increased for better log detail.
- **Connectivity Tests:**
  - Direct tests using tools like `dig` from debug pods showed that queries against the Unbound service IP (e.g.
    10.99.162.170:53) timed out.
  - Attempts to query using pod IPs (e.g. 10.244.x.x) also resulted in timeouts.
- **Image & Security Context Changes:**
  - Initially tried using `mvance/unbound:latest` with adjusted security contexts.
  - Switched to using a more stable image (`docker.io/klutchell/unbound:1.19.0`), and later updated to
    `docker.io/mvance/unbound:1.21.1`.
  - Noted mixed states: some pods are running while one or more entered CrashLoopBackOff, and logs have remained empty.
- **Permissions Issue Identified:**
  - The Unbound containers were found to have startup issues likely related to file system permissions.
  - An init container was introduced to create the necessary directories and fix ownership (using BusyBox) so Unbound
    can write its configuration and log files.

### AdGuard

- **Configuration Update:**
  - Its upstream DNS settings were changed to point to the Unbound service (`unbound.kube-system:53`) instead of an
    incorrect static IP.

### Cilium & Network Policies

- **Cilium Policy Testing:**
  - A cluster-wide policy (`allow-dns-global`) was created to permit TCP/UDP traffic on port 53.
  - The initial FQDN matching in policies caused errors (“FQDN regex compilation LRU not yet initialized”) and was
    simplified.
- **Network Connectivity Verification:**
  - While CoreDNS and Unbound pods are scheduled across multiple nodes and appear healthy individually, connectivity
    tests revealed cross-node (pod-to-pod) communication issues.
  - Cilium health checks indicate that while host-to-host connectivity is working, endpoint connectivity across nodes
    times out—suggesting a potential network routing or VXLAN tunneling issue.

### Debugging Pods

- **Using Debug Pods:**
  - Several debug pods (e.g., using `nicolaka/netshoot` and BusyBox) were deployed to test DNS queries and network
    connectivity.
  - These pods confirmed that while internal Kubernetes service resolution is working (via CoreDNS), external DNS
    queries (routed through Unbound) are still timing out.

---

## What’s Left / Next Steps

### Unbound Service Improvements

- **Stabilize Unbound Pods:**
  - Resolve the CrashLoopBackOff issue so that all Unbound pods are running reliably with the updated image
    (`docker.io/mvance/unbound:1.21.1`).
  - Verify that the init container’s permission fixes take effect on all pods by checking file ownership and directory
    access inside the pods.
- **Log Verification:**
  - Once the pods are fully running, check Unbound logs to ensure the DNS process is starting and processing queries as
    expected.
- **Direct Query Testing:**
  - From a debug pod, re-run DNS queries (using both `nslookup` and `dig`) to confirm that external queries are
    processed successfully through the Unbound service.

### CoreDNS Confirmation

- **Reload and Monitor:**
  - Ensure that CoreDNS has reloaded the new configuration and is forwarding external queries to Unbound.
  - Continue monitoring its logs to verify that forwarded queries reach Unbound.

### Cilium & Network Connectivity

- **Cross-Node Connectivity:**
  - Investigate the cross-node connectivity issues flagged in the Cilium health checks.
  - Determine whether the VXLAN tunneling mode or specific Cilium policies are interfering with DNS traffic.
- **Temporary Policy Testing:**
  - As a diagnostic step, consider temporarily disabling Cilium policies to isolate whether they are blocking DNS
    traffic between pods on different nodes.
- **Cilium Logs and Metrics:**
  - Dive deeper into Cilium’s logs and metrics to identify any packet drops or routing issues that may be affecting
    pod-to-pod communication.

### GitOps and Deployment Verification

- **Commit Changes:**
  - Ensure that all configuration changes (Unbound deployment, ConfigMap updates, etc.) are committed to your GitOps
    repository so that ArgoCD can deploy the latest configuration.
- **Monitor Rollout:**
  - Monitor the rollout of the updated Unbound deployment to verify that all pods are updated and stable.
