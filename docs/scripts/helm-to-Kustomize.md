# Helm-to-Kustomize Conversion Script Documentation

This script converts a Helm chart into a Kustomize directory structure. It renders the Helm chart (with an option to
include CRDs), splits the rendered output into individual resource manifests, and then creates Kustomize base and
overlay directories.

---

## Overview

The script performs the following tasks:

1. **Archives Existing Files:** Moves existing `kustomization.yaml` and `values.yaml` files in the target directory into
   an archive subdirectory.
2. **Reads Configuration:** Extracts dynamic values (chart name, repository, version, release name, namespace, values
   file, and optional CRDs settings) from an archived `kustomization.yaml`.
3. **Helm Rendering:** Uses the `helm template` command to render the chart into a single YAML file. If the
   `includeCRDS` flag is true, it passes the `--include-crds` option.
4. **Splitting Manifests:** Splits the rendered YAML into separate files using `csplit`. Resources with
   `kind: CustomResourceDefinition` are moved to a dedicated CRDS directory.
5. **External CRDs Fallback:** If no CRDs are rendered via Helm and external CRDs URLs are provided, the script attempts
   to fetch CRDs from these URLs.
6. **Kustomization Files:** Generates base and overlay kustomization files that reference the individual manifests and
   any external resources (e.g., CRDs, announce, ip-pool).
7. **Logging & Error Handling:** Provides timestamped, color-coded logging and robust error handling.

---

## Prerequisites

- **Bash Shell:** The script is written in bash.
- **Required Commands:** The following commands must be installed and available in your PATH:
  - `helm`
  - `yq`
  - `curl`
  - `csplit`
- **Input Directory Structure:** The target directory should contain a `kustomization.yaml` and `values.yaml` that will
  be archived and used for configuration.

---

## Configuration

The script expects an archived `kustomization.yaml` (moved to the `archive/` directory) with the following structure
under the first entry of `helmCharts`:

```yaml
helmCharts:
  - name: <helm-chart-name>
    repo: <helm-chart-repository>
    version: <chart-version>
    releaseName: <helm-release-name>
    namespace: <namespace>
    valuesFile: <path-to-values-file> # Relative to the original directory
    includeCRDS: true|false # (Optional) Whether to include CRDs during rendering
    crdsUrls: # (Optional) External URLs as an array to fetch CRDs if needed
      - https://example.com/path/to/crds.yaml
      - https://another.example.com/crds.yaml
```

- **includeCRDS:** If set to `true`, the script will pass `--include-crds` to the `helm template` command so that CRDs
  are rendered.

- **crdsUrls:** If no CRDs are rendered by Helm and external CRDs URLs are provided, the script will fetch CRDs from
  these URLs as a fallback.

---

## Directory Structure

After execution, the target directory is organized as follows:

```
<target-directory>/
├── archive/                 # Archived original kustomization.yaml and values.yaml
├── base/                    # Contains split resource manifests and a base kustomization.yaml
├── crds/                    # Contains CustomResourceDefinition manifests (rendered or externally fetched)
├── overlays/
│   ├── production/          # Production overlay with its kustomization.yaml and sample patch
│   └── development/         # Development overlay with its kustomization.yaml and sample patch
└── kustomization.yaml       # Root-level kustomization that references base/ and possibly crds/
```

---

## How the Script Works

1. **Input Validation & Archiving:**

   - Validates that exactly one argument (the target directory) is provided.
   - Checks if the required commands exist.
   - Archives existing `kustomization.yaml` and `values.yaml` from the target directory into the `archive/`
     subdirectory.

2. **Configuration Extraction:**

   - Reads the archived `kustomization.yaml` and extracts the helm chart parameters using `yq`.
   - Reads the `includeCRDS` flag and optional external CRDs URLs.

3. **Helm Chart Rendering:**

   - Constructs the `helm template` command.
   - If `includeCRDS` is true, adds the `--include-crds` flag.
   - Renders the chart into a single YAML file.

4. **Splitting Manifests:**

   - Uses `csplit` to break the single YAML file into separate files.
   - Each file is checked with `yq` to extract its `kind` and `metadata.name`.
   - Files with `kind: CustomResourceDefinition` are moved into the `crds/` directory.

5. **External CRDs Fetching:**

   - If the `includeCRDS` flag is true but no CRDs are rendered, the script checks for external CRDs URLs.
   - If URLs exist, it fetches CRDs from these URLs using `curl` and concatenates them into a CRDs file.

6. **Kustomization Generation:**

   - Generates a base `kustomization.yaml` that references all resource files in the base directory and, if available,
     CRDs.
   - Creates overlay directories (production and development) with their own `kustomization.yaml` and a sample patch.
   - Creates a root-level `kustomization.yaml` that aggregates the base and, if available, CRDs.

7. **Logging:**

   - Throughout the process, the script logs key actions with timestamps and colored output to make it easier to follow
     progress.

8. **Final Output:**
   - The script displays instructions on how to deploy the resulting Kustomize resources with `kubectl apply -k`
     commands for base, overlays, and root-level configuration.

---

## How to Run

Place the script in your project (e.g., `helm-to-kustomize.sh`), ensure it is executable, and run it with the target
directory as an argument:

```bash
chmod +x helm-to-kustomize.sh
./helm-to-kustomize.sh <target-directory>
```

Example:

```bash
./helm-to-kustomize.sh k8s/infrastructure/base/network/cilium2
```

---

## Troubleshooting

- **Missing Commands:** If any required commands (helm, yq, curl, csplit) are missing, the script will exit with an
  error message. Install these tools and try again.

- **Incorrect Configuration:** Ensure that the archived `kustomization.yaml` in your target directory contains the
  expected helmCharts structure with all necessary fields. Missing fields will cause the script to exit.

- **CRDs Not Found:** If `includeCRDS` is true but no CRDs are rendered and no external CRDs URLs are provided (or
  fetching fails), the script logs a warning. Verify that your Helm chart includes CRDs or supply valid external URLs.
