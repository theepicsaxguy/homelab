"""Paper MC version check against the PaperMC Fill v3 API.

The v2 API was retired (HTTP 410). v3 exposes versions grouped by family,
newest first, and a per-version build list carrying a release channel. A
version only counts as released once it has at least one STABLE build — Paper
publishes the version entry while it is still ALPHA.
"""

import os
import re

from http_util import fetch_json

API = "https://fill.papermc.io/v3/projects/paper"
PRERELEASE_MARKERS = ("-pre", "-rc", "-beta", "-snapshot")

# Newest families to probe for a stable build before giving up.
FAMILY_SCAN = 5


def _stable_versions_newest_first() -> list[str]:
    """Flatten the v3 version map, newest first, dropping pre-release tags."""
    data = fetch_json(API)
    flattened = []
    for versions in data["versions"].values():
        for version in versions:
            if not any(marker in version for marker in PRERELEASE_MARKERS):
                flattened.append(version)
    return flattened


def latest_stable_build(version: str) -> int | None:
    """Highest STABLE build id for a Paper version, or None if it has none."""
    try:
        builds = fetch_json(f"{API}/versions/{version}/builds")
    except Exception:
        return None
    stable = [b["id"] for b in builds if b.get("channel") == "STABLE"]
    return max(stable) if stable else None


def _latest_released_version(candidates: list[str]) -> tuple[str, int] | None:
    for version in candidates[:FAMILY_SCAN]:
        build = latest_stable_build(version)
        if build is not None:
            return version, build
    return None


def check_paper_version(kustomization_file: str) -> bool:
    """Update VERSION= in kustomization.yaml to the newest released Paper.

    Returns True when the file was changed.
    """
    if not os.path.exists(kustomization_file):
        print("  [skip]  kustomization.yaml not found, skipping Paper version check")
        return False

    with open(kustomization_file) as f:
        content = f.read()

    match = re.search(r"- VERSION=(\S+)", content)
    if not match:
        print("  [skip]  VERSION not found in kustomization.yaml")
        return False

    current = match.group(1)

    try:
        candidates = _stable_versions_newest_first()
    except Exception as e:
        print(f"  [WARN]  Could not check Paper versions: {e}")
        return False

    released = _latest_released_version(candidates)
    if released is None:
        print(f"  [WARN]  No released Paper version found in the newest "
              f"{FAMILY_SCAN} candidates; keeping {current}")
        return False

    latest, build = released

    if latest == current:
        print(f"  [ok]    Paper {current} (latest stable build #{build})")
        return False

    if current not in candidates:
        print(f"  [info]  Paper VERSION={current} is not a released version in "
              f"the API (latest released={latest}). Update manually if needed.")
        return False

    if candidates.index(current) < candidates.index(latest):
        print(f"  [ok]    Paper {current} is ahead of the latest released "
              f"{latest}; keeping it")
        return False

    with open(kustomization_file, "w") as f:
        f.write(content.replace(f"- VERSION={current}", f"- VERSION={latest}"))

    print(f"  [UP]    Paper {current} -> {latest} (stable build #{build})")
    return True
