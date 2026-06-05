#!/usr/bin/env python3
"""
Update Minecraft plugin URLs in plugins.txt to their latest versions,
and check the Paper MC version in kustomization.yaml.

Each plugin source has its own resolver returning (new_url, version_label).

GeyserMC note: Geyser/Floodgate download as fixed filenames (no version in name),
so mc-image-helper's manifest never detects a version change. The init container
in statefulset.yaml always deletes these jars to force a fresh download. The URLs
here use specific build numbers (not `builds/latest`) so changes are visible in git.
"""

import os
import re
import sys
import json
import urllib.request
import urllib.error
from fnmatch import fnmatch

PLUGINS_FILE = sys.argv[1] if len(sys.argv) > 1 else \
    "/home/develop/homelab/k8s/applications/games/minecraft/plugins/plugins.txt"

KUSTOMIZATION_FILE = os.path.join(
    os.path.dirname(PLUGINS_FILE), "kustomization.yaml"
)

TIMEOUT = 15


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------

def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "minecraft-plugin-updater/1.0"})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        return json.loads(r.read())


def url_ok(url):
    """Return True if url responds with 2xx/3xx (follows redirects)."""
    try:
        req = urllib.request.Request(
            url,
            method="HEAD",
            headers={"User-Agent": "minecraft-plugin-updater/1.0"},
        )
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            return r.status < 400
    except Exception:
        try:
            req = urllib.request.Request(
                url,
                headers={"User-Agent": "minecraft-plugin-updater/1.0"},
            )
            with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
                return r.status < 400
        except Exception:
            return False


# ---------------------------------------------------------------------------
# Resolvers — each returns (new_url: str, label: str) or raises
# ---------------------------------------------------------------------------

def resolve_geysermc(project: str) -> tuple[str, str]:
    """Latest release version + specific build number for a GeyserMC project.

    Uses the exact build number (not `builds/latest`) so the URL changes in git
    when a new build ships, making the update visible and trackable.
    """
    meta = fetch_json(f"https://download.geysermc.org/v2/projects/{project}")
    version = meta["versions"][-1]
    build_meta = fetch_json(
        f"https://download.geysermc.org/v2/projects/{project}/versions/{version}/builds/latest"
    )
    build = build_meta["build"]
    url = (
        f"https://download.geysermc.org/v2/projects/{project}"
        f"/versions/{version}/builds/{build}/downloads/spigot"
    )
    return url, f"{version}-b{build}"


def resolve_github(repo: str, asset_glob: str) -> tuple[str, str]:
    """Latest GitHub release asset matching a glob pattern."""
    data = fetch_json(f"https://api.github.com/repos/{repo}/releases/latest")
    tag = data["tag_name"]
    for asset in data["assets"]:
        if fnmatch(asset["name"], asset_glob):
            return asset["browser_download_url"], tag
    raise ValueError(
        f"No asset matching '{asset_glob}' in {repo} {tag}. "
        f"Available: {[a['name'] for a in data['assets']]}"
    )


def resolve_luckperms() -> tuple[str, str]:
    """Latest successful LuckPerms build from ci.lucko.me."""
    data = fetch_json("https://ci.lucko.me/job/LuckPerms/lastSuccessfulBuild/api/json")
    build = data["number"]
    filename = next(
        a["fileName"] for a in data["artifacts"]
        if "Bukkit" in a["fileName"] and "Legacy" not in a["fileName"]
    )
    url = f"https://download.luckperms.net/{build}/bukkit/loader/{filename}"
    return url, f"build-{build}"


def resolve_wildloaders() -> tuple[str, str]:
    """Latest successful WildLoaders build from hub.bg-software.com."""
    base = "https://hub.bg-software.com/job/WildLoaders%20-%20Dev%20Builds"
    data = fetch_json(f"{base}/lastSuccessfulBuild/api/json")
    build = data["number"]
    filename = next(
        a["fileName"] for a in data["artifacts"] if a["fileName"].endswith(".jar")
    )
    url = f"{base}/{build}/artifact/target/{filename}"
    return url, f"build-{build}"


def resolve_modrinth(project_id: str) -> tuple[str, str]:
    """Latest Modrinth version for a project."""
    versions = fetch_json(f"https://api.modrinth.com/v2/project/{project_id}/version")
    latest = versions[0]
    file_url = latest["files"][0]["url"]
    return file_url, latest["version_number"]


# ---------------------------------------------------------------------------
# URL → resolver mapping
# ---------------------------------------------------------------------------

def _contains(fragment):
    return lambda url: fragment in url


RESOLVERS = [
    (_contains("download.geysermc.org/v2/projects/geyser"),
     lambda _: resolve_geysermc("geyser")),
    (_contains("download.geysermc.org/v2/projects/floodgate"),
     lambda _: resolve_geysermc("floodgate")),
    (_contains("SniperTVmc/EssentialsX-GUI"),
     lambda _: resolve_github("SniperTVmc/EssentialsX-GUI", "EssentialsX-GUI-*.jar")),
    (_contains("IntellectualSites/FastAsyncWorldEdit"),
     lambda _: resolve_github("IntellectualSites/FastAsyncWorldEdit",
                              "FastAsyncWorldEdit-Paper-*.jar")),
    (lambda url: "EssentialsX/Essentials" in url and "EssentialsXChat" in url,
     lambda _: resolve_github("EssentialsX/Essentials", "EssentialsXChat-*.jar")),
    (lambda url: "EssentialsX/Essentials" in url and "EssentialsXSpawn" in url,
     lambda _: resolve_github("EssentialsX/Essentials", "EssentialsXSpawn-*.jar")),
    (lambda url: "EssentialsX/Essentials" in url
                 and "EssentialsXChat" not in url and "EssentialsXSpawn" not in url,
     lambda _: resolve_github("EssentialsX/Essentials", "EssentialsX-[0-9]*.jar")),
    (lambda url: "Multiverse/Multiverse-Core" in url and "SignPortals" not in url,
     lambda _: resolve_github("Multiverse/Multiverse-Core", "multiverse-core-*.jar")),
    (_contains("Multiverse/Multiverse-SignPortals"),
     lambda _: resolve_github("Multiverse/Multiverse-SignPortals",
                              "multiverse-signportals-*.jar")),
    (_contains("MilkBowl/Vault"),
     lambda _: resolve_github("MilkBowl/Vault", "Vault.jar")),
    (_contains("luckperms"),
     lambda _: resolve_luckperms()),
    (_contains("WildLoaders"),
     lambda _: resolve_wildloaders()),
    (lambda url: "modrinth.com" in url or "gES9lvaL" in url,
     lambda _: resolve_modrinth("gES9lvaL")),
    (_contains("api.spiget.org"), None),  # static redirect, no version to track
]


