# Changelog

## 4.0.0 (2025-12-17)

## What's Changed
* Fix(configmap,-webui)--update-qdrant-semantic-cache-embedding-model-to-@cf/qwen/qwen3-embedding-0.6b by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1766
* fix(configmap): add qdrant vector size to configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1767
* chore(deps): update portkeyai/gateway docker tag to v1.14.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1769
* chore(deps): update portkeyai/gateway docker tag to v1.14.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1771
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.11.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1772
* chore(infra): reduce unnecessary HA configurations for homelab by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1765
* Enable per-user spend tracking for LiteLLM via Open WebUI headers by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1773
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1761
* feat(openwebui): add general tools and document search pipelines by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1774
* chore(deps): bump actions/checkout from 5 to 6 by @dependabot[bot] in https://github.com/theepicsaxguy/homelab/pull/1770
* Update document_search_pipeline.py by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1776
* Add writable volume mount for /app/pipelines to fix pipeline loading by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1775
* Fix Python 3.8 syntax errors and missing Pipeline class in document_search_pipeline.py by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1777
* fix(k8s/openwebui): add persistent storage and API key for pipelines by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1778
* Package pipeline files via ConfigMap instead of downloading from GitHub URLs by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1779
* chore(deps): update helm release argo-cd to v9.1.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1780
* chore(deps): update busybox docker tag to v1.37 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1781
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.37 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1782
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.38 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1783
* chore(deps): update getmeili/meilisearch docker tag to v1.27.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1785
* chore(deps): update mcr.microsoft.com/playwright docker tag to v1.57.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1787
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.40 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1786
* chore(deps): update qdrant/qdrant docker tag to v1.16.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1788
* chore(deps): update all dependencies to v79.8.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1789
* chore(deps): update all dependencies to v79.8.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1790
* chore(deps): update all dependencies to v79.8.2 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1791
* chore(deps): update portkeyai/gateway docker tag to v1.14.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1792
* feat(tofu): make load balancer deployment optional and disabled by default

Add enable_lb feature flag to control load balancer deployment. This prevents
tofu plan from prompting for lb-related variables when load balancer is not needed.

Changes:
- Add enable_lb variable (defaults to false)
- Make lb_nodes, auth_pass, and lb_store optional with sensible defaults
- Use count in lb module to conditionally deploy based on enable_lb flag

To enable load balancer deployment, set enable_lb = true in your .tfvars file.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com> by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1794
* Update nodes.auto.tfvars by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1793
* feat(tofu): set CPU units default to 1024 for all nodes

Add cpu_units configuration with default value of 1024 to prevent Proxmox
from changing CPU units to 100 during VM updates. This ensures consistent
CPU scheduling across control plane and worker nodes.

Changes:
- Add cpu_units field to defaults_worker and defaults_controlplane with default 1024
- Add cpu_units to nodes_config variable type for per-node override capability
- Update virtual-machines.tf cpu block to use cpu_units with fallback to 1024

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com> by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1795
* feat(k8s/ai): add OpenHands AI coding agent with LiteLLM integration by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1796
* chore(deps): update all dependencies to v24 (major) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1735
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1798
* chore(deps): update dependency externalsecret to external-secrets.io/v1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1797
* chore(deps): update all dependencies (major) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1799
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1800
* chore(deps): update all dependencies to v79.9.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1801
* chore(deps): update ghcr.io/karakeep-app/karakeep docker tag to v0.29.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1802
* chore(deps): update helm release argo-cd to v9.1.5 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1803
* chore(deps): update terraform proxmox to v0.88.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1804
* chore(deps): update ghcr.io/jellyfin/jellyfin docker tag to v10.11.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1806
* feat(authentik): require SSL mode for PostgreSQL connectiona by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1805
* chore(deps): update getmeili/meilisearch docker tag to v1.28.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1807
* chore(deps): update getmeili/meilisearch docker tag to v1.28.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1808
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1809
* chore(deps): update helm release crossplane to v2.1.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1810
* chore(deps): update helm release crossplane to v2.1.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1811
* chore(config): update cache settings and add responses API documentation by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1812
* chore(deps): update all dependencies to v79.11.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1813
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.41 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1814
* chore(deps): update getmeili/meilisearch docker tag to v1.28.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1815
* chore(deps): update ghcr.io/karakeep-app/karakeep docker tag to v0.29.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1817
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1818
* Add OpenCode application deployment to k8s/applications/ai by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1816
* fix(opencode): add emptyDir volume for /home/node/.local to fix read-… by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1819
* chore(deps): update helm release argo-cd to v9.1.6 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1820
* chore(kustomization): comment out unused resources in kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1821
* chore(deps): update qdrant/qdrant docker tag to v1.16.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1822
* chore(deps): update helm release gpu-operator to v25.10.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1823
* fix(k8s): update authentik proxy references to ak-outpost-authentik-embedded-outpost by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1824
* chore(kustomization): comment out unused headlessx resource by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1825
* Remove FOSSA license check badges by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1827
* Replace privileged mode with SYS_ADMIN capability in openhands DinD container by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1826
* chore(deps): update helm release external-secrets to v1.1.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1830
* chore(deps): update all dependencies to v79.12.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1831
* feat(media): add audiobookshelf deployment by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1829
* chore(deps): update terraform kubernetes to v3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1828
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.12.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1832
* feat(k8s): update audiobookshelf deployment and add audiobookrequest service by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1833
* chore(deps): update ghcr.io/blakeblackshear/frigate docker tag to v0.16.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1834
* chore(deps): update terraform proxmox to v0.89.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1835
* chore(deps): update koenkk/zigbee2mqtt docker tag to v2.7.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1838
* Feat(storage)--add-recurring-jobs-for-hourly-and-GFS-backup-tiers by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1837
* chore(deps): update all dependencies to v80 (major) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1839
* chore(deps): update getmeili/meilisearch docker tag to v1.29.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1841
* chore(database): update postgresql volume size and labels by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1842
* chore(deps): update lscr.io/linuxserver/unifi-network-application docker tag to v10.0.162 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1843
* Add GPT-Researcher application with litellm integration by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1840
* Update manager-hotfix-patch.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1844
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1845
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1847
* chore(deps): update all dependencies to v80.1.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1848
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1849
* refactor(database): replace Zalando Postgres with CloudNativePG in-place by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1846
* chore(deps): update coredns/coredns docker tag to v1.13.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1850
* Chore(auth)--remove-database-credentials.yaml-from-kustomization by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1851
* chore(deps): update node.js to v24.12.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1852
* docs(authentik): add AGENTS.md for blueprint creation and maintenance by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1854
* chore(deps): update helm release redis to v24.0.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1855
* docs(agents): Implement AGENTS.md maintenance structure per agents-maintainer spec by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1853
* feat(auth): complete OIDC blueprint configuration for all applications by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1856
* chore(deps): update helm release redis to v24.0.7 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1857
* feat(k8s)!: migrate from Zalando PostgreSQL to CloudNativePG by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1858
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1859
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1860
* Update database.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1861
* Automated-Node-Upgrade-Plan by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1863
* Kubernetes n8n deployment by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1864
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1865
* chore(deps): update all dependencies to v80.3.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1866
* chore(deps): enhance renovate configuration and update Dockerfiles by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1867
* chore(deps): update all dependencies (major) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1862
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1868
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1869
* fix(image-build): improve IMAGE_VERSION extraction in Dockerfile processing by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1870
* feat(image-build): add manual workflow dispatch for image building by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1871
* Feat(upgrade)--implement-sequential-node-upgrade-mechanism-and-enhance-configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1873
* chore(deps): update all dependencies to v80.3.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1874
* chore(deps): update actions/upload-artifact action to v6 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1872
* chore(deps): update all dependencies to v80.4.1 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1875
* Psql migration to cnpg by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1876
* Longhorn replica zone anti-affinity by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1877
* chore(deps): update helm release redis to v24.0.8 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1878
* Update statefulset.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1879
* chore(deps): update ghcr.io/chriswritescode-dev/opencode-manager docker tag to v0.4.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1880
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1882
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1883
* chore(deps): update helm release argo-cd to v9.1.8 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1884
* Feat(longhorn)--enhance-storage-configuration-and-add-Prometheus-alerts by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1881
* feat(k8s): update audiobookshelf configuration and add OIDC support by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1885
* Docs(k8s)--add-troubleshooting-section-for-Longhorn-disk-expansion-issues by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1887
* Authentik group to litellm role mapping by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1888
* Kiwix wikipedia deployment by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1889
* Authentik argocd redirect issue by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1890
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1886


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v3.10.0...v4.0.0

## 3.10.0 (2025-11-20)

## What's Changed
* chore(deps): update pre-commit hook errata-ai/vale to v3.13.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1625
* chore(deps): update portkeyai/gateway docker tag to v1.13.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1627
* chore(deps): update helm release cloudnative-pg to v0.26.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1628
* chore(deps): update helm release cilium to v1.18.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1629
* chore(deps): update helm release argo-cd to v9.0.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1630
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1631
* chore(deps): update all dependencies to v78.5.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1632
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.10.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1633
* chore(deps): update helm release gpu-operator to v25.10.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1635
* chore(deps): update ghcr.io/berriai/litellm docker tag to v1.78.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1637
* chore(deps): update ghcr.io/berriai/litellm docker tag to v1.78.5 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1638
* chore(deps): update actions/upload-artifact action to v5 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1634
* chore(deps): update ghcr.io/jellyfin/jellyfin docker tag to v10.11.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1639
* chore(deps): update helm release redis to v23.2.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1640
* chore(deps): update helm release authentik to v2025.10.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1641
* chore(deps): update all dependencies (major) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1642
* chore(deps): update terraform proxmox to v0.86.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1643
* chore(deps): update node.js to v22.21.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1645
* chore(deps): update mongo docker tag to v8.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1646
* chore(deps): update all dependencies to v79.0.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1647
* chore(deps): update ghcr.io/immich-app/immich-server docker tag to v2.2.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1648
* chore(deps): update cloudflare/cloudflared docker tag to v2025.10.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1649
* chore(deps): update ghcr.io/immich-app/immich-machine-learning docker tag to v2.2.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1650
* chore(deps): update all dependencies to v2.2.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1651
* chore(deps): update all dependencies to v79.1.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1652
* chore(deps): update ghcr.io/berriai/litellm docker tag to v1.79.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1653
* chore(deps): update koenkk/zigbee2mqtt docker tag to v2.6.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1654
* chore(deps): update helm release redis to v23.2.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1655
* chore(deps): update node.js to v24 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1644
* chore(deps): update all dependencies to v79.1.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1656
* chore(deps): update ghcr.io/jellyfin/jellyfin docker tag to v10.11.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1657
* chore(deps): update all dependencies to v2.2.2 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1658
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1659
* chore(deps): update helm release argo-cd to v9.0.6 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1660
* chore(deps): update helm release redis to v23.2.5 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1661
* chore(deps): update helm release argo-cd to v9.1.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1662
* chore(deps): update helm release node-feature-discovery to v0.18.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1664
* chore(deps): update all dependencies to v2.2.3 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1665
* chore(deps): update helm release redis to v23.2.6 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1666
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.11.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1667
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1668
* chore(deps): update all dependencies to v79.2.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1669
* Chore(deps)--update-bytebot-agent-and-desktop-services,-adjust-HTTP-routes-and-ports by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1670
* fix(unifi): pin controller image to v9.2.87 by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1672
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1671
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1673
* chore(deps): update velero/velero-plugin-for-aws docker tag to v1.13.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1674
* chore(deps): update helm release redis to v23.2.11 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1676
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1677
* refactor: remove omada application by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1675
* Add license scan report and status by @fossabot in https://github.com/theepicsaxguy/homelab/pull/1678
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1679
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1680
* chore(deps): update all dependencies to v79.4.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1681
* chore(deps): update ghcr.io/berriai/litellm docker tag to v1.79.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1682
* Update database.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1683
* chore(deps): update getmeili/meilisearch docker tag to v1.25.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1685
* chore(deps): update helm release crossplane to v2.1.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1684
* chore(kustomization): remove unused resources 'portkey' and 'bytebot' by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1686
* chore(k8s): enhance security context for meilisearch, web, and immich deployments by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1687
* chore(k8s): add next-cache volume and update resource requests/limits in web StatefulSet by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1688
* Update web-statefulset.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1689
* chore(deps): update helm release argo-cd to v9.1.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1690
* chore(deps): update all dependencies to v79.5.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1691
* fix: ensure jellyfin has writable tmp storage by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1692
* chore(deps): update node.js to v24.11.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1694
* feat: deploy pinepods web application by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1693
* Update pvc.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1695
* feat(pinepods): add cache and certs volumes; update access mode to ReadWriteMany by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1696
* chore(deps): update helm release longhorn to v1.10.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1697
* chore(deps): update all dependencies to v1.18.4 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1698
* chore(deps): update helm release argo-cd to v9.1.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1699
* chore(deps): update helm release argo-cd to v9.1.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1700
* feat(pinepods): update readiness and startup probes; add valkey service and deployment by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1701
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.11.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1702
* chore(deps): update ghcr.io/berriai/litellm docker tag to v1.79.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1707
* Fix JSON syntax error in package.json by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1708
* docs: add pre-commit setup instructions and fix vale command not found by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1704
* feat(openwebui): wire qdrant vector store and embeddings by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1705
* Feat(vllm)--add-Dockerfile-and-requirements-for-vLLM-CPU-build by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1709
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1715
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1716
* chore(deps): update dependency setuptools to v78 [security] by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1714
* Update vllm-openai image to latest version by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1718
* Enforce Qdrant auth for Open WebUI by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1723
* Add CHAT_RESPONSE_STREAM_DELTA_CHUNK_SIZE to OpenWebUI by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1720
* chore(deps): bump pip from 24.3.1 to 25.3 in /images/vllm-cpu in the pip group across 1 directory by @dependabot[bot] in https://github.com/theepicsaxguy/homelab/pull/1717
* chore(deps): update all dependencies (major) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1663
* [WIP] Add Mastodon link to wiki by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1722
* Update Vale rule to forbid 'now' by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1726
* fix(images): update vllm image for ubuntu 24 by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1727
* Update deployment.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1728
* Add SYSTEM_IP environment variable to statefulset by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1729
* chore(deps): update ghcr.io/jellyfin/jellyfin docker tag to v10.11.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1730
* Add pipelines deployment for OpenWebUI by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1731
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1732
* chore(deps): update redis docker tag to v8.4.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1733
* Refactor(images)--simplify-Dockerfile-for-vLLM-CPU-build-and-remove-pinned-requirements by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1734
* Feat(pipelines)--add-new-pipelines-and-refactor-deployment-configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1736
* fix(ci): initialize git submodules in image build workflow by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1739
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1737
* chore(deps): update helm release authentik to v2025.10.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1741
* Fix vllm-cpu Docker build: replace submodule bind mounts with COPY by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1740
* Update deployment.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1743
* Fix OpenWebUI Pipelines connection and Kubernetes service discovery by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1742
* Remove invalid --device argument from vLLM v0.11.0 deployment by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1744
* Fix litellm embedding model reference to match vllm deployment by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1745
* Update configmap.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1747
* Update deployment.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1748
* fix(vllm-embed): add CPU optimizations for memory and scheduling by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1749
* chore(deps): update ghcr.io/immich-app/immich-machine-learning docker tag to v2.3.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1750
* Update deployment.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1751
* Update deployment.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1752
* chore(deps): update ghcr.io/immich-app/immich-server docker tag to v2.3.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1753
* Update deployment.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1754
* Update deployment.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1755
* chore(deps): update all dependencies to v79.6.1 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1756
* chore(deps): update all dependencies to v2.3.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1757
* chore(deps): update terraform proxmox to v0.87.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1758
* fix(httproute): add external parent reference to qdrant HTTPRoute by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1759
* fix(deployment): update litellm image to main-v1.80.0.rc.2 by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1760
* fix(configmap): update api_key format in litellm configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1762
* Fix(deployment)--update-vllm-command-parameters-and-resource-limits by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1763

## New Contributors
* @fossabot made their first contribution in https://github.com/theepicsaxguy/homelab/pull/1678

**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v3.9.0...v3.10.0

## 3.9.0 (2025-10-21)

## What's Changed
* chore(deps): update helm release authentik to v2025.8.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1494
* chore(deps): bump actions/setup-node from 4 to 5 by @dependabot[bot] in https://github.com/theepicsaxguy/homelab/pull/1492
* chore(deps): update node.js to v22 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1491
* chore(deps): update helm release argo-cd to v8.3.9 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1496
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1497
* chore(deps): update all dependencies to v77.7.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1498
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1499
* chore(deps): update helm release argo-cd to v8.5.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1500
* chore(deps): update all dependencies to v77.9.1 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1501
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1502
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.30 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1503
* chore(deps): update cloudflare/cloudflared docker tag to v2025.9.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1504
* feat: persist sabnzbd incomplete downloads by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1505
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1506
* chore(deps): update helm release argo-cd to v8.5.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1507
* chore(deps): update helm release gpu-operator to v25.3.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1508
* chore(deps): update all dependencies to v77.10.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1509
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.9.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1510
* Update statefulset.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1511
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1514
* chore(deps): update ghcr.io/berriai/litellm docker tag to v1.77.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1515
* Remove unused whoami service from homelab infrastructure by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1513
* Add Portkey Gateway deployment by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1516
* chore(deps): update dependency externalsecret to external-secrets.io/v1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1517
* feat(k8s): move Portkey from standalone folder to ai folder by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1519
* [WIP] Fix Portkey Gateway Pod Restart Loop Due to Read-Only Filesystem by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1521
* Update deployment.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1522
* Update deployment.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1523
* chore(deps): update terraform proxmox to v0.84.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1524
* chore(deps): update helm release argo-cd to v8.5.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1525
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1526
* chore(deps): update helm release external-secrets to v0.20.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1527
* chore(deps): update all dependencies to v1.143.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1528
* chore(deps): update helm release argo-cd to v8.5.5 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1529
* chore(deps): update helm release argo-cd to v8.5.6 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1530
* chore(deps): update all dependencies to v77.11.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1531
* Update statefulset.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1532
* chore(deps): update all dependencies to v1.143.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1533
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1534
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1535
* chore(deps): update helm release longhorn to v1.10.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1539
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.31 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1540
* fix(deps): update all dependencies to v3.9.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1541
* chore(deps): update all dependencies to v77.11.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1542
* fix(deps): update all dependencies to v3.9.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1543
* chore(deps): update ghcr.io/prometheus-community/charts/kube-prometheus-stack docker tag to v77.12.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1544
* chore(deps): update helm release argo-cd to v8.5.7 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1545
* chore(deps): update ghcr.io/berriai/litellm docker tag to v1.77.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1546
* chore(deps): update terraform proxmox to v0.84.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1547
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.32 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1548
* chore(deps): update portkeyai/gateway docker tag to v1.12.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1549
* chore(deps): update getmeili/meilisearch docker tag to v1.22.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1550
* chore(deps): update helm release authentik to v2025.8.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1551
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1553
* chore(deps): update all dependencies to v1.144.1 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1554
* chore(deps): update koenkk/zigbee2mqtt docker tag to v2.6.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1555
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.10.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1556
* chore(deps-dev): bump @commitlint/cli from 19.8.1 to 20.1.0 by @dependabot[bot] in https://github.com/theepicsaxguy/homelab/pull/1552
* chore(deps): update all dependencies (major) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1536
* chore(deps): update helm release node-feature-discovery to v0.18.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1557
* chore(deps): update all dependencies to v77.12.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1558
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1559
* chore(deps): update all dependencies to v77.13.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1560
* chore(deps): update ghcr.io/berriai/litellm docker tag to v1.77.5 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1561
* chore(deps): update coredns/coredns docker tag to v1.13.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1562
* chore(deps): update helm release redis to v23 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1563
* feat(k8s): increase storage for Immich and SABnzbd by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1565
* chore(deps): update helm release argo-cd to v8.5.9 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1566
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1567
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1568
* chore(deps): update python docker tag to v3.14 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1570
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.33 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1569
* chore(deps): update helm release argo-cd to v8.5.10 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1571
* chore(deps): update coredns/coredns docker tag to v1.13.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1572
* chore(deps): update helm release argo-cd to v8.6.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1574
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.10.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1576
* chore(deps): update ghcr.io/berriai/litellm docker tag to v1.77.7 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1577
* chore(deps): update terraform proxmox to v0.85.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1578
* chore(deps): update helm release redis to v23.1.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1579
* chore(deps): update helm release velero to v11.1.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1580
* chore(deps): update getmeili/meilisearch docker tag to v1.23.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1581
* chore(deps): update helm release argo-cd to v8.6.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1582
* chore(deps): update helm release external-secrets to v0.20.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1583
* chore(deps): update cloudflare/cloudflared docker tag to v2025.10.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1585
* chore(deps): update terraform proxmox to v0.85.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1586
* chore(deps): update helm release argo-cd to v8.6.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1587
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1588
* chore(deps): update helm release cert-manager to v1.19.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1589
* chore(deps): update all dependencies to v2.1.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1590
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.34 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1591
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1592
* fix(deps): update all dependencies to v3.9.2 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1593
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.10.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1594
* chore(deps): bump actions/setup-node from 5 to 6 by @dependabot[bot] in https://github.com/theepicsaxguy/homelab/pull/1584
* chore(deps): update all dependencies (major) - autoclosed by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1573
* chore(deps): update helm release argo-cd to v9.0.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1596
* refactor: remove unused Mastodon resources by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1597
* fix: align headlessx manifests with platform patterns by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1599
* chore(deps): update all dependencies to v78.3.2 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1605
* Fix HeadlessX not building from source by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1602
* chore(images): remove unused hypebot image by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1604
* chore(deps): update mcr.microsoft.com/playwright docker tag to v1.56.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1606
* chore(deps): update node.js to v22 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1607
* feat(database): add CloudNativePG operator by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1609
* Create claude.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1610
* feat: add bytebot application stack by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1608
* chore(deps): update all dependencies (major) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1611
* Refactor  update dockerfile and kubernetes manifests for bytebot application by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1612
* refactor(bytebot): remove NGINX proxy and connect directly to LiteLLM by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1614
* Fix Bytebot service URLs to use documented defaults with explicit ports by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1616
* Fix Bytebot VNC routing by adding URLRewrite filter by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1618
* chore(deps): update ghcr.io/jellyfin/jellyfin docker tag to v10.11.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1619
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1621
* chore(deps): update getmeili/meilisearch docker tag to v1.24.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1622
* chore(deps): update node.js to v22.21.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1623
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1624

