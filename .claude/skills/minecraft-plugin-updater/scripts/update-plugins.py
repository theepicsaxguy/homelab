#!/usr/bin/env python3
"""
Update Minecraft plugin URLs in plugins.txt to their latest versions,
and check the Paper MC version in the sibling kustomization.yaml.

Per-source resolution lives in resolvers.py, the Paper check in papermc.py.
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from http_util import url_ok  # noqa: E402
from papermc import check_paper_version, configured_version  # noqa: E402
from resolvers import find_resolver, set_target_minecraft_version  # noqa: E402

REPO_MINECRAFT_PATH = "k8s/applications/games/minecraft"


def _short_name(url: str) -> str:
    """Return a human-readable name for a URL (last meaningful path segment)."""
    parts = url.rstrip("/").split("/")
    # For GeyserMC URLs ending in /spigot, include the version segment too
    if parts and parts[-1] == "spigot":
        version_idx = next(
            (i for i, p in enumerate(parts) if re.match(r"\d+\.\d+", p)), None
        )
        if version_idx:
            return "/".join(parts[version_idx:])
    return parts[-1] or url


def update_plugins(plugins_file: str) -> bool:
    """Rewrite plugins_file with resolved URLs. Returns True when changed."""
    with open(plugins_file) as f:
        urls = [line.strip() for line in f.read().splitlines() if line.strip()]

    updated = []
    changed = False

    for old_url in urls:
        resolver = find_resolver(old_url)

        if resolver is None:
            print(f"  [skip]  {old_url}")
            updated.append(old_url)
            continue

        try:
            new_url, label = resolver(old_url)
        except Exception as e:
            print(f"  [WARN]  Could not resolve {old_url[:70]}\n          {e}")
            updated.append(old_url)
            continue

        if new_url == old_url:
            print(f"  [ok]    {_short_name(old_url)} ({label})")
            updated.append(old_url)
            continue

        if not url_ok(new_url):
            print(f"  [WARN]  New URL non-2xx, keeping old:\n          {new_url}")
            updated.append(old_url)
            continue

        print(f"  [UP]    {_short_name(old_url)}")
        print(f"       -> {_short_name(new_url)}  ({label})")
        updated.append(new_url)
        changed = True

    if changed:
        with open(plugins_file, "w") as f:
            f.write("\n".join(updated) + "\n")

    return changed


def main():
    if len(sys.argv) < 2:
        print(f"usage: {os.path.basename(sys.argv[0])} <path to plugins.txt>",
              file=sys.stderr)
        return 2

    plugins_file = sys.argv[1]
    if not os.path.exists(plugins_file):
        print(f"error: {plugins_file} not found", file=sys.stderr)
        return 1

    kustomization_file = os.path.join(
        os.path.dirname(os.path.abspath(plugins_file)), "kustomization.yaml"
    )

    # Resolved before the plugin pass so version-aware sources (Modrinth) can
    # refuse a jar that no longer supports the Paper version this server pins.
    set_target_minecraft_version(configured_version(kustomization_file))

    print("=== Plugins ===")
    plugins_changed = update_plugins(plugins_file)
    if plugins_changed:
        print(f"\nWritten: {plugins_file}")

    print()
    print("=== Paper MC version ===")
    paper_changed = check_paper_version(kustomization_file)

    print()
    if plugins_changed or paper_changed:
        print("Next steps:")
        print(f"  kustomize build --enable-helm {REPO_MINECRAFT_PATH}")
        print("  Commit and let Argo CD roll the StatefulSet")
    else:
        print("Everything is up to date.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