def find_resolver(url: str):
    for matcher, resolver in RESOLVERS:
        if matcher(url):
            return resolver
    return None


# ---------------------------------------------------------------------------
# Paper MC version check
# ---------------------------------------------------------------------------

def _latest_stable_paper_build(version: str) -> int | None:
    """Return the highest STABLE build number for a Paper version, or None."""
    for host in ("https://fill.papermc.io", "https://api.papermc.io"):
        try:
            data = fetch_json(f"{host}/v2/projects/paper/versions/{version}/builds")
            stable = [b["build"] for b in data["builds"] if b.get("channel") == "STABLE"]
            return max(stable) if stable else None
        except Exception:
            continue
    return None


def check_paper_version():
    """Check if a newer Paper MC version is available and update kustomization.yaml.

    Paper switched versioning from 1.21.x (tracked in their v2 API) to a new
    scheme (26.x.x displayed on papermc.io). The v2 API still lists versions as
    1.21.x; itzg/minecraft-server accepts either form. We check the API for the
    latest 1.21.x release and also try the version string from kustomization.yaml
    directly to handle the transition gracefully.
    """
    if not os.path.exists(KUSTOMIZATION_FILE):
        print("  [skip]  kustomization.yaml not found, skipping Paper version check")
        return

    with open(KUSTOMIZATION_FILE) as f:
        content = f.read()

    match = re.search(r"- VERSION=(\S+)", content)
    if not match:
        print("  [skip]  VERSION not found in kustomization.yaml")
        return

    current_version = match.group(1)

    # Determine latest from API (returns 1.21.x-style versions)
    try:
        data = fetch_json("https://fill.papermc.io/v2/projects/paper")
        # Only consider stable final releases (no pre/rc suffixes)
        stable_versions = [
            v for v in data["versions"]
            if not any(s in v for s in ("-pre", "-rc", "-beta"))
        ]
        api_latest = stable_versions[-1] if stable_versions else None
    except Exception as e:
        print(f"  [WARN]  Could not check Paper versions: {e}")
        return

    # If the current version isn't in the API (e.g. new 26.x.x scheme),
    # report what the API says but don't overwrite — user controls the version.
    if api_latest and current_version not in data["versions"]:
        print(f"  [info]  Paper VERSION={current_version} (not in API; "
              f"API latest={api_latest}). Update manually if needed.")
        return

    if not api_latest or api_latest == current_version:
        build = _latest_stable_paper_build(current_version) if api_latest else None
        suffix = f" (latest stable build #{build})" if build else ""
        print(f"  [ok]    Paper {current_version}{suffix}")
        return

    # There's a newer version in the API
    new_content = content.replace(
        f"- VERSION={current_version}",
        f"- VERSION={api_latest}",
    )
    with open(KUSTOMIZATION_FILE, "w") as f:
        f.write(new_content)

    print(f"  [UP]    Paper {current_version} -> {api_latest}")
    return True


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

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


def main():
    print("=== Plugins ===")
    with open(PLUGINS_FILE) as f:
        lines = f.read().splitlines()

    urls = [l.strip() for l in lines if l.strip()]
    updated_lines = []
    any_changed = False

    for old_url in urls:
        resolver = find_resolver(old_url)

        if resolver is None:
            print(f"  [skip]  {old_url}")
            updated_lines.append(old_url)
            continue

        try:
            new_url, label = resolver(old_url)
        except Exception as e:
            print(f"  [WARN]  Could not resolve {old_url[:70]}\n          {e}")
            updated_lines.append(old_url)
            continue

        if new_url == old_url:
            print(f"  [ok]    {_short_name(old_url)} ({label})")
            updated_lines.append(old_url)
            continue

        if not url_ok(new_url):
            print(f"  [WARN]  New URL non-2xx, keeping old:\n          {new_url}")
            updated_lines.append(old_url)
            continue

        print(f"  [UP]    {_short_name(old_url)}")
        print(f"       -> {_short_name(new_url)}  ({label})")
        updated_lines.append(new_url)
        any_changed = True

    print()
    print("=== Paper MC version ===")
    paper_changed = check_paper_version()

    print()
    if any_changed:
        with open(PLUGINS_FILE, "w") as f:
            f.write("\n".join(updated_lines) + "\n")
        print(f"Written: {PLUGINS_FILE}")

    if any_changed or paper_changed:
        print()
        print("Next steps:")
        print("  kustomize build --enable-helm "
              "/home/develop/homelab/k8s/applications/games/minecraft")
        print("  kubectl apply -k "
              "/home/develop/homelab/k8s/applications/games/minecraft")
        print("  kubectl delete pod -n minecraft minecraft-bedrock-0")
    else:
        print("Everything is up to date.")


if __name__ == "__main__":
    main()