## New Contributors
* @dependabot[bot] made their first contribution in https://github.com/theepicsaxguy/homelab/pull/1492

**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v3.8.0...v3.9.0

## 3.8.0 (2025-09-15)

## What's Changed
* docs: move mastodon docs to website by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1322
* chore(deps): update helm release external-secrets to v0.19.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1329
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1330
* Update statefulset.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1332
* chore(ci): lint only changed docs by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1331
* chore(images): add OCI descriptions by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1326
* chore(deps): update helm release crossplane to v2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1335
* refactor(mastodon): split env configmaps per service by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1336
* chore(deps): update helm release redis to v22.0.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1338
* chore(deps): update helm release argo-cd to v8.2.6 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1339
* chore(deps): update helm release argo-cd to v8.2.7 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1340
* feat(tofu): add worker node work-04 by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1334
* feat(k8s): update mastodon configurations and deployments by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1342
* fix(mastodon): tune elasticsearch resources by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1343
* feat(elasticsearch): add external secret and setup job for Elasticsearch credentials by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1344
* Fix(k8s)--set-ES_PRESET-for-Elasticsearch-configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1345
* fix(sabnzbd): install cherrypy runtime dependency by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1348
* fix(mastodon): disable s3 acls for r2 by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1349
* fix(k8s): set minio endpoint for logical backups by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1347
* feat(k8s): add revision tag generation for Docker images by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1350
* Replace-helm-with-manual-es-redis by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1351
* fix(mastodon): remove redundant TLS environment variables for Kibana by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1352
* fix(k8s): update kibana deployment metadata and secret reference by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1354
* fix(mastodon): remove DEFAULT_LOCALE from mastodon core environment by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1355
* fix(renovate): configure regex manager templates by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1357
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1358
* fix(mastodon): expose elasticsearch master service by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1356
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1359
* chore(deps): update actions/checkout action to v5 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1360
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1362
* chore(deps): update getmeili/meilisearch docker tag to v1.17.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1363
* fix: add elasticsearch labels for mastodon by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1365
* fix(kibana): enable tls for elasticsearch by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1364
* chore: build images on pull request by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1366
* feat(ci): build only changed images by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1368
* fix(ci): fetch full history for image builds by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1369
* chore(deps): update ghcr.io/prometheus-community/charts/kube-prometheus-stack docker tag to v76.3.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1371
* Update image-build.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1370
* chore(deps): update getmeili/meilisearch docker tag to v1.17.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1372
* Feat(k8s)  enhance mastodon deployment with elasticsearch integration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1373
* feat(k8s): update kibana deployment and add service account setup job by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1374
* chore(deps): update helm release crossplane to v2.0.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1375
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1376
* feat(tofu): add api load balancer by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1377
* chore(deps): update helm release redis to v22.0.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1378
* chore(deps): update helm release argo-cd to v8.3.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1379
* Create v411e-hype/Dockerfile by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1380
* theepicsaxguy-patch-7 by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1382
* Update image-build.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1383
* Update image-build.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1384
* chore(deps): update python docker tag to v3.13 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1381
* Feat(k8s)--add-hypebot-deployment-and-configuration-files by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1385
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1386
* Feat(k8s)--add-application-set-and-project-configuration-for-GitOps by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1387
* chore(deps): update ghcr.io/fallenbagel/jellyseerr docker tag to v2.7.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1388
* chore(deps): update all dependencies to v76.4.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1390
* Fix(infra)--update-file-associations-for-Terraform-and-OpenTofu by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1391
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1389
* fix(apps): update hypebot image to ghcr.io/goingdark-social/hypebot:v0.1.0 by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1392
* chore(deps): update ghcr.io/blakeblackshear/frigate docker tag to v0.16.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1393
* Fix/cilium disable multicast by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1394
* Fix(cilium)  remove multicast config map by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1395
* chore(hypebot): remove unused configuration files and resources by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1396
* chore(deps): update terraform proxmox to v0.82.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1397
* chore(deps): update getmeili/meilisearch docker tag to v1.18.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1398
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1399
* chore(deps): update terraform proxmox to v0.82.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1400
* chore(deps): update ollama/ollama docker tag to v0.11.5 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1401
* chore(deps): update helm release authentik to v2025.8.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1402
* chore(deps): update ollama/ollama docker tag to v0.11.6 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1403
* chore(deps): update cloudflare/cloudflared docker tag to v2025.8.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1404
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1405
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1406
* chore(deps): update all dependencies to v76.5.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1407
* chore(deps): update all dependencies to v76.5.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1408
* chore(deps): update all dependencies to v1.139.2 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1409
* chore(deps): update helm release redis to v22.0.5 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1410
* chore(deps): update all dependencies to v1.139.3 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1412
* chore(deps): update getmeili/meilisearch docker tag to v1.19.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1413
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1414
* chore(deps): update ghcr.io/immich-app/immich-server docker tag to v1.139.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1415
* chore(deps): update all dependencies to v77 (major) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1411
* chore(deps): update helm release redis to v22.0.6 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1416
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1418
* Feat(litellm)--add-Kubernetes-manifests-for-Litellm-application-deployment by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1417
* disable autoscaling argocd by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1419
* chore(deps): update helm release redis to v22.0.7 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1420
* feat(litellm): enable prompt storage by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1421
* feat: enable LiteLLM caching and health probes by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1422
* chore(deps): update redis docker tag to v7.2.10 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1423
* chore(deps): update redis docker tag to v7.4.5 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1424
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.26 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1426
* chore(k8s): update open-webui image tag to 0.6.26-slim by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1427
* chore(k8s): update redis cache configuration in configmap by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1428
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1429
* Refactor(k8s)--update-configuration-settings-for-litellm by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1430
* chore(deps): update all dependencies to v1.140.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1431
* chore(deps): update all dependencies to v77.1.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1432
* chore(deps): update terraform proxmox to v0.83.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1433
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1434
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1435
* chore(deps): update all dependencies to v77.2.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1436
* chore(deps): update all dependencies to v77.3.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1437
* chore(deps): update all dependencies to v77.4.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1438
* chore(deps): update all dependencies to v77.5.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1439
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.9.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1440
* chore(deps): update ghcr.io/blakeblackshear/frigate docker tag to v0.16.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1441
* chore(deps): update helm release argo-cd to v8.3.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1442
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.9.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1443
* chore(deps): update kustomization and config values for litellm and argocd to streamline resource management by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1444
* chore(deps): update helm release argo-cd to v8.3.5 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1445
* chore(deps): reduce replica counts for whoami, mongodb, prometheus, and alertmanager to optimize resource usage by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1446
* chore(deps): update getmeili/meilisearch docker tag to v1.20.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1447
* chore(deps): update all dependencies to v1.141.1 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1448
* chore(deps): update coredns/coredns docker tag to v1.12.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1449
* chore(deps): update ghcr.io/berriai/litellm docker tag to v1.76.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1450
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.27 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1451
* chore(deps): update all dependencies to v77.6.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1452
* chore(deps): update terraform proxmox to v0.83.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1453
* chore(deps): update helm release velero to v10.1.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1454
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.28 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1455
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1456
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1457
* chore(deps): update all dependencies to v1.142.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1458
* fix(sabnzbd): set entrypoint download directories by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1459
* Delete k8s/external directory by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1460
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1461
* Create README.MD by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1462
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.9.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1463
* Update entrypoint.py by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1464
* Update statefulset.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1465
* chore(deps): update all dependencies (major) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1425
* Update statefulset.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1466
* Update renovate.json by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1467
* chore(config): migrate renovate config by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1468
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1469
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1470
* Update statefulset.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1471
* Update Dockerfile by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1472
* Update statefulset.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1473
* Update Dockerfile by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1474
* Update entrypoint.py by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1475
* Update Dockerfile by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1476
* Update entrypoint.py by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1477
* Update entrypoint.py by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1478
* Update Dockerfile by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1479
* Fix: Update build workflow to trigger on all non-Markdown file changes by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1481
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1484
* chore(deps): update terraform proxmox to v0.83.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1485
* Update statefulset.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1486
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1487
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1488
* fix(build): enforce Node.js >=20.18.1 requirement and prevent module loading issues by @Copilot in https://github.com/theepicsaxguy/homelab/pull/1483
* chore(deps): update node.js to v20.18.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1489
* chore(deps): update node.js to v20.19.5 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1490
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1493

## New Contributors
* @Copilot made their first contribution in https://github.com/theepicsaxguy/homelab/pull/1481

**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v3.7.0...v3.8.0

## 3.7.0 (2025-08-08)

## What's Changed
* chore(deps): update ollama/ollama docker tag to v0.10.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1236
* fix(k8s): disable Mastodon Postgres SSL by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1238
* chore(deps): update helm release velero to v10.0.11 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1240
* Feat/improve-mastodon-performance by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1239
* Add Mastodon SMTP secrets by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1241
* chore(deps): update helm release argo-cd to v8.2.5 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1242
* Add implicit TLS flags for Mastodon mailer by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1243
* chore(deps): update dependency typescript to ~5.9.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1244
* chore(deps): update helm release kubechecks to v0.5.6 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1246
* Fix postgres backup secret by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1245
* Increase Mastodon Sidekiq resources by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1247
* feat(k8s): triple Mastodon media PVC by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1248
* Update Mastodon images by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1249
* chore(deps): update ghcr.io/immich-app/immich-machine-learning docker tag to v1.137.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1250
* chore(deps): update ghcr.io/immich-app/immich-machine-learning docker tag to v1.137.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1251
* chore(deps): update ghcr.io/immich-app/immich-server docker tag to v1.137.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1252
* chore(deps): update terraform proxmox to v0.81.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1253
* chore(deps): update all dependencies to v1.137.3 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1254
* chore(deps): update koenkk/zigbee2mqtt docker tag to v2.6.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1255
* feat(tofu): add support for external nodes in configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1256
* Increase Mastodon PVC to 50Gi by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1257
* chore(deps): update mbentley/omada-controller docker tag to v5.15.24.19 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1258
* chore(deps): update helm release external-secrets to v0.19.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1259
* chore(deps): update helm release redis to v21.2.14 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1261
* chore(deps): update getmeili/meilisearch docker tag to v1.16.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1262
* Feat--add-s3-cdn-for-mastodon by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1260
* chore(deps): update nginx docker tag to v1.29 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1263
* chore(deps): update all dependencies to v75.15.2 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1264
* fix(mastodon): include bucket in proxy and allow CDN hosts by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1267
* fix(mastodon): remove CDN_HOST override by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1268
* Update nginx-proxy.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1269
* feat(gateway): add additional HTTPS listener for goingdark.social by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1270
* chore(mastodon): remove unused storage configurations by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1272
* feat(mastodon): add hcaptcha secrets by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1271
* chore(deps): update ollama/ollama docker tag to v0.11.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1273
* chore(deps): update coredns/coredns docker tag to v1.12.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1275
* chore(deps): update all dependencies to v75.16.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1276
* fix: refactor nginx proxy by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1274
* fix(k8s): render sabnzbd secrets in config by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1277
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1278
* fix(sabnzbd): overwrite config during init by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1279
* fix(sabnzbd): overwrite config during init by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1280
* fix(sabnzbd): ensure config seed uses envsubst by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1282
* chore(deps): update ollama/ollama docker tag to v0.11.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1283
* fix(sabnzbd): ensure config seed uses envsubst by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1281
* chore(deps): update helm release velero to v10.0.12 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1284
* chore(mastodon): update to v4.4.3 by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1285
* chore(deps): update all dependencies to v75.17.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1286
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.8.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1288
* chore(deps): update ghcr.io/prometheus-community/charts/kube-prometheus-stack docker tag to v75.17.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1289
* feat(mastodon): scale components and enable pooling by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1287
* fix(mastodon): route replica database through pooler by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1291
* fix(mastodon): label namespace for baseline podsecurity by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1290
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1292
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1293
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1294
* fix(mastodon): run migrations via job by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1295
* Update database.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1296
* fix(mastodon): use primary database service by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1297
* feat(mastodon): enable tls for database connections by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1298
* chore(deps): update docker.elastic.co/elasticsearch/elasticsearch docker tag to v9.1.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1299
* chore(deps): update all dependencies to v75.18.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1300
* chore(deps): update all dependencies to v75.18.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1301
* Fix  resolved ssl for postgresql and mastodon by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1302
* chore(deps): update ollama/ollama docker tag to v0.11.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1305
* Test mastodon helm by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1306
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1307
* chore(deps): update elasticsearch docker tag to v19.21.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1308
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1310
* chore(deps): update elasticsearch docker tag to v22 - autoclosed by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1309
* fix(mastodon): add backup credentials secret by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1311
* feat(sabnzbd): rebuild with distroless image by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1313
* chore(deps): update elasticsearch docker tag to v22.1.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1314
* chore(deps): update python docker tag to v3.13 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1315
* Update Dockerfile by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1317
* chore(deps): update busybox docker tag to v1.37.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1318
* chore(deps): update helm release redis to v22 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1316
* Update image-build.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1319
* trigger build by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1321
* fix(ci): quote pattern and separator in Vale workflow by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1320
* fix(pre-commit): add document start by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1325
* chore(deps): update all dependencies to v76 (major) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1324


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v3.6.0...v3.7.0

## 3.6.0 (2025-07-30)

## What's Changed
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.7.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1194
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.16 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1196
* chore(deps): update terraform proxmox to v0.80.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1197
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1198
* chore(deps): update all dependencies to v75.11.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1199
* chore(deps): update helm release redis to v21.2.12 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1200
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1201
* fix(deps): update dependency @easyops-cn/docusaurus-search-local to ^0.52.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1202
* chore(deps): update all dependencies to v75.12.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1203
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.18 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1204
* chore(deps): update helm release argo-cd to v8.1.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1205
* chore(deps): update ghcr.io/fallenbagel/jellyseerr docker tag to v2.7.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1206
* chore(deps): update terraform kubernetes to ~> 2.38.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1207
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1208
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1209
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1210
* chore(deps): update all dependencies to v1.136.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1211
* chore(deps): update helm release argo-cd to v8.2.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1212
* chore(deps): update all dependencies to v75.14.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1213
* chore(deps): update all dependencies to v75.15.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1214
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1215
* fix(k8s): update bazarr statefulset configuration and environment variables by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1216
* feat(network): add LoadBalancer service for omada by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1217
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.7.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1218
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1220
* feat(k8s): add Mastodon application stack by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1221
* fix(ci): lint only changed docs by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1224
* docs: standardize Open WebUI references by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1226
* feat(k8s): add Mastodon external secrets and service account configuration

- Introduced db-secrets.yaml for database credentials
- Updated externalsecret.yaml to use new naming convention
- Added secretstore.yaml for external secrets management
- Created serviceaccount.yaml for RBAC permissions
- Modified statefulset.yaml to reference new secrets by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1227
* feat(deployment): configure Mastodon with HTTPS and persistent storage by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1228
* chore(deps): update docker.elastic.co/elasticsearch/elasticsearch docker tag to v7.17.29 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1229
* chore(deps): update all dependencies to v1.18.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1232
* Split gateway TLS certs by domain by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1231
* chore(deps): update docker.elastic.co/elasticsearch/elasticsearch docker tag to v9 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1230
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1233
* chore(deps): update ollama/ollama docker tag to v0.10.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1234
* feat(k8s): update Mastodon deployment configurations and resource limits

- added new environment variables for Mastodon
- increased Redis persistence size and resource requests/limits
- updated streaming and web deployment resource requests/limits by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1235


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v3.5.0...v3.6.0

## 3.5.0 (2025-07-13)

## What's Changed
* Refactor(nvidia)  remove deprecated nvidia device plugin resources by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1145
* Update statefulset.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1146
* chore(deps): update ollama/ollama docker tag to v0.9.4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1147
* chore(deps): update onerahmet/openai-whisper-asr-webservice docker tag to v1.9.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1150
* chore(deps): update all dependencies (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1151
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.7.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1153
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1152
* refactor(config): centralize cluster configuration into variables by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1149
* chore(deps): update koenkk/zigbee2mqtt docker tag to v2.5.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1154
* chore(deps): update linuxserver/unrar docker tag to v7.1.8 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1155
* chore(deps): update helm release external-secrets to v0.18.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1156
* Refactor(mqtt)--update-secret-keys-and-improve-password-handling by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1157
* chore(deps): update mbentley/omada-controller docker tag to v5.15.24.18 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1158
* chore(deps): update cloudflare/cloudflared docker tag to v2025.7.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1159
* Enhance-Zigbee2MQTT-initialization-process by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1160
* docs(k8s): add guide for dynamic app config by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1161
* Refactor(k8s)--simplify-external-secret-and-configuration-management by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1162
* chore(deps): update all dependencies to v75.8.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1163
* chore(deps): update ghcr.io/home-assistant/home-assistant docker tag to v2025.7.1 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1164
* refactor(k8s): rename haos to hassio in HTTPRoute and DNS records by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1165
* chore(deps): update all dependencies to v75.8.1 (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1167
* chore(deps): update all dependencies to v75.9.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1168
* chore(deps): update terraform proxmox to v0.79.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1169
* chore(deps): update helm release redis to v21.2.7 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1170
* docs(getting-started): document domain and dns setup by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1172
* feat(website): improve seo and static stats by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1171
* Refactor(github-stats)--improve-GitHub-stats-fetching-and-caching by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1173
* Feat(docs)--add-linting-and-style-checks-for-markdown-files by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1176
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1177
* chore(deps): update pre-commit hook errata-ai/vale to v3.12.0 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1178
* Refactor documentation for Kubernetes provisioning and application management by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1179
* chore(deps): update helm release redis to v21.2.9 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1181
* chore(deps): update all dependencies (patch) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1182
* chore(deps): update helm release argo-cd to v8.1.3 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1183
* chore(deps): update helm release velero to v10.0.9 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1184
* feat(hassio): enable OIDC login via Authentik by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1174
* chore(deps): update helm release redis to v21.2.10 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1185
* chore(deps): update all dependencies to v75.10.0 (minor) by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1186
* chore(deps): update ghcr.io/blakeblackshear/frigate docker tag to v0.15.2 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1187
* Fix Vale action config by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1188
* chore(deps): update dependency remark-lint-no-empty-sections to v4 by @renovate[bot] in https://github.com/theepicsaxguy/homelab/pull/1180
* Fix homepage quick start link by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1189
* fix: vale ci introduce comments by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1191
* fix: vale ci introduce comments by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1192
* docs: resolve vale errors by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1190
* Update vale.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1193


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v3.4.0...v3.5.0

## 3.4.0 (2025-06-30)

## What's Changed
* Refactor(tofu)--update-variable-definitions-and-remove-unused-outputs by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1117
* feat(auth): configure kubectl oidc via authentik by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1118
* feat(openwebui): merge oauth accounts by email by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1120
* refactor(k8s): update webui statefulset to include static-files volume by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1122
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/1123
* feat(k8s): enhance GPU support and configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1124
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/1125
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/1126
* feat(k8s): add GPU tolerations and taints for enhanced scheduling by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1127
* feat(k8s): persist mosquitto data and tighten policies by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1129
* chore(deps): update onerahmet/openai-whisper-asr-webservice docker tag to v1.9.0 by @renovate in https://github.com/theepicsaxguy/homelab/pull/1130
* feat(k8s): configure GPU node runtime and taints by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1128
* fix(k8s): update security context to run as root user by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1131
* Feat(mdns proxy)  add m dns repeater and related udp routes by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1132
* Feat(k8s)--restructure-Home-Assistant-configuration-and-initialization-scripts by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1133
* fix(k8s): align home-assistant ports and capabilities by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1136
* refactor(gpu): simplify passthrough and add nfd by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1137
* chore(deps): update all dependencies to v75.6.2 (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/1139
* fix: added custom gpu rules NFD by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1138
* Update statefulset.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1140
* Pr/theepicsaxguy/1135 by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1141
* fix(tofu): update ram_dedicated for worker node configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1142


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v3.3.0...v3.4.0

## 3.3.0 (2025-06-24)

## What's Changed
* feat(images): add dockerignore for spilo17-vchord by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1041
* docs(getting-started): list required CLI tools by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1042
* refactor(tofu): stabilize image downloads by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1044
* docs: update OpenTofu references by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1045
* docs(k8s): remove Bitwarden item notes by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1052
* docs(k8s): reference secret name by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1050
* docs(k8s): use kustomize build in manual bootstrap guide by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1049
* docs(k8s): update repository URL in argocd guide by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1048
* docs: update OpenTofu references by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1047
* docs: update OpenTofu references by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1046
* fix(tofu): ignore null node overrides by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1053
* Refactor(tofu)--improve-schematic-processing-in-image-configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1056
* docs: rename image blocks by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1054
* feat(tofu): make node freeze opt-in by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1057
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/1058
* chore(deps): update helm release velero to v10.0.6 by @renovate in https://github.com/theepicsaxguy/homelab/pull/1059
* refactor(tofu): remove freeze attribute from node configurations by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1060
* chore(deps): update ghcr.io/immich-app/immich-machine-learning docker tag to v1.135.2 by @renovate in https://github.com/theepicsaxguy/homelab/pull/1061
* chore(deps): update all dependencies (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/1062
* feat(k8s): expand immich library volume to 40Gi by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1063
* chore(deps): update ghcr.io/immich-app/immich-server docker tag to v1.135.2 by @renovate in https://github.com/theepicsaxguy/homelab/pull/1064
* fix: Update prompts by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1065
* chore(deps): update all dependencies to v1.135.3 (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/1066
* docs(website): remove seo page by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1067
* chore(repo): enable esm for commitlint by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1068
* docs: update schematic variable names by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1069
* docs(github): clarify updater tools by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1070
* refactor(k8s): embed babybuddy pvc in statefulset by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1071
* docs(contributing): add required checks summary by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1072
* fix(talos): pin cilium-cli version by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1074
* fix(k8s): clarify frigate route names by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1075
* feat(infra): add CNAME record for HAOS in Cloudflare DNS by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1078
* refactor(k8s): simplify home-assistant service definition by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1079
* feat: add home assistant  by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1080
* chore(deps): update ghcr.io/mysticrenji/bluez-service docker tag to v1.1.0 by @renovate in https://github.com/theepicsaxguy/homelab/pull/1087
* Feat(k8s)--refactor-home-assistant-deployment-and-add-zigbee2mqtt-support by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1088
* fix(hassio): specify non-root security context by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1089
* fix(k8s): update hassio statefulset security context by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1090
* feat(k8s): add configmap for home assistant by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1091
* feat(k8s): allow zigbee2mqtt privileged by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1092
* fix(automation): link to correct home assistant folder by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1093
* Feat(k8s)--update-zigbee2mqtt-configuration-and-add-external-secrets by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1095
* fix(k8s): update namespace for hassio secrets by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1097
* chore(deps): update busybox docker tag to v1.37 by @renovate in https://github.com/theepicsaxguy/homelab/pull/1096
* fix(k8s): mount hassio secrets file by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1098
* fix(k8s): mount hassio secrets file by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1099
* Feat(k8s)  add zigbee2mqtt configuration and device management files by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1100
* fix(k8s): update zigbee2mqtt serial adapter configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1101
* chore(deps): update helm release velero to v10.0.7 by @renovate in https://github.com/theepicsaxguy/homelab/pull/1102
* fix(k8s): update frigate strategy type and image repository by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1103
* chore(deps): update homeassistant/home-assistant docker tag to v2025.6.2 by @renovate in https://github.com/theepicsaxguy/homelab/pull/1104
* fix(k8s): reduce storage requests for bazarr, radarr, and omada by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1105
* chore(deps): update all dependencies to v75.5.0 (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/1106
* fix(k8s): update zigbee2mqtt configuration for homeassistant integration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1107
* feat(k8s): seed sabnzbd config via ExternalSecret by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1109
* chore(deps): update alpine docker tag to v3.22 by @renovate in https://github.com/theepicsaxguy/homelab/pull/1110
* chore(deps): update homeassistant/home-assistant docker tag to v2025.6.3 by @renovate in https://github.com/theepicsaxguy/homelab/pull/1111
* Feat(k8s)  add sabnzbd initialization script and update secrets by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1112
* fix(network): correct storage request value in omada StatefulSet by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1114
* feat(k8s): add ExternalSecret for MinIO PostgreSQL backup credentials by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1115
* Refactor(tofu)  update variable definitions and remove unused outputs by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1116
* chore(deps): update all dependencies (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/1113


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v3.2.0...v3.3.0

## 3.2.0 (2025-06-19)

## What's Changed
* feat(auth): add users to all groups by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/974
* fix(k8s): adjust immich resources and domain url by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/976
* docs(k8s): add secret management guide by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/979
* fix(k8s): read immich config from secret by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/980
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/981
* chore(deps): update helm release redis to v21.2.4 by @renovate in https://github.com/theepicsaxguy/homelab/pull/984
* chore(deps): update helm release authentik to v2025.6.2 by @renovate in https://github.com/theepicsaxguy/homelab/pull/985
* chore(deps): update all dependencies to v75 (major) by @renovate in https://github.com/theepicsaxguy/homelab/pull/983
* chore(deps): update cloudflare/cloudflared docker tag to v2025.6.1 by @renovate in https://github.com/theepicsaxguy/homelab/pull/986
* chore(deps): update helm release argo-cd to v8.1.0 - autoclosed by @renovate in https://github.com/theepicsaxguy/homelab/pull/982
* chore(deps): update all dependencies to v75.2.0 (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/988
* fix(argocd): include EndpointSlice in resource list by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/989
* Update values.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/990
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/991
* chore(deps): update helm release external-secrets to v0.18.0 by @renovate in https://github.com/theepicsaxguy/homelab/pull/992
* fix(argocd): use label tracking by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/993
* feat(storage): set longhorn reclaim policy to retain by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/994
* fix(k8s): remove namespace allowlist annotation by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/995
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/996
* chore(deps): update all dependencies to v75.3.0 (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/997
* fix(k8s): raise immich pod resources by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/998
* refactor(tofu): drop restapi provider by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/999
* refactor(tofu): remove unused talos variables by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1000
* fix(tofu): replace self references by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1001
* style(tofu): add newline at EOF by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1003
* fix(tofu): update provider constraint comment by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1004
* refactor(talos): remove debug output by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1005
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/1007
* feat(tofu): use defaults for node configs by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1006
* feat(tofu): add disk unit numbers by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1008
* feat(tofu): enforce control plane node validation by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1009
* chore(deps): update all dependencies to v75.3.2 (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/1010
* chore(deps): update all dependencies to v1.135.0 (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/1011
* refactor(talos): deduplicate image downloads by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1012
* refactor(talos): split locals for clarity by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1013
* feat(tofu): add node validation by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1014
* chore(deps): update helm release redis to v21.2.5 by @renovate in https://github.com/theepicsaxguy/homelab/pull/1015
* refactor(tofu): expose node defaults as variables by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1016
* feat(tofu): centralize cluster domain by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1018
* refactor(tofu): centralize provider version constraints by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1020
* docs(tofu): remove upgrade helper from diagram by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1021
* feat(tofu): move node configs to tfvars by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1027
* refactor(talos): split config into dedicated files by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1028
* chore(deps): update all dependencies to v75.3.3 (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/1032
* refactor(tofu): move upgrade locals to dedicated file by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1031
* fix(talos): deduplicate image downloads by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1033
* fix(tofu): use schematic resource id by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1034
* chore(website): remove obsolete sidebar file by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1036
* fix(talos): make image downloads map keys static by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1037
* chore(deps): update all dependencies to v75.3.5 (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/1039
* fix(tofu): handle optional update flag by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/1040


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v3.1.0...v3.2.0

## 3.1.0 (2025-06-15)

## What's Changed
* refactor(k8s): remove LoadBalancer type from web service by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/952
* refactor(k8s): remove velero-plugin-for-csi from initContainers by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/954
* refactor(k8s): update storageClassName to longhorn for stateful sets by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/955
* fix(k8s): remove unsupported cloudflared pdb by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/956
* docs: clarify limitations and DR scope by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/943
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/930
* fix(k8s): allow velero node-agent on baseline clusters by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/957
* chore(k8s): remove outdated backup cronjobs by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/958
* fix(k8s): use minio keys for velero by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/959
* fix(k8s): remove redundant Omada PVC and port by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/960
* chore(k8s): restructure jellyseerr deployment configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/961
* fix(k8s): update volume mounts and claims for jellyfin StatefulSet by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/962
* fix(k8s): update StatefulSet configuration and remove unused PVCs by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/963
* Chore(k8s)--remove-unused-PVCs-and-patch-files-for-media-applications by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/964
* fix(k8s): update PVC configuration for immich server and jellyseerr service by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/965
* fix(k8s): update container port for jellyseerr StatefulSet by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/966
* fix(k8s): update container ports for jellyseerr and bazarr services by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/967
* fix(k8s): update immich OIDC credentials and configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/968
* feat(k8s): configure immich OAuth via secret by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/969
* Fix(k8s)--remove-unused-storageTemplate-configuration-from-immich-secret by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/970
* Fix(k8s)--remove-unused-storageTemplate-configuration-from-immich-secret by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/971
* fix(immich): align oidc issuer with blueprint by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/972
* feat(k8s): enhance immich configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/973


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v3.0.0...v3.1.0

## 3.0.0 (2025-06-14)

## What's Changed
* Create FUNDING.yml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/941
* style(kustomization): format YAML resources for consistency by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/946
* chore(deps): update all dependencies to v74 (major) by @renovate in https://github.com/theepicsaxguy/homelab/pull/944
* chore(deps): update all dependencies to v74.2.1 (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/949
* refactor(k8s): migrate deployments to statefulsets and update services by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/948
* docs(migration)!: !add guide for migrating stateful applications to S… by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/950
* docs(migration)!: !add guide for migrating stateful applications to StatefulSets by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/951


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v2.10.0...v3.0.0

## 2.10.0 (2025-06-12)

## What's Changed
* fix(k8s): run frigate as root for s6-overlay by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/912
* chore(deps): update ghcr.io/prometheus-community/charts/kube-prometheus-stack docker tag to v73.2.1 by @renovate in https://github.com/theepicsaxguy/homelab/pull/913
* fix(frigate): allow chown on log tmpfs by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/915
* chore(deps): update all dependencies to v73.2.2 (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/916
* fix(frigate): allow group changes by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/917
* fix(frigate): allow setuid and writable root by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/918
* fix(k8s): address container startup issues by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/919
* feat(k8s): add velero backup controller by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/920
* chore(deps): update velero/velero-plugin-for-aws docker tag to v1.10.1 by @renovate in https://github.com/theepicsaxguy/homelab/pull/921
* chore(deps): update all dependencies (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/922
* feat(k8s): add cloudflared probes and pdb by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/923
* feat(k8s): enable ha mode for argocd by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/924
* fix(k8s): update velero plugin configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/926
* chore(deps): update helm release velero to v10 - autoclosed by @renovate in https://github.com/theepicsaxguy/homelab/pull/925
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/927
* chore(k8s): comment out openai summary for kubechecks by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/928
* fix(kubechecks): add cloudflare schemas by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/929
* fix(k8s): declare CSI snapshot location by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/932
* chore(deps): update velero/velero-plugin-for-csi docker tag to v0.7.1 by @renovate in https://github.com/theepicsaxguy/homelab/pull/931
* docs: rewrite documentation in first person by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/933
* feat(website): reshape homepage for project showcase by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/934
* docs(contributing): clarify maintainer role by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/935
* chore(website): remove unused SocialProof component by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/936
* docs(readme): move domain note to setup docs by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/937
* chore(scripts): remove unused fix_kustomize script by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/939
* fix(website): remove local logos and use external docs link by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/938
* fix(website): fetch repo stats and logos from GitHub by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/940


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v2.9.0...v2.10.0

## 2.9.0 (2025-06-11)

## What's Changed
* feat(infra): enable HA replicas by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/868
* fix(k8s): template Cloudflare provider credentials by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/871
* fix(auth): increase worker probe timeout by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/872
* fix(k8s): enable HA for critical databases by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/874
* feat(k8s): add pdbs for critical services by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/875
* chore update omada by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/876
* feat(k8s): integrate Karakeep with Authentik by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/877
* docs: remove historical references by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/878
* chore(deps): update helm release argo-cd to v8.0.17 by @renovate in https://github.com/theepicsaxguy/homelab/pull/880
* refactor(k8s): simplify kubechecks token sync by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/879
* fix(k8s): specify pedrobot image by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/881
* chore(deps): update helm release cert-manager to v1.18.0 by @renovate in https://github.com/theepicsaxguy/homelab/pull/882
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.14 by @renovate in https://github.com/theepicsaxguy/homelab/pull/884
* fix(k8s): pin image versions and policies by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/885
* fix(k8s): update pedrobot image by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/883
* chore(deps): update helm release redis to v21.2.2 by @renovate in https://github.com/theepicsaxguy/homelab/pull/887
* fix(deps): update all dependencies (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/888
* chore(deps): update helm release redis to v21.2.3 by @renovate in https://github.com/theepicsaxguy/homelab/pull/889
* chore(deps): update cloudflare/cloudflared docker tag to v2025.6.0 by @renovate in https://github.com/theepicsaxguy/homelab/pull/890
* refactor(k8s): consolidate arr configs and scope secrets by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/891
* fix(argocd): drop unused kubechecks token by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/897
* docs: replace example domains with placeholders by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/896
* fix(k8s): remove unsupported fields from cloudflare crds by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/898
* fix(k8s): enforce read-only root filesystem by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/894
* fix(k8s): update zone reference for ittools by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/900
* fix(network): run CoreDNS as non-root by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/892
* feat(k8s): enforce securityContext on helm charts by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/901
* feat(k8s): enforce securityContext on helm charts by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/903
* docs(monitoring): update CRD management details by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/904
* fix(k8s): mount tmp dir for kubechecks by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/905
* docs: refresh README and add contributing guide by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/906
* fix(k8s): add tmp and run volumes for karakeep by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/907
* fix(k8s): mount tmpfs for frigate /run by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/908
* fix(k8s): enable privilege escalation for bazarr and frigate by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/909
* docs(contributing): fix broken links by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/911
* chore(deps): update getmeili/meilisearch docker tag to v1.15.1 by @renovate in https://github.com/theepicsaxguy/homelab/pull/910


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v2.8.0...v2.9.0

## 2.8.0 (2025-06-09)

## What's Changed
* Add CODE_OF_CONDUCT and fix README link by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/818
* fix(k8s): specify cloudflare account name by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/820
* fix(network): update cilium helm repo by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/822
* refactor(k8s): share arr deployment config by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/821
* k8s: automate kubechecks argocd token by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/825
* k8s(authentik): update external secrets by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/828
* chore(deps): update all dependencies to v73.2.0 (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/827
* fix(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/826
* k8s(resources): tune workloads and add pedrobot db by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/829
* chore(deps): update mongo docker tag to v8 by @renovate in https://github.com/theepicsaxguy/homelab/pull/830
* fix(k8s): use Recreate strategy for PVC deployments by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/831
* fix(k8s): update argocd token generator image by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/832
* chore(deps): update all dependencies (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/834
* chore(deps): update helm release argo-cd to v8.0.15 by @renovate in https://github.com/theepicsaxguy/homelab/pull/833
* k8s(controllers): embed token generator by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/837
* fix(k8s): update sync-wave annotations and enable ServerSideApply by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/838
* feat(k8s): enhance Jellyfin integration with ExternalSecret and environment variables by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/839
* fix(k8s): update .gitignore and token-pushsecret.yaml for consistency by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/840
* fix(k8s): set grafana oauth secret ids by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/841
* feat(website): enable local search by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/842
* feat(website): organize sidebar categories by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/843
* feat(website)!: remove blog by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/844
* fix(website): replace local search plugin by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/845
* docs(readme): fix links and quick start by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/846
* chore(deps): update helm release redis to v21.2.1 by @renovate in https://github.com/theepicsaxguy/homelab/pull/847
* feat(k8s): add probes and backups by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/849
* fix(k8s): set babybuddy port to 3000 by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/850
* Update deployment.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/851
* Update deployment.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/852
* Update deployment.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/853
* fix(k8s): relax probe intervals by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/854
* docs(website): expose changelog by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/855
* fix(k8s): generate ArgoCD token without CLI by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/856
* feat(k8s): add probes and pvc updates by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/858
* chore(deps): update helm release argo-cd to v8.0.16 by @renovate in https://github.com/theepicsaxguy/homelab/pull/857
* feat(k8s): add pod disruption budgets by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/860
* fix(unrar): improve liveness probe by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/862
* chore(k8s): remove unused babybuddy values file by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/861
* fix(k8s): limit kubechecks cpu by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/859
* ci(image-build): set minimal permissions by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/863
* feat(jellyfin): persist cache volume by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/865
* fix(k8s): make unrar liveness probe resilient to long extractions by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/864
* fix(pedrobot): separate mongo backup storage by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/866
* chore(deps): update getmeili/meilisearch docker tag to v1.15.0 by @renovate in https://github.com/theepicsaxguy/homelab/pull/870


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v2.7.0...v2.8.0

## 2.7.0 (2025-06-04)

## What's Changed
* chore(deps): update all dependencies to v72.9.0 (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/786
* Refactor(tofu)  update talos image configuration and http data sources by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/788
* refactor(storage): update backup job to run every 4 hours by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/789
* Refactor(auth)  update yaml schemas and linting configurations for authentik blueprints by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/790
* feat(auth): add OAuth2 SSO integration for Open WebUI and update blueprints by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/791
* chore(deps): update all dependencies to v72.9.1 (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/792
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/793
* Update zone.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/796
* chore(deps): update terraform proxmox to v0.78.1 by @renovate in https://github.com/theepicsaxguy/homelab/pull/795
* Update webui-deployment.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/797
* chore: disable default login by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/798
* chore(deps): update all dependencies to v73 (major) by @renovate in https://github.com/theepicsaxguy/homelab/pull/799
* Fix documentation sidebar spelling by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/800
* Remove hardcoded versions from docs by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/804
* Fix README environment description by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/803
* Update authentik blueprints for env-based OAuth credentials by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/801
* chore(deps): update all dependencies to v73.1.0 (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/805
* Fix workspace schema paths by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/808
* Add Codex agent guide by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/807
* chore(deps): update helm release authentik to v2025.6.0 by @renovate in https://github.com/theepicsaxguy/homelab/pull/809
* fix(ci): monitor Dockerfile updates by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/811
* feat(auth): add groups and users blueprints by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/812
* fix(network): align coredns forwarders by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/813
* k8s(apps): verify resource constraints by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/817
* docs(website): fix template links by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/816
* docs(tofu): fix heading spacing by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/815


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v2.6.3...v2.7.0

## 2.6.3 (2025-05-31)

## What's Changed
* Refactor(k8s)  update http route backend reference and add frigate blueprints by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/754
* chore(deps): update helm release redis to v21.1.11 by @renovate in https://github.com/theepicsaxguy/homelab/pull/753
* Update account.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/756
* chore(deps): update all dependencies to v72.8.0 (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/757
* Update recurringjob.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/758
* chore(deps): update helm release argo-cd to v8.0.14 by @renovate in https://github.com/theepicsaxguy/homelab/pull/759
* fix(storage): increase PVC size from 10Gi to 20Gi by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/783
* chore(k8s): remove obsolete torrent application resources by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/782
* fix(tofu): add lifecycle block to ignore specific disk changes by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/785
* Theepicsaxguy/issue775 by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/784


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v2.6.2...v2.6.3

## 2.6.2 (2025-05-30)

## What's Changed
* chore(deps): update ghcr.io/immich-app/immich-machine-learning docker tag to v1.134.0 by @renovate in https://github.com/theepicsaxguy/homelab/pull/727
* Add Crossplane and Cloudflare DNS configurations by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/710
* fix: changed crossplane provider by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/729
* chore(deps): update helm release argo-cd to v8.0.11 by @renovate in https://github.com/theepicsaxguy/homelab/pull/726
* fix: create images/spilo/Dockerfile by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/731
* Create image-build.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/732
* Update Dockerfile by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/733
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/734
* fix: Add Cloudflare resources for zone and account by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/736
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/735
* fix(ci): correct Dockerfile path detection and update image tags by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/737
* chore(deps): update docker/build-push-action action to v6 by @renovate in https://github.com/theepicsaxguy/homelab/pull/738
* chore(deps): update all dependencies to v72.6.4 (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/740
* fix(k8s): modified Dockerfile for spilo17-vchord image and update database.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/739
* Add-blueprints-for-various-applications-and-services-in-Authentik by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/730
* Fix duplicate Bitwarden ID in secrets.yml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/741
* chore(deps): update helm release redis to v21.1.10 by @renovate in https://github.com/theepicsaxguy/homelab/pull/742
* chore: Update secrets by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/743
* Update secrets.yml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/744
* Update values.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/745
* Fix Authentik PostgreSQL keys in values.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/746
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.13 by @renovate in https://github.com/theepicsaxguy/homelab/pull/747
* Refactor(k8s)--update-authentik-secrets-configuration-for-clarity by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/748
* refactor(k8s): update authentik blueprints and remove deprecated outpost by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/751
* chore(deps): update helm release argo-cd to v8.0.13 by @renovate in https://github.com/theepicsaxguy/homelab/pull/749
* refactor(k8s): clean up kustomization.yaml and update deployment strategy by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/752
* chore(deps): update all dependencies to v72.7.0 (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/750


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v2.6.1...v2.6.2

## 2.6.1 (2025-05-28)

## What's Changed
* fix: Implement VectorChord for immich database by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/699
* fix(k8s): replace Helm chart with Kubernetes manifests and update documentation by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/702
* fix(argocd): update resource requests and limits for repoServer by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/705
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/703
* fix(k8s): increase resource limits and shared memory for Frigate and Immich by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/706
* chore(deps): update ghcr.io/immich-app/immich-server docker tag to v1.133.1 by @renovate in https://github.com/theepicsaxguy/homelab/pull/707
* chore(deps): update helm release redis to v21 by @renovate in https://github.com/theepicsaxguy/homelab/pull/704
* chore(ci): update permissions for release-please workflow by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/708
* fix(k8s): reduce shared memory and PVC size for Frigate configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/709
* chore(deps): update helm release argo-cd to v8.0.10 by @renovate in https://github.com/theepicsaxguy/homelab/pull/711
* fix(k8s): correct docker image and extension names in database configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/712
* fix(k8s): update docker image and correct extension name in database config by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/713
* fix: correct database image by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/714
* fix(k8s): correct extension name for vchord in database configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/715
* chore(deps): update helm release redis to v21.1.7 by @renovate in https://github.com/theepicsaxguy/homelab/pull/716
* chore(deps): update helm release kube-prometheus-stack to v72.6.3 by @renovate in https://github.com/theepicsaxguy/homelab/pull/717
* fix(k8s): update docker image for immich-postgresql to specific SHA by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/718
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.11 by @renovate in https://github.com/theepicsaxguy/homelab/pull/719
* chore: Update database image by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/720
* chore: Update database.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/721
* fix: Update database extensions by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/723
* fix(deps): update all dependencies (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/722
* chore(deps): update ghcr.io/immich-app/immich-server docker tag to v1.134.0 by @renovate in https://github.com/theepicsaxguy/homelab/pull/724
* chore(deps): update helm release redis to v21.1.8 by @renovate in https://github.com/theepicsaxguy/homelab/pull/725


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v2.6.0...v2.6.1

## 2.6.0 (2025-05-22)

## What's Changed
* chore(deps): update terraform proxmox to v0.78.0 by @renovate in https://github.com/theepicsaxguy/homelab/pull/646
* Refactor-blog-and-configuration-files;-update-styles-and-assets by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/647
* refactor(k8s): update HTTPRoute configurations for frigate by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/648
* chore(deps): update helm release argo-cd to v8.0.2 by @renovate in https://github.com/theepicsaxguy/homelab/pull/649
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/652
* chore(deps): update dependency siderolabs/talos to v1.10.2 by @renovate in https://github.com/theepicsaxguy/homelab/pull/653
* chore(deps): update registry.k8s.io/git-sync/git-sync docker tag to v4.4.1 by @renovate in https://github.com/theepicsaxguy/homelab/pull/654
* chore(deps): update all dependencies (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/651
* Add transformer to kustomization files by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/655
* Create common/rollout-transform.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/656
* chore(deps): update all dependencies to v72.5.0 (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/657
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/658
* Update externalsecret.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/659
* Update values.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/660
* chore(deps): update helm release argo-cd to v8.0.4 by @renovate in https://github.com/theepicsaxguy/homelab/pull/661
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/662
* Update service.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/663
* Implemented dex for argocd by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/664
* chore(deps): update ghcr.io/open-webui/open-webui docker tag to v0.6.10 by @renovate in https://github.com/theepicsaxguy/homelab/pull/667
* Create helm-charts.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/668
* Update helm-charts.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/669
* Create helm-chart.md by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/670
* chore(deps): update all dependencies (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/671
* feat(k8s): add Immich application resources and configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/672
* refactor(k8s): change creationPolicy to Merge for argocd-secret by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/674
* fix(k8s): disable admin access in ArgoCD configuration by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/675
* refactor(k8s): update resource requests and limits for PostgreSQL instances by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/676
* chore(deps): update helm release argo-cd to v8.0.6 by @renovate in https://github.com/theepicsaxguy/homelab/pull/677
* Feat(k8s)--update-Frigate-configuration-and-add-upgrade-guide-for-Talos by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/678
* Cleaned-up-configurations-by-removing-obsolete-variables  by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/650
* fix(k8s): update backend port for immich server in HTTPRoute by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/679
* feat(k8s): add authsecret for OIDC client credentials by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/680
* chore(deps): update terraform kubernetes to ~> 2.37.0 by @renovate in https://github.com/theepicsaxguy/homelab/pull/682
* chore(deps): update all dependencies to v72.5.2 (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/681
* chore(deps): update all dependencies to v72.5.3 (patch) by @renovate in https://github.com/theepicsaxguy/homelab/pull/683
* Feat(k8s)  add external secret for min io longhorn backup by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/684
* perf(k8s): increase resource requests and limits for jellyfin deployment by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/685
* Chore(k8s)  remove unused argo rollouts resources and configurations by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/686
* chore(deps): update helm release argo-cd to v8.0.7 by @renovate in https://github.com/theepicsaxguy/homelab/pull/687
* chore: upgrade immich by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/688
* chore(deps): update helm release argo-cd to v8.0.9 by @renovate in https://github.com/theepicsaxguy/homelab/pull/690
* chore(deps): update all dependencies to v72.6.2 (minor) by @renovate in https://github.com/theepicsaxguy/homelab/pull/691
* Update release-please.yml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/689
* Update release-please.yml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/692
* fix(longhorn): switch configMapGenerator behavior to merge for safer … by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/693
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/694
* Update kustomization.yaml by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/695
* Chore(longhorn)  remove backup.yaml from config map generator by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/696
* chore(release): update release-please configuration for better change… by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/697
* chore(release): remove version from pull request header for consistency by @theepicsaxguy in https://github.com/theepicsaxguy/homelab/pull/698


**Full Changelog**: https://github.com/theepicsaxguy/homelab/compare/v2.5.0...v2.6.0

## [2.5.0](https://github.com/theepicsaxguy/homelab/compare/v2.4.0...v2.5.0) (2025-05-13)


### Features

* **k8s:** add whisperasr deployment and service configuration ([#616](https://github.com/theepicsaxguy/homelab/issues/616)) ([bafe4a9](https://github.com/theepicsaxguy/homelab/commit/bafe4a9a5f2945791146ca9d61679d2d18f02e20))
* **k8s:** update frigate HTTPRoute and add Authentik Outpost configuration ([#623](https://github.com/theepicsaxguy/homelab/issues/623)) ([81de4f2](https://github.com/theepicsaxguy/homelab/commit/81de4f29e1b169ff96bfabeac2a936d46a81ca21))
* **website:** enhance homepage with new sections and styling ([#643](https://github.com/theepicsaxguy/homelab/issues/643)) ([56bbe20](https://github.com/theepicsaxguy/homelab/commit/56bbe20762e3e3e990f5344895e854f77304e985))


### Bug Fixes

* **k8s:** correct HTTPRoute name and backend reference for frigate ([#625](https://github.com/theepicsaxguy/homelab/issues/625)) ([1ad965c](https://github.com/theepicsaxguy/homelab/commit/1ad965c4eee4bf96b3ca97ac5a546cab0f08e074))
* **k8s:** update OIDC issuer URL for authentik configuration ([#612](https://github.com/theepicsaxguy/homelab/issues/612)) ([db644ee](https://github.com/theepicsaxguy/homelab/commit/db644eeac7cc0b86b5033d015c739e7e3044fdad))

## [2.4.0](https://github.com/theepicsaxguy/homelab/compare/v2.3.0...v2.4.0) (2025-05-05)


### Features

* **k8s:** add automation and MQTT configurations ([#587](https://github.com/theepicsaxguy/homelab/issues/587)) ([7ad437e](https://github.com/theepicsaxguy/homelab/commit/7ad437e7fd94540cdfadf35ce96e8ddcd59407a8))
* **k8s:** add HTTPRoute for argocd webhook ([#579](https://github.com/theepicsaxguy/homelab/issues/579)) ([1e29074](https://github.com/theepicsaxguy/homelab/commit/1e29074f03f565d368b56d31349cf1fdd453fdcf))


### Bug Fixes

* **k8s:** add missing DNS entry for cilium-gateway-external ([#578](https://github.com/theepicsaxguy/homelab/issues/578)) ([29562ff](https://github.com/theepicsaxguy/homelab/commit/29562ff8e7470563f88ae7e2560c3d617ca05b6e))
* **k8s:** increase memory limit for controller to 2Gi ([#577](https://github.com/theepicsaxguy/homelab/issues/577)) ([95ab6ef](https://github.com/theepicsaxguy/homelab/commit/95ab6efdd559aa24d25ef712e87c7283306c4d50))
* **k8s:** update argocd webhook hostname in cloudflared config ([#581](https://github.com/theepicsaxguy/homelab/issues/581)) ([258fd82](https://github.com/theepicsaxguy/homelab/commit/258fd82888438208708733a29c735f0e025721e7))
* **k8s:** update cert-manager CRD version in kustomization.yaml ([#575](https://github.com/theepicsaxguy/homelab/issues/575)) ([8126055](https://github.com/theepicsaxguy/homelab/commit/81260559121f6f923be55de6bef19a54f13a69dc))
* **k8s:** update kubechecks role permissions in values.yaml ([#580](https://github.com/theepicsaxguy/homelab/issues/580)) ([3bf02bb](https://github.com/theepicsaxguy/homelab/commit/3bf02bbb8101cfb9c03e385a689921d5092181da))

## [2.3.0](https://github.com/theepicsaxguy/homelab/compare/v2.2.0...v2.3.0) (2025-05-03)


### Features

* **k8s:** add Bazarr deployment and service configuration ([#552](https://github.com/theepicsaxguy/homelab/issues/552)) ([6d3315e](https://github.com/theepicsaxguy/homelab/commit/6d3315e8f0f764a9c549163fbfcacd4af1cbebfa))
* **k8s:** add configMapGenerator for AdGuard configuration ([#567](https://github.com/theepicsaxguy/homelab/issues/567)) ([8c4e733](https://github.com/theepicsaxguy/homelab/commit/8c4e7336c2042b7a6ee134934917fbacd441f27b))
* **k8s:** add Omada controller deployment and related resources ([#565](https://github.com/theepicsaxguy/homelab/issues/565)) ([857e81c](https://github.com/theepicsaxguy/homelab/commit/857e81c40b61b20cdc549cc2e1ff11a24b29c335))
* **k8s:** enhance rollout configuration with health checks and analysis ([#561](https://github.com/theepicsaxguy/homelab/issues/561)) ([8f889e1](https://github.com/theepicsaxguy/homelab/commit/8f889e155d57894fe2c8831239596becce5000a3))
* **k8s:** implement blue-green deployment strategy for applications ([#571](https://github.com/theepicsaxguy/homelab/issues/571)) ([527f372](https://github.com/theepicsaxguy/homelab/commit/527f372845aa0ad3ecdd5f1ab855e282372c763b))
* **k8s:** update AdGuard deployment with persistent volume claim ([#560](https://github.com/theepicsaxguy/homelab/issues/560)) ([7a9b432](https://github.com/theepicsaxguy/homelab/commit/7a9b432adba78c57208f34f3454127c14627c49a))
* **k8s:** update Bazarr deployment to use new configMap reference ([#554](https://github.com/theepicsaxguy/homelab/issues/554)) ([58af7ab](https://github.com/theepicsaxguy/homelab/commit/58af7ab667249b9aa660ed0f33b219ff22a2653e))
* **k8s:** update resource requests and limits for open-webui deployment ([#572](https://github.com/theepicsaxguy/homelab/issues/572)) ([c45a067](https://github.com/theepicsaxguy/homelab/commit/c45a0671e797ecf5629b31b0470055a3b67263b0))
* **networking:** implement AdGuard deployment with init containers ([#566](https://github.com/theepicsaxguy/homelab/issues/566)) ([bc715c1](https://github.com/theepicsaxguy/homelab/commit/bc715c135d82884c615110f89aa486b229e55c96))


### Bug Fixes

* **k8s:** update Bazarr security context to allow read-write filesystem ([#556](https://github.com/theepicsaxguy/homelab/issues/556)) ([2eed9d9](https://github.com/theepicsaxguy/homelab/commit/2eed9d9de7d68ffacc460103f4500ec13a259625))

## [2.2.0](https://github.com/theepicsaxguy/homelab/compare/v2.1.0...v2.2.0) (2025-05-01)


### Features

* **k8s:** add deployment, service, and external secret for pedro-bot ([#498](https://github.com/theepicsaxguy/homelab/issues/498)) ([b394df2](https://github.com/theepicsaxguy/homelab/commit/b394df250e32d9644400fd27e57920d839e29ca0))
* **k8s:** add HTTPS route for omada service ([#502](https://github.com/theepicsaxguy/homelab/issues/502)) ([9675e13](https://github.com/theepicsaxguy/homelab/commit/9675e13e47bfcb216ec021c0d999941a8688e6c2))
* **k8s:** add karakeep application resources ([#515](https://github.com/theepicsaxguy/homelab/issues/515)) ([5d3d62f](https://github.com/theepicsaxguy/homelab/commit/5d3d62fe43ce9054d33e6ab393dd4576b8638d0b))
* **k8s:** add omada certificate and update references ([#505](https://github.com/theepicsaxguy/homelab/issues/505)) ([25752ad](https://github.com/theepicsaxguy/homelab/commit/25752ad436cda31462c1100c17542504d05a31d6))
* **k8s:** add sabnzbd deployment and associated resources ([#547](https://github.com/theepicsaxguy/homelab/issues/547)) ([d7c3e64](https://github.com/theepicsaxguy/homelab/commit/d7c3e64d979f9159361574eab357d8e9ba87cfec))
* **k8s:** implement TLS passthrough and certificate management for omada ([#546](https://github.com/theepicsaxguy/homelab/issues/546)) ([77f342e](https://github.com/theepicsaxguy/homelab/commit/77f342eeab53b3b591d8f3584a64de0890bbbbcc))
* **k8s:** update jellyseerr service configuration ([#517](https://github.com/theepicsaxguy/homelab/issues/517)) ([929626e](https://github.com/theepicsaxguy/homelab/commit/929626e0c2b862f8e0b4d285bbae801d4ee9545f))
* **networking:** add HTTPRoute and Namespace for omada service ([#480](https://github.com/theepicsaxguy/homelab/issues/480)) ([0ec0f84](https://github.com/theepicsaxguy/homelab/commit/0ec0f84cc26a1bcf8ad9e22f6d4b868d59cc331f))
* **networking:** add TLS route and certificate for omada ([#499](https://github.com/theepicsaxguy/homelab/issues/499)) ([cfeed5b](https://github.com/theepicsaxguy/homelab/commit/cfeed5bdcf58016497146e7a7c1b8437a4300e7e))


### Bug Fixes

* **k8s:** update jellyfin hostname and timezone configuration ([#516](https://github.com/theepicsaxguy/homelab/issues/516)) ([ce5888f](https://github.com/theepicsaxguy/homelab/commit/ce5888f1ff8a5366bcf398c902b3b34cd3009f55))
* **k8s:** update jellyseerr and omada configurations for port changes ([#533](https://github.com/theepicsaxguy/homelab/issues/533)) ([1e5f43b](https://github.com/theepicsaxguy/homelab/commit/1e5f43b5b7a2b1a2ee2eb0208d8f83a4a40a1024))
* **k8s:** update jellyseerr service port and remove unused PVC ([#532](https://github.com/theepicsaxguy/homelab/issues/532)) ([b0fb271](https://github.com/theepicsaxguy/homelab/commit/b0fb2715adb7f53d40907b38121cb0b4dea92615))
* **k8s:** update meilisearch deployment init container and security context ([#527](https://github.com/theepicsaxguy/homelab/issues/527)) ([af500f6](https://github.com/theepicsaxguy/homelab/commit/af500f6021c2d1aaecfaff1d042e60dcd68b0991))


### Performance Improvements

* **k8s:** increase CPU resource requests and limits for open-webui ([#528](https://github.com/theepicsaxguy/homelab/issues/528)) ([95acdfa](https://github.com/theepicsaxguy/homelab/commit/95acdfa42a96ea651acba6ed800e79dba0eba050))
* **k8s:** increase resource limits for omada-controller deployment ([#545](https://github.com/theepicsaxguy/homelab/issues/545)) ([287ffc2](https://github.com/theepicsaxguy/homelab/commit/287ffc29e270f9f9c6a786daba4ab6d3b25bf254))

## [2.1.0](https://github.com/theepicsaxguy/homelab/compare/v2.0.0...v2.1.0) (2025-04-17)


### Features

* **k8s:** add external application management resources ([#377](https://github.com/theepicsaxguy/homelab/issues/377)) ([a77461a](https://github.com/theepicsaxguy/homelab/commit/a77461adc24caa9721862e564fb7ed4d1d4347e8))
* **k8s:** add HTTPRoute for hoarder-web and remove Ingress sample ([#380](https://github.com/theepicsaxguy/homelab/issues/380)) ([e1416fb](https://github.com/theepicsaxguy/homelab/commit/e1416fb361bee2852231af7c66e1ec407499ec76))

## [2.0.0](https://github.com/theepicsaxguy/homelab/compare/v1.17.0...v2.0.0) (2025-04-13)


### ⚠ BREAKING CHANGES

* **network-policy:** Changed API responses from 'hostname' to 'dnsNames' in the gateway specification.

### Features

* **k8s:** add Hoarder application deployment and configuration ([#307](https://github.com/theepicsaxguy/homelab/issues/307)) ([0cf58a4](https://github.com/theepicsaxguy/homelab/commit/0cf58a47d789e87ce87598b68d6cec7467dc220a))
* **k8s:** add HTTPRoute configuration for it-tools ([#358](https://github.com/theepicsaxguy/homelab/issues/358)) ([1e90d98](https://github.com/theepicsaxguy/homelab/commit/1e90d986575a327b1d9c2e6fd06c235040667a74))
* **k8s:** add HTTPRoute configurations for Argo Rollouts and Longhorn ([#352](https://github.com/theepicsaxguy/homelab/issues/352)) ([57cbe3c](https://github.com/theepicsaxguy/homelab/commit/57cbe3cf9be6d43de36420a505bdf365e093e2cf))
* **k8s:** add KUBECHECKS_ARGOCD_API_INSECURE environment variable ([#351](https://github.com/theepicsaxguy/homelab/issues/351)) ([7a3e130](https://github.com/theepicsaxguy/homelab/commit/7a3e13084d092e116638c26b47a0e2c730ef8b8f))
* **k8s:** add monitoring stack with Prometheus and Grafana ([#313](https://github.com/theepicsaxguy/homelab/issues/313)) ([2a75469](https://github.com/theepicsaxguy/homelab/commit/2a75469b97111bfa7409618dd31fa17028b0a704))
* **k8s:** implement kubechecks deployment with external secrets ([#356](https://github.com/theepicsaxguy/homelab/issues/356)) ([550dd90](https://github.com/theepicsaxguy/homelab/commit/550dd905f33dcc951737b35acb3034c68c8a591f))
* **k8s:** update HTTPRoute hostnames and kustomization configurations ([#348](https://github.com/theepicsaxguy/homelab/issues/348)) ([32e089b](https://github.com/theepicsaxguy/homelab/commit/32e089b1b419e5908e81cbd5a64fe69cfb9455e9))
* **tofu:** add extra mounts and kernel modules to machine config ([#310](https://github.com/theepicsaxguy/homelab/issues/310)) ([66425f3](https://github.com/theepicsaxguy/homelab/commit/66425f3143cd7526792039acc7ed332d605dc938))


### Code Refactoring

* **network-policy:** enhanced security settings ([#304](https://github.com/theepicsaxguy/homelab/issues/304)) ([187d68d](https://github.com/theepicsaxguy/homelab/commit/187d68d69e1141f80957faa1e962baec09ba7543)), closes [#5678](https://github.com/theepicsaxguy/homelab/issues/5678)

## [1.17.0](https://github.com/theepicsaxguy/homelab/compare/v1.16.0...v1.17.0) (2025-03-23)


### Features

* **cert-manager:** add Bitwarden issuer and certificate configurations ([#301](https://github.com/theepicsaxguy/homelab/issues/301)) ([12e6d26](https://github.com/theepicsaxguy/homelab/commit/12e6d2625faf60afab0c295ca65ed9093a3cc197))
* **external-secrets:** add ClusterRole and ClusterRoleBinding for clusterpushsecret ([#290](https://github.com/theepicsaxguy/homelab/issues/290)) ([910c14f](https://github.com/theepicsaxguy/homelab/commit/910c14f818e8ad70580afab8295191d86171eb20))
* **k8s:** add Cilium network policies for cert-manager and external-secrets ([#264](https://github.com/theepicsaxguy/homelab/issues/264)) ([2083501](https://github.com/theepicsaxguy/homelab/commit/208350162390270c5e0e4b181acb95e24da59c36))
* **k8s:** add CoreDNS deployment and update configurations ([#253](https://github.com/theepicsaxguy/homelab/issues/253)) ([622d4ee](https://github.com/theepicsaxguy/homelab/commit/622d4eef0df12e4f61baa7baad8e5c5da5563695))
* **k8s:** add namespaces for various components ([#238](https://github.com/theepicsaxguy/homelab/issues/238)) ([9ba98e0](https://github.com/theepicsaxguy/homelab/commit/9ba98e086ed1f2912f52bf5e09a7159b5dd576e6))
* **k8s:** allowlist specific namespaces for resource management ([#225](https://github.com/theepicsaxguy/homelab/issues/225)) ([b80662f](https://github.com/theepicsaxguy/homelab/commit/b80662f17c8f22f611b7e0eabc112497e8f7f9b1))
* **k8s:** change ArgoCD service type to LoadBalancer ([#242](https://github.com/theepicsaxguy/homelab/issues/242)) ([3082725](https://github.com/theepicsaxguy/homelab/commit/3082725d38bb9eb2b1a127386d90c0e28ca4c097))
* **k8s:** enhance ArgoCD and cert-manager network policies ([#303](https://github.com/theepicsaxguy/homelab/issues/303)) ([736c5c1](https://github.com/theepicsaxguy/homelab/commit/736c5c1385e0c96beecc7fb045d73937edd84c18))
* **k8s:** enhance namespace management and add webhook policies ([#232](https://github.com/theepicsaxguy/homelab/issues/232)) ([72cbdea](https://github.com/theepicsaxguy/homelab/commit/72cbdea8d6a7025d288ed810107490ee2f6f8e98))
* **k8s:** enhance namespace management with dynamic allowlist updates ([#224](https://github.com/theepicsaxguy/homelab/issues/224)) ([c0e4ce9](https://github.com/theepicsaxguy/homelab/commit/c0e4ce919ec72cc425c13ade07bbb7959ea95804))
* **k8s:** enhance network policies and configurations for ArgoCD and Open WebUI ([#262](https://github.com/theepicsaxguy/homelab/issues/262)) ([9301f98](https://github.com/theepicsaxguy/homelab/commit/9301f988ac5b00e91ff26c80c1bde0de9f3e0afd))
* **k8s:** implement ArgoCD network policy and update configurations ([#237](https://github.com/theepicsaxguy/homelab/issues/237)) ([bcb48f4](https://github.com/theepicsaxguy/homelab/commit/bcb48f47dd8b41c72c798daea32d7dc1c3d05d39))
* **k8s:** implement dynamic resource scaling for improved efficiency ([#227](https://github.com/theepicsaxguy/homelab/issues/227)) ([f10a63a](https://github.com/theepicsaxguy/homelab/commit/f10a63a0edf4d3a16c6c89ce798603e0e90576f3))
* **k8s:** introduce service accounts and services for cert-manager ([#265](https://github.com/theepicsaxguy/homelab/issues/265)) ([d99bba0](https://github.com/theepicsaxguy/homelab/commit/d99bba083434f47bd4441da71be6f139eaecacdb))
* **k8s:** reorganize application configurations and add new resources ([#222](https://github.com/theepicsaxguy/homelab/issues/222)) ([ddd6148](https://github.com/theepicsaxguy/homelab/commit/ddd61488413b3fc4f1d507f7a5c7a9b7af919d28))
* **k8s:** update ArgoCD and Cilium configurations ([#239](https://github.com/theepicsaxguy/homelab/issues/239)) ([d2795a0](https://github.com/theepicsaxguy/homelab/commit/d2795a0ed00f51030d2c4e64102ae6da2096b767))
* **k8s:** update Bitwarden configurations for external secrets ([#302](https://github.com/theepicsaxguy/homelab/issues/302)) ([1d4d464](https://github.com/theepicsaxguy/homelab/commit/1d4d46455c68730c668eee6538bd983a8a3af228))
* **k8s:** update CoreDNS values.yaml configuration ([#257](https://github.com/theepicsaxguy/homelab/issues/257)) ([0c461cd](https://github.com/theepicsaxguy/homelab/commit/0c461cd2fe1ffdf88385fd66fd56a7c448729547))
* **k8s:** update kustomization files to include additional resources ([#226](https://github.com/theepicsaxguy/homelab/issues/226)) ([cc50dd2](https://github.com/theepicsaxguy/homelab/commit/cc50dd2a6cd71729e4623578e15825641b7f1bb7))
* **networking:** update CoreDNS configuration and add service definition ([#298](https://github.com/theepicsaxguy/homelab/issues/298)) ([7c1df8c](https://github.com/theepicsaxguy/homelab/commit/7c1df8c5764f99548749aba134bc9a2d4d4c8333))
* **tofu:** update Talos configuration for Kubernetes version 1.32.0 ([#292](https://github.com/theepicsaxguy/homelab/issues/292)) ([e9900f1](https://github.com/theepicsaxguy/homelab/commit/e9900f1b617c714317584aee963243bda524e001))


### Bug Fixes

* **networking:** update Cilium network policy for ArgoCD and remove Authelia configurations ([#291](https://github.com/theepicsaxguy/homelab/issues/291)) ([1614f12](https://github.com/theepicsaxguy/homelab/commit/1614f12f96f8a85192218e60963daa2ccdd62b52))

## [1.16.0](https://github.com/theepicsaxguy/homelab/compare/v1.15.0...v1.16.0) (2025-03-09)


### Features

* **k8s:** add ApplicationSet and kubechecks for cluster management ([#208](https://github.com/theepicsaxguy/homelab/issues/208)) ([2004ae4](https://github.com/theepicsaxguy/homelab/commit/2004ae46da22d116ddfb52065c1f43427bec713f))
* **k8s:** add kustomization for external secrets management ([#183](https://github.com/theepicsaxguy/homelab/issues/183)) ([723533e](https://github.com/theepicsaxguy/homelab/commit/723533e5037b99dfded168728a71d31eaa0fc582))
* **k8s:** add new namespaces and configuration files ([#212](https://github.com/theepicsaxguy/homelab/issues/212)) ([eb7de23](https://github.com/theepicsaxguy/homelab/commit/eb7de23f201ac2b9ce2cbb049f87d57ae9d266df))
* **k8s:** implement dynamic namespace management in ArgoCD ([#220](https://github.com/theepicsaxguy/homelab/issues/220)) ([e9c0df8](https://github.com/theepicsaxguy/homelab/commit/e9c0df82ad607b015a1dd0160817ecedd2cb1bb2))
* **k8s:** integrate Bitwarden Secrets Manager with External Secrets Operator ([#193](https://github.com/theepicsaxguy/homelab/issues/193)) ([364105b](https://github.com/theepicsaxguy/homelab/commit/364105bf0da8300df86329cabc264879d014a456))
* **k8s:** modularize Kustomize overlays and enhance namespace management ([#216](https://github.com/theepicsaxguy/homelab/issues/216)) ([c8a28d3](https://github.com/theepicsaxguy/homelab/commit/c8a28d3de36ea1718eb5b5439b8d81fedd418205))

## [1.15.0](https://github.com/theepicsaxguy/homelab/compare/v1.14.0...v1.15.0) (2025-03-04)


### Features

* **k8s:** add sm-operator network policy and update RBAC rules ([#173](https://github.com/theepicsaxguy/homelab/issues/173)) ([a5ea082](https://github.com/theepicsaxguy/homelab/commit/a5ea08216213942fe26a6bd2d5817faa068756b6))
* **k8s:** enhance Cilium configuration and add DNS policy ([#175](https://github.com/theepicsaxguy/homelab/issues/175)) ([71b5f5b](https://github.com/theepicsaxguy/homelab/commit/71b5f5b8b407c18d7dc0153d649b11256cc73d10))
* **k8s:** enhance Cilium configuration and management ([#156](https://github.com/theepicsaxguy/homelab/issues/156)) ([67cc113](https://github.com/theepicsaxguy/homelab/commit/67cc113a0a7bed1b0fa7598000a421b330fbd899))
* **k8s:** enhance infrastructure configuration and security policies ([#150](https://github.com/theepicsaxguy/homelab/issues/150)) ([56198ed](https://github.com/theepicsaxguy/homelab/commit/56198eda05ded7ad6418d7a0cf83682e061fa3f7))
* **k8s:** implement sm-operator resources and remove kubechecks ([#160](https://github.com/theepicsaxguy/homelab/issues/160)) ([c46cafa](https://github.com/theepicsaxguy/homelab/commit/c46cafa6619888e75a551255baed5f44528cf457))
* **k8s:** implement Unbound DNS configuration with new deployment ([#164](https://github.com/theepicsaxguy/homelab/issues/164)) ([37abf5b](https://github.com/theepicsaxguy/homelab/commit/37abf5bde107e31caf35c1e916c62b1e64118f71))
* **k8s:** integrate external secrets management for multiple components ([#178](https://github.com/theepicsaxguy/homelab/issues/178)) ([566fe21](https://github.com/theepicsaxguy/homelab/commit/566fe21d9927732bd39f8c4e3035e725096014be))
* **k8s:** update AdGuardHome configuration and add new HTTP routes ([#143](https://github.com/theepicsaxguy/homelab/issues/143)) ([7b9c233](https://github.com/theepicsaxguy/homelab/commit/7b9c2335441c68f6525bf1a2958a78cc718e4d9a))
* **security, networking:** enhance Cilium security and update Gateway API documentation ([#152](https://github.com/theepicsaxguy/homelab/issues/152)) ([7297ed8](https://github.com/theepicsaxguy/homelab/commit/7297ed8d40d09f275e780517ee930230a8dc8ce2))


### Bug Fixes

* **k8s:** correct DNS configuration and improve deployment security ([#163](https://github.com/theepicsaxguy/homelab/issues/163)) ([4c6987e](https://github.com/theepicsaxguy/homelab/commit/4c6987ee583de8abeac22583e0a36aaa936e08f6))
* **k8s:** update bootstrap DNS configuration for AdGuardHome ([#166](https://github.com/theepicsaxguy/homelab/issues/166)) ([74a5f87](https://github.com/theepicsaxguy/homelab/commit/74a5f8767d296b79c7219550266bed40eb4a22e0))

## [1.14.0](https://github.com/theepicsaxguy/homelab/compare/v1.13.0...v1.14.0) (2025-02-26)


### Features

* **k8s:** update AdGuardHome and gateway configurations ([#140](https://github.com/theepicsaxguy/homelab/issues/140)) ([2ad2e25](https://github.com/theepicsaxguy/homelab/commit/2ad2e25ccd4d75221731afce08ad96f1205d10f4))

## [1.13.0](https://github.com/theepicsaxguy/homelab/compare/v1.12.0...v1.13.0) (2025-02-26)

### Features

- **k8s:** enhance AdGuardHome and Cilium configurations with troubleshooting documentation
  ([#135](https://github.com/theepicsaxguy/homelab/issues/135))
  ([5ded39a](https://github.com/theepicsaxguy/homelab/commit/5ded39aa3fd55c7e97537a583717ddef9a75b4ad))

## [1.12.0](https://github.com/theepicsaxguy/homelab/compare/v1.11.0...v1.12.0) (2025-02-26)

### Features

- **k8s:** enhance validation script and ApplicationSet configurations
  ([#131](https://github.com/theepicsaxguy/homelab/issues/131))
  ([ddf1fb7](https://github.com/theepicsaxguy/homelab/commit/ddf1fb7ada922cbdc668aa6f448f10c13d1e3070))
- **k8s:** integrate and enhance Kubechecks for GitOps workflow
  ([#133](https://github.com/theepicsaxguy/homelab/issues/133))
  ([ad73e6f](https://github.com/theepicsaxguy/homelab/commit/ad73e6f224628705db1237c26c022e1bb6a3e198))

## [1.11.0](https://github.com/theepicsaxguy/homelab/compare/v1.10.0...v1.11.0) (2025-02-24)

### Features

- **k8s:** update Kustomization and ApplicationSet configurations
  ([#115](https://github.com/theepicsaxguy/homelab/issues/115))
  ([ba2851d](https://github.com/theepicsaxguy/homelab/commit/ba2851de49b3300f29288b94efaa818e687b91d8))

## [1.10.0](https://github.com/theepicsaxguy/homelab/compare/v1.9.0...v1.10.0) (2025-02-23)

### Features

- **security:** add Bitwarden Secrets Manager bootstrap documentation
  ([#111](https://github.com/theepicsaxguy/homelab/issues/111))
  ([f0bcb07](https://github.com/theepicsaxguy/homelab/commit/f0bcb071956ec9365c6c1eb20b6eb474ef1e5faa))

## [1.9.0](https://github.com/theepicsaxguy/homelab/compare/v1.8.0...v1.9.0) (2025-02-23)

### Features

- **k8s:** enhance infrastructure project configuration with sync windows
  ([#104](https://github.com/theepicsaxguy/homelab/issues/104))
  ([609fd5c](https://github.com/theepicsaxguy/homelab/commit/609fd5ce836d39d8d5538927b08fcccdffbefb94))
- **k8s:** enhance rollout and analysis configurations for infrastructure
  ([#110](https://github.com/theepicsaxguy/homelab/issues/110))
  ([35301ee](https://github.com/theepicsaxguy/homelab/commit/35301eeb3d81a4d543393c3c874bbdd088a6c184))

## [1.8.0](https://github.com/theepicsaxguy/homelab/compare/v1.7.1...v1.8.0) (2025-02-23)

### Features

- **k8s:** add Argo Rollouts configuration and resource limits
  ([#102](https://github.com/theepicsaxguy/homelab/issues/102))
  ([d604013](https://github.com/theepicsaxguy/homelab/commit/d604013bdb2e6382795aa1765744fdd44917971b))

## [1.7.1](https://github.com/theepicsaxguy/homelab/compare/v1.7.0...v1.7.1) (2025-02-23)

### Bug Fixes

- **k8s:** correct allowEmpty syntax in ApplicationSet configurations
  ([#100](https://github.com/theepicsaxguy/homelab/issues/100))
  ([2ff9d0b](https://github.com/theepicsaxguy/homelab/commit/2ff9d0bf98afbee8e74da9c07f5729d329dc7d45))

## [1.7.0](https://github.com/theepicsaxguy/homelab/compare/v1.6.0...v1.7.0) (2025-02-23)

### Features

- **k8s:** enhance ApplicationSet configuration and add PR preview support
  ([#97](https://github.com/theepicsaxguy/homelab/issues/97))
  ([4662fbd](https://github.com/theepicsaxguy/homelab/commit/4662fbdefe57a1bbb56af8ab47d52071079b3c38))

## [1.6.0](https://github.com/theepicsaxguy/homelab/compare/v1.5.0...v1.6.0) (2025-02-22)

### Features

- **k8s:** enhance secret management with Bitwarden integration
  ([#93](https://github.com/theepicsaxguy/homelab/issues/93))
  ([03365f0](https://github.com/theepicsaxguy/homelab/commit/03365f09eec0f2d353935fada6647d80c33180bd))
- **k8s:** update Bitwarden API version and enhance project configuration
  ([#94](https://github.com/theepicsaxguy/homelab/issues/94))
  ([39061cb](https://github.com/theepicsaxguy/homelab/commit/39061cb87c2dcbb331f3dc1143786fb797f739fa))

### Bug Fixes

- **k8s:** correct DHCP service name and enhance AdGuard secret management
  ([#91](https://github.com/theepicsaxguy/homelab/issues/91))
  ([3965795](https://github.com/theepicsaxguy/homelab/commit/3965795711a5ac866e886a36f5ea45e4c2f963d5))

## [1.5.0](https://github.com/theepicsaxguy/homelab/compare/v1.4.2...v1.5.0) (2025-02-22)

### Features

- **k8s:** enhance kustomization and service configurations ([#88](https://github.com/theepicsaxguy/homelab/issues/88))
  ([857bb35](https://github.com/theepicsaxguy/homelab/commit/857bb358c8722360ed7063b8369694239b8dbbcb))

## [1.4.2](https://github.com/theepicsaxguy/homelab/compare/v1.4.1...v1.4.2) (2025-02-21)

### Bug Fixes

- update ([#74](https://github.com/theepicsaxguy/homelab/issues/74))
  ([3935c19](https://github.com/theepicsaxguy/homelab/commit/3935c19f42347dc41588f1dbb5cc78a6d40dd8ca))

## [1.4.1](https://github.com/theepicsaxguy/homelab/compare/v1.4.0...v1.4.1) (2025-02-21)

### Bug Fixes

- create CommitLint.yml ([#72](https://github.com/theepicsaxguy/homelab/issues/72))
  ([3eecc06](https://github.com/theepicsaxguy/homelab/commit/3eecc06c98b1dc8f5de546a4be061ff2cac5e05d))

## [1.4.0](https://github.com/theepicsaxguy/homelab/compare/v1.3.0...v1.4.0) (2025-02-20)

### Features

- **ci:** Add workflows to standardize commit messages and pull request titles
  ([#67](https://github.com/theepicsaxguy/homelab/issues/67))
  ([b2f184d](https://github.com/theepicsaxguy/homelab/commit/b2f184da8338bef32e89a08afd6e25e2125563c8))

## [1.3.0](https://github.com/theepicsaxguy/homelab/compare/v1.2.0...v1.3.0) (2025-02-20)

### Features

- **argocd:** enable Redis authentication and specify chart version for compatibility
  ([#65](https://github.com/theepicsaxguy/homelab/issues/65))
  ([f447b02](https://github.com/theepicsaxguy/homelab/commit/f447b020feefbf8eaa1b9872c3feabd5412e576d))

## [1.2.0](https://github.com/theepicsaxguy/homelab/compare/v1.1.0...v1.2.0) (2025-02-18)

### Features

- update common labels from dev.pctips to dev.pc-tips across k8s configurations
  ([#32](https://github.com/theepicsaxguy/homelab/issues/32))
  ([d73b8a5](https://github.com/theepicsaxguy/homelab/commit/d73b8a50bc53f6a82ed328f4e372e660beb1a45b))

## [1.1.0](https://github.com/theepicsaxguy/homelab/compare/v1.0.0...v1.1.0) (2025-02-17)

### Features

- add Bitwarden ESO provider configuration and namespace ([#29](https://github.com/theepicsaxguy/homelab/issues/29))
  ([82b2ae0](https://github.com/theepicsaxguy/homelab/commit/82b2ae024783da7a674daa64baddebfcd72480d8))

## 1.0.0 (2025-02-16)

### Features

- **access:** Extra admins in the cluster
  ([17a07d4](https://github.com/theepicsaxguy/homelab/commit/17a07d4fd8f1f1a8fa0c3eb33252a990328175ca))
- add Cert-manager ([fe368b9](https://github.com/theepicsaxguy/homelab/commit/fe368b937ed320a036b8713d86be611fc86bd403))
- add crossplane.io
  ([76ab7a7](https://github.com/theepicsaxguy/homelab/commit/76ab7a71a2a294e03b323e1229429432994b3aed))
- add extra admin user
  ([4dd769f](https://github.com/theepicsaxguy/homelab/commit/4dd769fdf742eb46e9cac9c023e5cd6b08ea28ef))
- add Gateway API and Gateways
  ([805ab61](https://github.com/theepicsaxguy/homelab/commit/805ab6101737f3c2acb8482a6b29287967d9fa13))
- add node-feature-discovery and intel-device-plugins
  ([ac16aed](https://github.com/theepicsaxguy/homelab/commit/ac16aed3d2ad5df761073e44f201750a9da4e972))
- **adguard:** mount config-file for declarative configuration
  ([872f33c](https://github.com/theepicsaxguy/homelab/commit/872f33c2952486f631c096ae5fb8a2c9216d9cad))
- **app:** Adding Deltahouse application
  ([37370e0](https://github.com/theepicsaxguy/homelab/commit/37370e093e603a4035ed99aa24b235cf9530d764))
- **applications:** Use a single ApplicationSet instead of individual Application manifests
  ([726886c](https://github.com/theepicsaxguy/homelab/commit/726886c87c0dfab35417393bb6a8740065bcca64))
- **apps:** Added Home Assistant application
  ([98d20d2](https://github.com/theepicsaxguy/homelab/commit/98d20d2d45c40bc0411a197199ffc74d9d99fb8a))
- **apps:** Starting to use Terraform and adding applications
  ([c450934](https://github.com/theepicsaxguy/homelab/commit/c450934d7771f9aca0006c85a74372ee7d43422e))
- **Argo CD:** Switch to Helm chart
  ([398b98c](https://github.com/theepicsaxguy/homelab/commit/398b98cfffbc064cf492d1c8af904c20d236e76d))
- **argocd:** Add an extra layer of security on ArgoCD interface
  ([a23fe82](https://github.com/theepicsaxguy/homelab/commit/a23fe826e191f67a44191450fe93bb2b2d91fa68))
- **argocd:** Adding ArgoCD
  ([7a9f9e2](https://github.com/theepicsaxguy/homelab/commit/7a9f9e281e4bbea589cf95d88123b217dcb9c05c))
- **argocd:** Copying necessary binaries from main ArgoCD image for use in kustomize-with-helm plugin
  ([8cead34](https://github.com/theepicsaxguy/homelab/commit/8cead343da162e4a97893e18802528630e753047))
- **argocd:** Creating AppProjects for ArgoCD
  ([a1a7d5c](https://github.com/theepicsaxguy/homelab/commit/a1a7d5c13f56963ea0899ee086bf48fdfbaa3eaa))
- **argocd:** Creating kustomize build with helm plugin
  ([f5da0ac](https://github.com/theepicsaxguy/homelab/commit/f5da0ac420c1e98c15a29f8e7b4b0225e159ecaf))
- **argocd:** Deploying Plex and HAss using ArgoCD
  ([6140fc8](https://github.com/theepicsaxguy/homelab/commit/6140fc8370210d00af7a244e85070c00df86cf46))
- **argocd:** Letting ArgoCD manage itself
  ([b4c0097](https://github.com/theepicsaxguy/homelab/commit/b4c00972e62541135f0f0163d6c2c08689f732ee))
- **arr:** Deploying arr-suite with ArgoCD
  ([24e0284](https://github.com/theepicsaxguy/homelab/commit/24e0284a56aacd5665598b320931357fe3c8f59a))
- **arr:** implement arr stack
  ([bd7ae1f](https://github.com/theepicsaxguy/homelab/commit/bd7ae1f091c71354f8a643d20f10a541c3aee8a5))
- **arr:** Use Kustomize Helm charts for the arr-suite
  ([cbbb6d8](https://github.com/theepicsaxguy/homelab/commit/cbbb6d8bccb40133ac274a7511d0b5f5d1b4ed4c))
- **auth:** add Authelia for OIDC
  ([ba69146](https://github.com/theepicsaxguy/homelab/commit/ba69146b4bb11c2eb7b9da63c01de0f850aed7be))
- **auth:** add keycloak for auth
  ([628bdb5](https://github.com/theepicsaxguy/homelab/commit/628bdb53d6c54ac8bd9403c595c3d353ff0b8853))
- **auth:** add Keycloak for auth
  ([884fe3b](https://github.com/theepicsaxguy/homelab/commit/884fe3bd00f5b1ab03fb5261e3acc2962eb65da7))
- **auth:** Added Google auth for remark42 blog comments
  ([606e9fe](https://github.com/theepicsaxguy/homelab/commit/606e9fe015795b8177497efe8cad5d7ab26f38e4))
- **auth:** Adding traefik-forward-auth
  ([954ff94](https://github.com/theepicsaxguy/homelab/commit/954ff948215c863e14e092efc125f84c38925285))
- **auth:** Deploying traefik-forward-auth with Helm chart
  ([9d5a579](https://github.com/theepicsaxguy/homelab/commit/9d5a5797939b26bb6a224e306f6466452ef5632d))
- **authelia:** add "optional" secrets in config
  ([0c19b80](https://github.com/theepicsaxguy/homelab/commit/0c19b80b7535ea38073ef3e943352b9bde7b18a8))
- **authelia:** add Argo CD client
  ([86395ed](https://github.com/theepicsaxguy/homelab/commit/86395edc1f9031f26a9df9b96262a4629d0c6e93))
- **authelia:** add ES256 jwk
  ([d077f4b](https://github.com/theepicsaxguy/homelab/commit/d077f4b035fd86269d1bf223e6e5aabdc8289d7f))
- **authelia:** add ES256 jwk and use it
  ([6d13790](https://github.com/theepicsaxguy/homelab/commit/6d137906d1e01f0f560d39c1bfc709fbc0eb1c5c))
- **authelia:** add kubectl oidc account
  ([e48986a](https://github.com/theepicsaxguy/homelab/commit/e48986a5a2b97e37cad47228219f6c6bac23a622))
- **authelia:** add smtp integration
  ([7a949af](https://github.com/theepicsaxguy/homelab/commit/7a949afadda5a84cd09797c9d5f9ee3f6a044fd9))
- **authelia:** enable 2FA
  ([9a92b48](https://github.com/theepicsaxguy/homelab/commit/9a92b48c9766a732a2f8fbcfccb57d3035bea71a))
- **authelia:** harden oidc clients
  ([d816953](https://github.com/theepicsaxguy/homelab/commit/d816953b98d84c02a82d4d4449b806988b73da52))
- **authelia:** make cert-manager generate jwks
  ([403d32b](https://github.com/theepicsaxguy/homelab/commit/403d32b9eddb019b78e7ddad081b7a6878477adb))
- **authelia:** use a cnpg managed db
  ([ce5fc25](https://github.com/theepicsaxguy/homelab/commit/ce5fc25504ce7c934032de85665a45daf34a381b))
- **authelia:** use ldaps with lldap
  ([a7ea946](https://github.com/theepicsaxguy/homelab/commit/a7ea9468e85dc32cfcd5c8eb608df4770415e2e0))
- **auth:** enable kubectl oidc auth
  ([2674d91](https://github.com/theepicsaxguy/homelab/commit/2674d91a48b9a37c44c7ced33d260f8e9d58049c))
- **blog:** Adding blog from GitLab
  ([94a2970](https://github.com/theepicsaxguy/homelab/commit/94a29703d966a42ae921044105340bad5f70726b))
- **blog:** Adding Remark42 for blog commenting
  ([e3aa992](https://github.com/theepicsaxguy/homelab/commit/e3aa9923e0933ef464c3730a0d0e44f2573ba17f))
- **cert-manager:** Installing and configuring cert-manager
  ([ca44a52](https://github.com/theepicsaxguy/homelab/commit/ca44a520c8a253fd8553bd89e1da2e0b287362f7))
- **cert-manager:** Use Cert-manager Helm Chart instead of static manifest
  ([819a2b9](https://github.com/theepicsaxguy/homelab/commit/819a2b964efeba2b61b9dd8d8c637e3281d3e90a))
- **certs:** Configuring certs through Cloudlfare using Cert Manager with Traefik
  ([1b66227](https://github.com/theepicsaxguy/homelab/commit/1b662274249c832bc0ba080f57a87e16c074618d))
- **chart:** Adding an additionalVolumes value to chart
  ([312e620](https://github.com/theepicsaxguy/homelab/commit/312e620a31988d907ce85e78591603f099be4b8c))
- **cilium:** enable maglev loadBalancer
  ([c524a6a](https://github.com/theepicsaxguy/homelab/commit/c524a6ab654e48a1113ada476daf63a3eec168b7))
- **cilium:** Installing cilium with ArgoCD
  ([2b840e6](https://github.com/theepicsaxguy/homelab/commit/2b840e6e8e212f7590fd49275c0fd5b65afccbbc))
- cleanup of remodelling
  ([207b189](https://github.com/theepicsaxguy/homelab/commit/207b1892bf01941db43835bc3911821a90318398))
- **cloud-init:** Kubeadm cluster
  ([e343d41](https://github.com/theepicsaxguy/homelab/commit/e343d41b8547ce35a263b60f19dc66ad854ba526))
- **cloudflared:** Configuring tunnel locally/declaratively instead of ClickOps through Dashboard
  ([e18d379](https://github.com/theepicsaxguy/homelab/commit/e18d3796de677ac0e6785cba717878f611058aa0))
- **cloudflare:** Enabling Cloudflare TLS
  ([3338fb4](https://github.com/theepicsaxguy/homelab/commit/3338fb47da04dd3a644f1f25a07e7af6011800f9))
- **cni:** Using Terraform to provide Cilium as a CNI using Helm
  ([18f8d9e](https://github.com/theepicsaxguy/homelab/commit/18f8d9ede4538bb8c96daf078f1bb35f748d0dc6))
- **cni:** Using Terraform to provide Cilium as a CNI using Helm
  ([f808257](https://github.com/theepicsaxguy/homelab/commit/f8082570a2dbad6360f3f244fda400169ad27fdd))
- **cnpg:** configure test-database for external connection
  ([1d0ae6d](https://github.com/theepicsaxguy/homelab/commit/1d0ae6d437f43f579d2f58384758c350035d04a2))
- **config:** Config changes after switching to Debian
  ([e3423cd](https://github.com/theepicsaxguy/homelab/commit/e3423cd5471fd9c340ea3c1acd724a2b17789461))
- configure keycloak using crossplane provider
  ([4cb40d3](https://github.com/theepicsaxguy/homelab/commit/4cb40d3282fb9aed6419fa73fb9d1ee24084ba15))
- configure renovate
  ([be08e10](https://github.com/theepicsaxguy/homelab/commit/be08e101b25ce6e7f9ad329964d245afb80c562a))
- **config:** Using configMaps instead of env-variables for traefik-forward-auth
  ([8eb09c3](https://github.com/theepicsaxguy/homelab/commit/8eb09c3f502604dc1eac9f1ded75e0785fe91812))
- **coturn:** use plain manifests instead of helm chart
  ([a535a76](https://github.com/theepicsaxguy/homelab/commit/a535a76c31241f1e85411809ab66fc9c493cbbb6))
- **crossplane:** try to organise crossplane crds
  ([bff7417](https://github.com/theepicsaxguy/homelab/commit/bff741753a13bdca67c0782e437cbba18854269d))
- **cuda:** Running a CUDA sample pod
  ([8667f83](https://github.com/theepicsaxguy/homelab/commit/8667f835b312034f3b19ceb750e60aa7b50856ba))
- **dashboard:** Deploying and exposing the Kubernetes Dashboard
  ([90e7ddd](https://github.com/theepicsaxguy/homelab/commit/90e7dddb0ab69c78f384bfb52a271bc270b49ada))
- **dashboard:** Deploying k8s dashboard with ArgoCD
  ([4e717aa](https://github.com/theepicsaxguy/homelab/commit/4e717aa6074105db805db9c08012d4524372c978))
- **database:** add cnpg for database management
  ([d3338da](https://github.com/theepicsaxguy/homelab/commit/d3338da90a64481ea8657262d595d399310cda6d))
- **db:** Adding Zalando Postgres-operator
  ([7c6d24a](https://github.com/theepicsaxguy/homelab/commit/7c6d24a49f514c7c9500304309f64bb03de68931))
- **dns:** use Unbound and AdGuardHome for DNS
  ([9dec025](https://github.com/theepicsaxguy/homelab/commit/9dec025db74c7ab25a76da73e1032314fa752183))
- **env:** Fetching common env from a ConfigMap
  ([fd605aa](https://github.com/theepicsaxguy/homelab/commit/fd605aa01aefb659530d40007e70726e2e7f67e9))
- **gateway:** Enabled and configured Cilium as a GatewayClass
  ([b066e54](https://github.com/theepicsaxguy/homelab/commit/b066e543046ffa383cf6d534421306a1435e5c45))
- **gateway:** Switch public sites over to Gateway instead of Traefik IngressRoute
  ([6a3fffb](https://github.com/theepicsaxguy/homelab/commit/6a3fffb8c3250e015a9bfb401a662728b05b64e0))
- **gpu:** Adding Nvidia GPU-Oparator
  ([c7c145d](https://github.com/theepicsaxguy/homelab/commit/c7c145d73b36be60f4b69c19c6b01954369f37d4))
- **gpu:** Change from nvidia-gpu-operator to nvidia-device-plugin
  ([cac81f3](https://github.com/theepicsaxguy/homelab/commit/cac81f3cceb8b454e1fe31e33313a308f69537f8))
- **haos:** Proxy HAOS through k8s for certificate
  ([3c33225](https://github.com/theepicsaxguy/homelab/commit/3c33225e00941f909f01e4d3fdbd02ba5835bbca))
- **hass:** Move Home Assistant config to own repo
  ([52a3f87](https://github.com/theepicsaxguy/homelab/commit/52a3f87dad1679cc2e422fbb9e1875e04874d929))
- **helm-traefik:** Setting up Traefik using Helm-chart
  ([107f1fc](https://github.com/theepicsaxguy/homelab/commit/107f1fc700cc1596d9194234eb30f27580a4f0ea))
- **helm:** Add labels and annotations to helm chart
  ([ad7ecb8](https://github.com/theepicsaxguy/homelab/commit/ad7ecb83fd71c3bf1ce49f6f0ad31809cd5b7a08))
- **helm:** Introducing Helm Charts for templating
  ([67049f2](https://github.com/theepicsaxguy/homelab/commit/67049f2e015d38fcb6163e894253bd82a558fc48))
- **helm:** Modifying chart template to allow a stand-alone auth deployment
  ([ea712fe](https://github.com/theepicsaxguy/homelab/commit/ea712feb77e2fbd1bc84292894ce85c8454b33d8))
- **helm:** Trying to use a local Helm chart
  ([1c6e0c6](https://github.com/theepicsaxguy/homelab/commit/1c6e0c6c99d37eef824ae7aa80bb464fa42b3bfb))
- **homepage:** add homepage and blog
  ([731a16b](https://github.com/theepicsaxguy/homelab/commit/731a16baf3e691ce1699e82799696187d4e37231))
- **homepage:** Adding a simple landing page
  ([91c7238](https://github.com/theepicsaxguy/homelab/commit/91c72383987c2984b893811e8750d83bcec6299a))
- **hubble:** Enabling and exposing Hubble
  ([d5f5e23](https://github.com/theepicsaxguy/homelab/commit/d5f5e23bf26626bfb6edf1f6923ca068325b3aa9))
- **infra:** Use a single ApplicationSet instead of multiple Application manifests for infrastructure applications
  ([ad74c53](https://github.com/theepicsaxguy/homelab/commit/ad74c53fdf3044fc99c2f497499135ce71cfaec8))
- **ingress:** Provision Traefik as an ingress controller
  ([c8561e7](https://github.com/theepicsaxguy/homelab/commit/c8561e74c2de2840519789d41886cb4284468456))
- **init:** Initial commit
  ([b277649](https://github.com/theepicsaxguy/homelab/commit/b27764985727e9492e20720c481f33d896a0bf05))
- install Netbird as a VPN solution
  ([69d56e8](https://github.com/theepicsaxguy/homelab/commit/69d56e8e714b01861f74ff6c9a20e9d1cfa624bf))
- **jellyfin:** Adding Jellyfin
  ([5886c83](https://github.com/theepicsaxguy/homelab/commit/5886c83d8da0e1ac9c508ac2885a24fa213ab50f))
- **jf:** Proxy Jellyfin from Euclid instead of Plex
  ([7d79db7](https://github.com/theepicsaxguy/homelab/commit/7d79db70e9d18824ae93bbed095c31b1a88f4d07))
- **k8s:** multi-node Talos cluster
  ([fbdccd7](https://github.com/theepicsaxguy/homelab/commit/fbdccd773166368b1c14c4bae09f7cfd2bfc27b3))
- **kube-proxy:** Trying to use cilium's kube-proxy
  ([3f3f1ee](https://github.com/theepicsaxguy/homelab/commit/3f3f1eeac03cdc5027db43f2fc8637477d1c76a3))
- **kustomize:** Simple implementation of Kustomize for apps
  ([eab8320](https://github.com/theepicsaxguy/homelab/commit/eab83202de479136d58a6d106f7bd1f5b10646d3))
- **lb:** Replace MetalLB with Cilium LB IPAM + BGP Control Plane
  ([8d4bb60](https://github.com/theepicsaxguy/homelab/commit/8d4bb606e47abc89abe124b32c35d3cdce4f176d))
- **ldap:** add lldap as ldap server
  ([2a3f017](https://github.com/theepicsaxguy/homelab/commit/2a3f01736dc39f367bd582ed4cf7af118781da64))
- **lgtm:** Adding LGTM Helm chart
  ([cabdc65](https://github.com/theepicsaxguy/homelab/commit/cabdc654485295e3aae8129bb727a78abf2a6eda))
- **lidarr:** Deploying Lidarr using Helm Chart
  ([f906558](https://github.com/theepicsaxguy/homelab/commit/f906558832a6c6620fb8557d256176f54b71df09))
- **lldap:** add a test user
  ([baa30f0](https://github.com/theepicsaxguy/homelab/commit/baa30f0e030f2d029b0139f8afcd1ac4902de67a))
- **lldap:** add cnpg database for persistence
  ([5563a63](https://github.com/theepicsaxguy/homelab/commit/5563a63f56baf4581b3f84b9f60f47d90648c58e))
- **lldap:** add smtp integration
  ([8da8d82](https://github.com/theepicsaxguy/homelab/commit/8da8d82bf4204cdc9f3ad4863756b1cae1df8504))
- **lldap:** bootstrap lldap users with script
  ([ddb7f0f](https://github.com/theepicsaxguy/homelab/commit/ddb7f0fd9fc62c101a2ea615d06495cc70d07dce))
- **lldap:** create and use own authelia user
  ([c884036](https://github.com/theepicsaxguy/homelab/commit/c88403691bc7ca3b78a096db14c2a4fd6c3a0aed))
- **LoadBalancer:** Adding MetalLB
  ([5a71638](https://github.com/theepicsaxguy/homelab/commit/5a716387a89f04629ec63141fda2e4b3b199d5e9))
- **media:** add media players
  ([3edf326](https://github.com/theepicsaxguy/homelab/commit/3edf3260d616f20c5fd6f876e4b43db206f7deae))
- **metallb:** Installing MetalLB using ArgoCD
  ([d81b83c](https://github.com/theepicsaxguy/homelab/commit/d81b83c2435ed8f98f71c7ef48eb0f5955b8732f))
- **monitoring:** add http-routes for prometheus and alertmanager
  ([53b332c](https://github.com/theepicsaxguy/homelab/commit/53b332cb2846ab4f5431f3fe30f93cece248b028))
- **monitoring:** Configure kube-prometheus-stack
  ([91998ec](https://github.com/theepicsaxguy/homelab/commit/91998ecc2aa22e956d3c9dbbb650d87d07cf8e86))
- **monitoring:** install kube-prometheus-stack
  ([f1797c9](https://github.com/theepicsaxguy/homelab/commit/f1797c94ec223a3ea8155fcace4c906c7e3956eb))
- **monitoring:** Installing kube-prometheus-stack from prometheus-community Helm chart
  ([3c5e337](https://github.com/theepicsaxguy/homelab/commit/3c5e337cfc8f1adc416fdcc3cf6b16cbe342ee6e))
- **mTLS:** Enable Cilium mTLS
  ([059e8ab](https://github.com/theepicsaxguy/homelab/commit/059e8abace4a08cc92103b4be4d0b9d0bf677e98))
- **net-aux:** Adding Unbound as a recursive DNS resolver for Pi-Hole
  ([20d365b](https://github.com/theepicsaxguy/homelab/commit/20d365b8f123e34ce9819bf2a8bd28c49ad2b884))
- **netbird:** add netbird router agent
  ([5c0c336](https://github.com/theepicsaxguy/homelab/commit/5c0c3366b28d03141b200fee8863ce727df3377e))
- **netbird:** add relay service
  ([aa1a078](https://github.com/theepicsaxguy/homelab/commit/aa1a0782949253369345ffd749bb4cb384854898))
- **netbird:** change oidc provider to authelia
  ([c483d0f](https://github.com/theepicsaxguy/homelab/commit/c483d0fa5acb7d7eb05a83b98055ed99d4d4d181))
- **netbird:** configuring oidc-clients using new XOidcClient composition
  ([15adc6f](https://github.com/theepicsaxguy/homelab/commit/15adc6f86306c944e375547f0f0ccf83cb4cd244))
- **netbird:** remove idp-integration
  ([037fc29](https://github.com/theepicsaxguy/homelab/commit/037fc29129024b5db0210c4b3b2fa015a5acadc2))
- **netbird:** replace backend helm chart with plain manifests
  ([56d2a42](https://github.com/theepicsaxguy/homelab/commit/56d2a42b9df670bfe0b450afc2c65fc2ab39d220))
- **netbird:** replace dashboard helm chart with plain manifests
  ([0149a02](https://github.com/theepicsaxguy/homelab/commit/0149a02e4cdb828d303eda85a272449aa1ab7198))
- **netbird:** use built-in mechanism for jwk sign key refresh
  ([0195f99](https://github.com/theepicsaxguy/homelab/commit/0195f992524ecbd5f5d3f6a818464d6376377813))
- **net:** Rewriting main Pi-Hole to use Unbound as well
  ([b033608](https://github.com/theepicsaxguy/homelab/commit/b033608da12f5f1984f857c21c99c5f9cca8aab5))
- **network:** add cloudflared
  ([127290d](https://github.com/theepicsaxguy/homelab/commit/127290d99b4bccfceece1673e131f3084d6c7240))
- **network:** Creating an auxiliary deployment of network tools
  ([d0986d5](https://github.com/theepicsaxguy/homelab/commit/d0986d5ee1477658411f44e37456b741d7cefc1e))
- **patches:** Trying to patch an extra volume mount
  ([31c3ae0](https://github.com/theepicsaxguy/homelab/commit/31c3ae0820d8e860250eb2270b5c9019495d3309))
- **pi-hole:** Adding Pi-Hole
  ([dbbcda1](https://github.com/theepicsaxguy/homelab/commit/dbbcda1434720a8d70d269b55173704202319fe9))
- **pi-hole:** Configured Pi-Hole to proxy public domain to local Traefik svc in order for Cloudflared tunnel to work
  ([93fde77](https://github.com/theepicsaxguy/homelab/commit/93fde779be92584164edfd05447182bb1d4fbe9b))
- **pi-hole:** Configuring Pi-Hole lists
  ([c87f167](https://github.com/theepicsaxguy/homelab/commit/c87f1673f469a44acfa0a360e7f5cd0b1c98bc6b))
- **plex:** Proxy Euclid Plex
  ([ba5ec8a](https://github.com/theepicsaxguy/homelab/commit/ba5ec8a7d6ebaa5ea2f75afeb0469f1cc6748a9d))
- **prowlarr:** Deploying Prowlarr with Helm chart
  ([e84bea5](https://github.com/theepicsaxguy/homelab/commit/e84bea5da271a63c4071dc5f28e776a1b5b49570))
- **proxmox:** Proxy Euclid Proxmox through Gateway
  ([9eeae42](https://github.com/theepicsaxguy/homelab/commit/9eeae42921536d7e95dd58e01d61be6f1dcb2d75))
- **qbit:** Deploying qBittorrent with Helm chart
  ([748092d](https://github.com/theepicsaxguy/homelab/commit/748092d15158b1efd5ad051a29e6590c5a422201))
- **radarr:** Deploying Radarr with Helm chart
  ([e6cad43](https://github.com/theepicsaxguy/homelab/commit/e6cad43b4bb40bf99852513c0545a90c5f43a34b))
- **renovate:** group related containers for fewer renovate PRs
  ([f1a1166](https://github.com/theepicsaxguy/homelab/commit/f1a11669a6752bdd292f020e40e88d3b4ea3d0e2))
- **renovate:** rebase stale PRs
  ([1d3f025](https://github.com/theepicsaxguy/homelab/commit/1d3f02562535955ede1dd260d36bd3c5d0ee0666))
- routes to cluster external services
  ([aa6af35](https://github.com/theepicsaxguy/homelab/commit/aa6af35f48ca9b9c797cf688c3d673edb2796382))
- **secrets:** Adding sealed secrets controller
  ([4814a31](https://github.com/theepicsaxguy/homelab/commit/4814a31b15c740b6b68fab86e5e0daceb3aaa62d))
- **secrets:** Committing sealed secrets for traefik-auth
  ([2c29f0f](https://github.com/theepicsaxguy/homelab/commit/2c29f0fd333a407bb1f7bbbd750f92afbb7fa26e))
- **secrets:** Moved sealed secrets to their respective folders
  ([f1eeac2](https://github.com/theepicsaxguy/homelab/commit/f1eeac25923dab0395649d14b49c214d3326b4c6))
- **sets:** Moved ApplicationSets out into their own folder
  ([9832d5f](https://github.com/theepicsaxguy/homelab/commit/9832d5fc3c8e46fcaec9af82be7dfdce4d8a3a6e))
- **sonarr:** Deploying Sonarr with Helm chart
  ([34796f4](https://github.com/theepicsaxguy/homelab/commit/34796f4b1d86d060cd09eaf2c1351be58f32f232))
- **talos:** add ArgoCD ApplicationSet for homelab and update Talos configuration for improved endpoint management
  ([1db4773](https://github.com/theepicsaxguy/homelab/commit/1db477374d2101fb348bac5576f84d2b56e6bf44))
- **talos:** add ArgoCD bootstrap configuration and enhance Talos machine setup
  ([7ca0509](https://github.com/theepicsaxguy/homelab/commit/7ca05092d45ce966940160f1dde06b45337dacd4))
- **talos:** add configuration for DNS settings and update output commands in setup documentation
  ([cfd9447](https://github.com/theepicsaxguy/homelab/commit/cfd9447bdd33fa19589d12f96be95906a4eec083))
- **talos:** Bootstrap Cilium from ConfigMap
  ([8c5389c](https://github.com/theepicsaxguy/homelab/commit/8c5389c31cf7aee9581468a2a6034a5f630aafcf))
- **talos:** generate schematic id on-the-fly and add possibility of changing image
  ([29f5ce8](https://github.com/theepicsaxguy/homelab/commit/29f5ce8b144a700621e5b52cc3f4217cbb707b3c))
- **talos:** implement health check for Talos cluster using local-exec provisioner
  ([c221c07](https://github.com/theepicsaxguy/homelab/commit/c221c07c96c196c18431ee6c59b7126148734cef))
- **talos:** update image version to v1.9.4 and refine download file resource
  ([68fefd6](https://github.com/theepicsaxguy/homelab/commit/68fefd6c61b0a7534a392dead8fa9987fcab31e2))
- **test:** Rename test deployment to not collide with whoami
  ([555c751](https://github.com/theepicsaxguy/homelab/commit/555c751a5e59e4b9ec523e370aee1e50952f2fbe))
- **test:** Use a different issuer for a test-app
  ([885e454](https://github.com/theepicsaxguy/homelab/commit/885e454ecc0775c411d7caadf2d8c2c2a0c23be1))
- **tofu:** split into multiple configurations
  ([daaafc8](https://github.com/theepicsaxguy/homelab/commit/daaafc8feaea676d494d572ef1c8c2dd8682e181))
- **tofu:** updated kubernetes setup
  ([c4ba712](https://github.com/theepicsaxguy/homelab/commit/c4ba7120dd9d9f5a821da0cbd447714f005a1aa7))
- **tofu:** use new talos_image_factory_schematic resource
  ([140fbc2](https://github.com/theepicsaxguy/homelab/commit/140fbc249b26c622c0e2ab413c3aca9eb5014f8e))
- **traefik:** Adding Traefik using ArgoCD
  ([d265a4d](https://github.com/theepicsaxguy/homelab/commit/d265a4d644cdef8aee4b154cb25063a412beeb44))
- **traefik:** Clean up Traefik config after certs are handled by Cert-manager
  ([cdec125](https://github.com/theepicsaxguy/homelab/commit/cdec125a11bb662700ffd08989c5a4e75b681770))
- **traefik:** Exposing Traefik Dashboard
  ([5a5869f](https://github.com/theepicsaxguy/homelab/commit/5a5869f87a95b7b38fe1ce216a962e4c6b9b22fe))
- **traefik:** Using Kustomize with Helm to deploy Traefik using ArgoCD
  ([a13e7f7](https://github.com/theepicsaxguy/homelab/commit/a13e7f7df65f0c4d2ce66d32ca2da7969072172f))
- **traefik:** Working PoC using single node Kubernetes cluster with Cilium, MetalLB and Traefik
  ([482f35c](https://github.com/theepicsaxguy/homelab/commit/482f35c139592946bb4771319a1b9914222d34e4))
- **unrar:** add an image for unrar tool
  ([e5b3cd9](https://github.com/theepicsaxguy/homelab/commit/e5b3cd91d33fa4e806d47dab63b868b37e9d3598))
- **vm:** Start to use Proxmox
  ([d035bec](https://github.com/theepicsaxguy/homelab/commit/d035bec693c338df45edf5ad0347d8f24b2cc6be))
- **volumes:** Persistent storage for Traefik certs
  ([b33d362](https://github.com/theepicsaxguy/homelab/commit/b33d3620889d49dc5d686f5fe892d18a737dfc18))
- **volumes:** provision volumes using tofu
  ([7a946e3](https://github.com/theepicsaxguy/homelab/commit/7a946e3e234268732f5366d93d35acdd9f853466))
- **vpn:** split gateway into external and internal services
  ([9a7894a](https://github.com/theepicsaxguy/homelab/commit/9a7894a7abb149603f197718069e434fb07cfb03))
- **vuetorrent:** use git-sync to fetch vuetorrent theme
  ([1602202](https://github.com/theepicsaxguy/homelab/commit/1602202137d6571da5ba17ff51fe2b66b48dc08b))
- **whoami:** add simple whoami-app for testing
  ([653d3e9](https://github.com/theepicsaxguy/homelab/commit/653d3e946cc5d61f2f2394e732581c2c20b80c06))
- **whoami:** Adding simple service to test Traefik
  ([7a50d59](https://github.com/theepicsaxguy/homelab/commit/7a50d59336cdbf0dec902d6cce868d09386fed76))
- **whoami:** Deploying whoami with ArgoCD and secret delivery
  ([600a704](https://github.com/theepicsaxguy/homelab/commit/600a7043f3e7ab00d9c5e49aad21a98c9809492a))

### Bug Fixes

- **argo cd:** disable dex
  ([38542b6](https://github.com/theepicsaxguy/homelab/commit/38542b6bdb5b8fce49529e794f6bfed7d6fff882))
- **argocd:** Cleaning up Application entry for Traefik
  ([888e0de](https://github.com/theepicsaxguy/homelab/commit/888e0de398569d703f6d77491dd3ff270f1ef78a))
- **argocd:** Enabling selfHeal and prune on Applications
  ([95e6f9b](https://github.com/theepicsaxguy/homelab/commit/95e6f9b320f0c759d80fc1ee15d6bb44e886ec36))
- **argocd:** Migrating from argocd-cm plugins
  ([d3f6691](https://github.com/theepicsaxguy/homelab/commit/d3f66914c1d02abdbe68b17e44e5660342e7e9df))
- **argocd:** Pin the version of ArgoCD to 2.7.11
  ([fafdac7](https://github.com/theepicsaxguy/homelab/commit/fafdac7f04d7c0c186bfdbf61f9065aed9dc3eda))
- **argocd:** turn on server-side diff
  ([af79c5b](https://github.com/theepicsaxguy/homelab/commit/af79c5b906bae3e5a166465058cf7ee0cf3ee4a3))
- **argo:** Trying to ease deployment restictions
  ([450117a](https://github.com/theepicsaxguy/homelab/commit/450117ae55c261b0270396762d1dcb2aca69e166))
- **authelia:** add access_control policy rule
  ([8d8e0ca](https://github.com/theepicsaxguy/homelab/commit/8d8e0ca87ab1ef13aef1af9465014fecb6d63775))
- **authelia:** clean up values-file
  ([3c2c08b](https://github.com/theepicsaxguy/homelab/commit/3c2c08b367736f63df8ef3edb672bd2a23b92f86))
- **authelia:** disable html emails
  ([d523d12](https://github.com/theepicsaxguy/homelab/commit/d523d128c418e03ade0f16676035812ecec03d1e))
- **authelia:** increase db disk size
  ([edd0a15](https://github.com/theepicsaxguy/homelab/commit/edd0a153454634eaeec993a42a45b04dd05c2f09))
- bind prometheus operator to same node with volume
  ([e2e30a9](https://github.com/theepicsaxguy/homelab/commit/e2e30a91e27a49549ff0430859842cc8a862b7b8))
- **cert-manager:** remove deprecated flag
  ([1a46529](https://github.com/theepicsaxguy/homelab/commit/1a46529d96f1df7cc4a72b3ba69dd7ead53889fa))
- **cert-manager:** Trying to configure a service to use cert-manager
  ([3190aef](https://github.com/theepicsaxguy/homelab/commit/3190aefd4af4a38f44fb5a99753ab93028847bdf))
- **cert-manager:** update API token
  ([cbf1210](https://github.com/theepicsaxguy/homelab/commit/cbf1210859fab69d59c61f300e7bdaf6a6f418b7))
- **cert:** ask for cert for both \*.pctips.dev and pctips.dev
  ([25f9771](https://github.com/theepicsaxguy/homelab/commit/25f977126b1928fc79482523b541857ec37bbe01))
- **cert:** Changing certs from Let's Encrypt to Cloudflare
  ([17c7900](https://github.com/theepicsaxguy/homelab/commit/17c79002dcb1b7c32aaf41bd53da403a0af90d14))
- **cert:** Fixing Cloudflare cert tls secret not properly configured
  ([b73671c](https://github.com/theepicsaxguy/homelab/commit/b73671ccc81365527b4a462a4aaf8584d47ee1b1))
- **certs:** Cleaning up Traefik with cert-manager and Cloudflare DNS
  ([681aded](https://github.com/theepicsaxguy/homelab/commit/681adedfbe401bd15efd37de29ac2f37dee812f4))
- **chart:** Fixed missing image-tag in application chart
  ([6f2d19d](https://github.com/theepicsaxguy/homelab/commit/6f2d19d92fd2d7216acdf0e98771c233d0e48f45))
- **cilium-identity:** Excluding CiliumIdentity to avoid ArogCD reporting OutOfSync
  ([ee15bb9](https://github.com/theepicsaxguy/homelab/commit/ee15bb9970ee911b599186c80415aff46b8472e7))
- **cilium:** Announce ARP on all interfaces
  ([0b1011d](https://github.com/theepicsaxguy/homelab/commit/0b1011d0f6402507b24ba90edb96e1bb55046437))
- **cilium:** use legacy host routing
  ([063b5da](https://github.com/theepicsaxguy/homelab/commit/063b5da94ffd0ae54fdf86bbf437daee30ec9c99))
- Cleaning Gateway/HTTPRoute naming
  ([54dc229](https://github.com/theepicsaxguy/homelab/commit/54dc229e3e556541b0f573853cd1104dfe099219))
- **cloudflared:** Configure cloudflared services to point directly at FQDN Traefik service instead of using DNS routing
  to IP ([7dcb094](https://github.com/theepicsaxguy/homelab/commit/7dcb0940de3e4c1293a0f9c2304a6d385e85c2d1))
- **cloudflared:** correct routing to homepage
  ([bca0889](https://github.com/theepicsaxguy/homelab/commit/bca0889c47661d7b672a05dee0b3e223b7711615))
- **cloudflared:** Disable cloudflared
  ([25692fd](https://github.com/theepicsaxguy/homelab/commit/25692fd11f83d82e3d630e4fa74ecedb209f633f))
- **cloudflared:** Use Pi-Hole as DNS for cloudflared pods
  ([03bab47](https://github.com/theepicsaxguy/homelab/commit/03bab47e17186797242b1e7552cb0860a779d38d))
- **cnpg:** rename db volumes
  ([24743bf](https://github.com/theepicsaxguy/homelab/commit/24743bf9c2dd365b0f67d041cacae4dbc0460b75))
- configure gateway
  ([d7f90f3](https://github.com/theepicsaxguy/homelab/commit/d7f90f34e176597da47e0593bbce3f6cc350f90b))
- conflicting svc name
  ([5abde08](https://github.com/theepicsaxguy/homelab/commit/5abde08753f996a22e5ef6f61682883a3b3ec472))
- **coturn:** only use tls-port
  ([b090a54](https://github.com/theepicsaxguy/homelab/commit/b090a54d759f6edbca4bf58c7064b93734e21bc6))
- crossed-wires in Plex and Jellyfin
  ([0a265cb](https://github.com/theepicsaxguy/homelab/commit/0a265cbfd5d907f7aac6dba71ff4aa0434ba4b05))
- **cuda:** Set correct namespace for CUDA-test
  ([edb30a6](https://github.com/theepicsaxguy/homelab/commit/edb30a695332f80e80041404a5f9f48001bf1f01))
- **dns:** Don't route non-denfined to Traefik
  ([eae119a](https://github.com/theepicsaxguy/homelab/commit/eae119a45c1000da8684f2c33762958e025add9d))
- **dns:** Pinning DNS IPs and cleaning up related services
  ([4c435eb](https://github.com/theepicsaxguy/homelab/commit/4c435eb22943d1a38bd30cc1640dcc4f0ae84f0b))
- **dns:** Trying with both UDP and TCP on the same Service again
  ([e819f3f](https://github.com/theepicsaxguy/homelab/commit/e819f3f26e7e9da554cf26b8e63871e619b83e71))
- **dns:** tweak dns settingss after update
  ([eb74b5b](https://github.com/theepicsaxguy/homelab/commit/eb74b5baff594cfc40ad94a91d4c37aedebbcdcf))
- **dns:** tweak unbound setting again
  ([e4fbd93](https://github.com/theepicsaxguy/homelab/commit/e4fbd938c17ce7481578f4dda7d46e7c85481ff4))
- **euclid:** Delay qemu-guest-agent startup
  ([32d9755](https://github.com/theepicsaxguy/homelab/commit/32d97558eca81216cf1183875f83961c5acc8ae3))
- **gateway:** Create a separate Gateway for Proxmox TLS passthrough
  ([da61e34](https://github.com/theepicsaxguy/homelab/commit/da61e34580587f9b2b1cc0da1cd6bfa99a2c6ed8))
- **gateway:** Creating a TLS Passthrough listener
  ([fe9ab18](https://github.com/theepicsaxguy/homelab/commit/fe9ab18ed0a97e33176cb9ee447cb37f4e45e2a3))
- **gateway:** Pinpointed difficulties to be with wildcard
  ([ba03da7](https://github.com/theepicsaxguy/homelab/commit/ba03da7c4b9d58a288875ffc82161d3ec6c4066b))
- **gateway:** Regressing to IngressRoutes to get sites working again
  ([8e7a87c](https://github.com/theepicsaxguy/homelab/commit/8e7a87c8254d1e4e481d9ee666fafd7f00cc2009))
- **gateway:** Removed non-traefik-forward-auth protected Ingresses in favour of HTTPRoutes
  ([d1ae9a1](https://github.com/theepicsaxguy/homelab/commit/d1ae9a189f4470613dfc14606a8eda53509d9cf9))
- **gpu:** Adding time-slicing config for GPU
  ([c61af77](https://github.com/theepicsaxguy/homelab/commit/c61af776907219909248d8cae69e5acce5fbb1d9))
- **gpu:** Disabling toolkit in Nvidia gpu-operator Helm chart
  ([ebddae1](https://github.com/theepicsaxguy/homelab/commit/ebddae176f3ff4d941e13497fca27a821febff81))
- **hass:** Creating PV and PVC for Home Assistant
  ([d43f968](https://github.com/theepicsaxguy/homelab/commit/d43f968a4cf1ff6b77057856832ae453489dae0f))
- **hass:** Removing traefik-forward-auth for Home Assistant
  ([e8dc6dc](https://github.com/theepicsaxguy/homelab/commit/e8dc6dc235046017591668b6b274154889fce145))
- **helm:** Correctly set auth host
  ([44456d4](https://github.com/theepicsaxguy/homelab/commit/44456d4465c52831f167e88f62948e8750e45871))
- **helm:** renamed helm directory to charts
  ([01625b3](https://github.com/theepicsaxguy/homelab/commit/01625b39d546834788bc66f80ccaf865e78b74dd))
- **hubble:** Move Hubble to it's own folder
  ([563b8e7](https://github.com/theepicsaxguy/homelab/commit/563b8e7181f4f57f886cf6d3a02aba0e5285efcb))
- **imagePullPolicy:** Change imagePullPolicy to 'Always' to keep apps updated
  ([b5312f4](https://github.com/theepicsaxguy/homelab/commit/b5312f4521c17c8350f0d63e77d7f418b2e969f6))
- increase cpu and mem limits for Argo CD and cloudflared
  ([605e5ef](https://github.com/theepicsaxguy/homelab/commit/605e5ef181f8e6bd5b4915170fa5e4ab7f23d8ca))
- **jellyfin:** Enabling GPU-support
  ([d23f71b](https://github.com/theepicsaxguy/homelab/commit/d23f71b45ced3c85b2dc4b56a4c6be3c3fb4ae52))
- **jellyfin:** use Memory for /cache to avoid NodeDiskPressure
  ([38f118f](https://github.com/theepicsaxguy/homelab/commit/38f118fa173447a1066a3a3b2e7347465ec28b68))
- **keycloak:** move crossplane-keycloak-credentials to keycloak from crossplane namespace
  ([5ecf061](https://github.com/theepicsaxguy/homelab/commit/5ecf061fc3f9b7cc9de1f27ff8b8a4a883cabfc5))
- **keycloak:** new postgres volume
  ([ffa1701](https://github.com/theepicsaxguy/homelab/commit/ffa170117b6e90bee5da623ef7c66f0b6d133671))
- **keycloak:** update crossplane keycloak-provider
  ([253e65a](https://github.com/theepicsaxguy/homelab/commit/253e65a708b959e120175905146fb708d23279de))
- **lldap:** add hash seed
  ([5ae1a6d](https://github.com/theepicsaxguy/homelab/commit/5ae1a6d8293c6a7e29f0373c3b11521c4073d29a))
- **lldap:** add tmp-volume for bootstrapping
  ([ee74146](https://github.com/theepicsaxguy/homelab/commit/ee741467dd050a01200e11a74dc2cc48a6e5360a))
- **lldap:** correct avatar url
  ([668f052](https://github.com/theepicsaxguy/homelab/commit/668f052356f9b68af6cc3eb16006de7187f5f00f))
- media player services
  ([2c1e894](https://github.com/theepicsaxguy/homelab/commit/2c1e894af06da156da65d231396be9e4274962dd))
- **monitoring:** Add a dedicated traefik-forward-auth for monitoring
  ([bfd062a](https://github.com/theepicsaxguy/homelab/commit/bfd062a55285cec75383d37385c9b6d045bc77cc))
- **monitoring:** add renavate rule for updating chart
  ([ab473a5](https://github.com/theepicsaxguy/homelab/commit/ab473a5e08b155dea78d4c452bfcc9f57f3fc6db))
- **monitoring:** Change the way kube-prometheus-stack is applied
  ([b233ef4](https://github.com/theepicsaxguy/homelab/commit/b233ef4873f444ad79e47529aaa857603a3cae75))
- **monitoring:** disable nodeExporter
  ([4c9dc0f](https://github.com/theepicsaxguy/homelab/commit/4c9dc0f2b4872c845f7c494a6af6fa7eb3f270d2))
- **netbird-agent:** allow read root fs and add sysctl
  ([c9ffd69](https://github.com/theepicsaxguy/homelab/commit/c9ffd698c8fe9ec504b653babdbe7c3c484ed6c4))
- **netbird-dashboard:** harden security
  ([1c585e2](https://github.com/theepicsaxguy/homelab/commit/1c585e2ce4b5021b68c1ddb72d2b1c4513874bca))
- **netbird-management:** harden security
  ([a99b4c6](https://github.com/theepicsaxguy/homelab/commit/a99b4c6e14c317b01588c39a29557ad76343e7fc))
- **netbird-relay:** harden security
  ([c35ba49](https://github.com/theepicsaxguy/homelab/commit/c35ba49135b140a23e349676475301045a800441))
- **netbird-signal:** harden security
  ([3cbc35a](https://github.com/theepicsaxguy/homelab/commit/3cbc35aaf95e72f29aabef535deaa9b9eb7fbacd))
- **netbird:** allow required endpoint from keycloak
  ([91e389d](https://github.com/theepicsaxguy/homelab/commit/91e389dc0ec0062d922767a5dbbdac6f96262be7))
- **netbird:** change dashboard redirect URLs
  ([2ec6244](https://github.com/theepicsaxguy/homelab/commit/2ec6244fca6cd10722a6657974083f81cb19cb1c))
- **netbird:** change oidc clientId
  ([fee02d4](https://github.com/theepicsaxguy/homelab/commit/fee02d4b16f410294930365f232056b8305397b2))
- **netbird:** change user_id claim
  ([e658857](https://github.com/theepicsaxguy/homelab/commit/e658857bf897065e8ab8cd8f390bdc63509e946e))
- **netbird:** clean up configuration
  ([ae355bb](https://github.com/theepicsaxguy/homelab/commit/ae355bb42713e736a7bf18b68e6d1445390275d8))
- **netbird:** expose netbird dashboard
  ([944f4a9](https://github.com/theepicsaxguy/homelab/commit/944f4a92baa7c89f609ea7609117fa1b5fb1878e))
- **netbird:** new agent setup key
  ([31c6b25](https://github.com/theepicsaxguy/homelab/commit/31c6b25013e952cc4c3a0ca9ae80549cc307f8fc))
- **netbird:** update oidc client
  ([b07b728](https://github.com/theepicsaxguy/homelab/commit/b07b7288558561e83950d278c5e4c4dd165d9744))
- **netbird:** use internal dns to resolve auth admin-endpoint to internal gateway
  ([505a18c](https://github.com/theepicsaxguy/homelab/commit/505a18cf388e82d1e913318d5c69571292303e12))
- **network:** Conflicting port-names in DNS-deployment
  ([563c2ed](https://github.com/theepicsaxguy/homelab/commit/563c2edc5b1e4221d76598e9c06930d113a8da53))
- **oidc:** add 'basic' scope to netbird client and update keycloak
  ([0e0a356](https://github.com/theepicsaxguy/homelab/commit/0e0a356fd1da96a5a36a8d536b47a01f5dc4fb0d))
- **oidc:** conceal argo cd client secret
  ([53855a6](https://github.com/theepicsaxguy/homelab/commit/53855a6d27c430c3d648ea7a3c40513c952ef382))
- **oidc:** conceal jwks signing key
  ([e0ce01c](https://github.com/theepicsaxguy/homelab/commit/e0ce01c80fab51d6081b44e1ee992aaace6fe861))
- **plex:** switch back to ingressroute for troubleshooting
  ([1738a24](https://github.com/theepicsaxguy/homelab/commit/1738a24f876936ec48ce354a1c374863b5e1d188))
- **plex:** Tidying deployment and adding GPU-support
  ([5a34100](https://github.com/theepicsaxguy/homelab/commit/5a34100a97ed37dd37a723091885899e41358b35))
- **plex:** Use Ingress instead of Gateway
  ([c6e1aad](https://github.com/theepicsaxguy/homelab/commit/c6e1aadb162512b3b64ffbb6c131f4a9a9b44946))
- **projects:** Moving definition of AppProjects
  ([bf4ea4a](https://github.com/theepicsaxguy/homelab/commit/bf4ea4aef1b81735a952e7f039a31d5be41eedcc))
- proxmox-csi-plugin configuration
  ([f65eb23](https://github.com/theepicsaxguy/homelab/commit/f65eb23cc522cd9be151218eb57ab8dfe9950a2e))
- **proxmox-csi-plugin:** fetch from Helm chart
  ([4d2fe61](https://github.com/theepicsaxguy/homelab/commit/4d2fe610e218af25fbbb58e766c69790b738e985))
- **proxmox:** TLS Passthrough GW for again
  ([4eac6c1](https://github.com/theepicsaxguy/homelab/commit/4eac6c1f1cfb79a85f1d761510c254dc7258f122))
- **proxmox:** Using Proxmox Service directly
  ([3197f45](https://github.com/theepicsaxguy/homelab/commit/3197f452a27c8ae9560822c754dff49642db6956))
- **qBit:** Change registry for qBit
  ([83b0c98](https://github.com/theepicsaxguy/homelab/commit/83b0c98dc665814c4d8d9e465171cb01fe3a5ca0))
- **remark42:** correct url
  ([935a130](https://github.com/theepicsaxguy/homelab/commit/935a13038c2b3dd850cf229776222b69262515fd))
- **renovate:** explicitly set versioning scheme for plex
  ([89c0a27](https://github.com/theepicsaxguy/homelab/commit/89c0a273644adfb1cba4ba3cd869c603e08ffba5))
- route plex and jellyfin through gateway for tls-termination
  ([5d69e82](https://github.com/theepicsaxguy/homelab/commit/5d69e82eb70b26ce1f282ce64f3ff9a05f7aad7a))
- pctips routing ([482c036](https://github.com/theepicsaxguy/homelab/commit/482c0368ea09eeda9c170ae8cc4a94ed1193d183))
- **storage:** change storage identifier from local-zfs to rpool3 across configurations
  ([a5513fa](https://github.com/theepicsaxguy/homelab/commit/a5513faf224e001e084f7dbcb98b04525ac180d7))
- **svc:** EndpointSlices should have the same name as the svc
  ([4b63ad0](https://github.com/theepicsaxguy/homelab/commit/4b63ad037ff46a7105d10ebe1787e5b4fc5ce306))
- **talos:** update MAC addresses and disable iGPU for control plane nodes
  ([d89db15](https://github.com/theepicsaxguy/homelab/commit/d89db15161e733532bc34a4bc2aeefc8bfeca5e1))
- **talos:** upgrading now actually works without destroying the cluster
  ([f39dc98](https://github.com/theepicsaxguy/homelab/commit/f39dc98104758b387c3d1145f500e24a9f80ccb9))
- **traefik-argocd:** Ingress stuck in 'Progressing' status
  ([1f0136a](https://github.com/theepicsaxguy/homelab/commit/1f0136a2f208eeaf61b325a74cfea221d8b1bb36))
- **traefik:** Changing ns for Traefik to `traefik` from `traefik-system`
  ([075a60f](https://github.com/theepicsaxguy/homelab/commit/075a60f074d87ec60ec729cf65eae909dc6fe081))
- **traefik:** Harcode internal DNS in Traefik
  ([bf94161](https://github.com/theepicsaxguy/homelab/commit/bf94161a442e108178886da986b1341913dd4e7a))
- update domain names from pctips.dev to pc-tips.se across various configurations
  ([2e5c35f](https://github.com/theepicsaxguy/homelab/commit/2e5c35f67896edb13351606b41d00c64f85e9ae6))
- update renovate syntax
  ([694d56b](https://github.com/theepicsaxguy/homelab/commit/694d56b32dece8bc238a8e1f03bebf6790801152))
- **users:** Add kustomization.yaml in users-folder
  ([4efe769](https://github.com/theepicsaxguy/homelab/commit/4efe7693968902ba49284446da70113f8997c5c4))
- **vpn:** remove read only root fs for netbird agent
  ([02eb0a6](https://github.com/theepicsaxguy/homelab/commit/02eb0a62d7d89a08912d951063901d08a71f6636))
- **vpn:** remove security context for agent
  ([48b6fc3](https://github.com/theepicsaxguy/homelab/commit/48b6fc376a4e11fd68c2bb986a55b2e7a833966b))
