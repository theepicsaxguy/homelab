#!/usr/bin/env python3
"""
Update Minecraft plugin URLs in plugins.txt to their latest versions.
Each plugin source has its own resolver that returns (new_url, version_label).
"""

import sys
import json
import urllib.request
import urllib.error
from fnmatch import fnmatch

PLUGINS_FILE = sys.argv[1] if len(sys.argv) > 1 else \
    "/home/develop/homelab/k8s/applications/games/minecraft/plugins/plugins.txt"

TIMEOUT = 15


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------

def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "minecraft-plugin-updater/1.0"})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        return json.loads(r.read())


def url_ok(url):
    """Return True if url responds with 2xx/3xx."""
    try:
        req = urllib.request.Request(
            url,
            method="HEAD",
            headers={"User-Agent": "minecraft-plugin-updater/1.0"},
        )
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            return r.status < 400
    except Exception:
        # HEAD may not be allowed; fall back to GET with no body read
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
    """Latest release version + build for a GeyserMC project."""
    meta = fetch_json(f"https://download.geysermc.org/v2/projects/{project}")
    version = meta["versions"][-1]
    url = (
        f"https://download.geysermc.org/v2/projects/{project}"
        f"/versions/{version}/builds/latest/downloads/spigot"
    )
    return url, version


def resolve_github(repo: str, asset_glob: str) -> tuple[str, str]:
    """Latest GitHub release asset matching a glob pattern."""
    data = fetch_json(f"https://api.github.com/repos/{repo}/releases/latest")
    tag = data["tag_name"]
    for asset in data["assets"]:
        if fnmatch(asset["name"], asset_glob):
            return asset["browser_download_url"], tag
    raise ValueError(f"No asset matching '{asset_glob}' in {repo} {tag}. "
                     f"Available: {[a['name'] for a in data['assets']]}")


def resolve_luckperms() -> tuple[str, str]:
    """Latest successful LuckPerms build from ci.lucko.me."""
    data = fetch_json("https://ci.lucko.me/job/LuckPerms/lastSuccessfulBuild/api/json")
    build = data["number"]
    filename = next(
        a["fileName"] for a in data["artifacts"] if "Bukkit" in a["fileName"]
        and "Legacy" not in a["fileName"]
    )
    url = f"https://download.luckperms.net/{build}/bukkit/loader/{filename}"
    return url, f"build-{build}"


def resolve_wildloaders() -> tuple[str, str]:
    """Latest successful WildLoaders build from hub.bg-software.com."""
    base = "https://hub.bg-software.com/job/WildLoaders%20-%20Dev%20Builds"
    data = fetch_json(f"{base}/lastSuccessfulBuild/api/json")
    build = data["number"]
    filename = next(
        a["fileName"] for a in data["artifacts"]
        if a["fileName"].endswith(".jar")
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
# Each entry: (matcher, resolver_fn)
# matcher is called with the old URL and returns True if this resolver owns it.
# ---------------------------------------------------------------------------

def _contains(fragment):
    return lambda url: fragment in url


RESOLVERS = [
    # GeyserMC — geyser
    (
        _contains("download.geysermc.org/v2/projects/geyser"),
        lambda _: resolve_geysermc("geyser"),
    ),
    # GeyserMC — floodgate
    (
        _contains("download.geysermc.org/v2/projects/floodgate"),
        lambda _: resolve_geysermc("floodgate"),
    ),
    # EssentialsX-GUI
    (
        _contains("SniperTVmc/EssentialsX-GUI"),
        lambda _: resolve_github("SniperTVmc/EssentialsX-GUI", "EssentialsX-GUI-*.jar"),
    ),
    # FastAsyncWorldEdit
    (
        _contains("IntellectualSites/FastAsyncWorldEdit"),
        lambda _: resolve_github(
            "IntellectualSites/FastAsyncWorldEdit",
            "FastAsyncWorldEdit-Paper-*.jar",
        ),
    ),
    # EssentialsX (Chat)
    (
        lambda url: "EssentialsX/Essentials" in url and "EssentialsXChat" in url,
        lambda _: resolve_github("EssentialsX/Essentials", "EssentialsXChat-*.jar"),
    ),
    # EssentialsX (Spawn)
    (
        lambda url: "EssentialsX/Essentials" in url and "EssentialsXSpawn" in url,
        lambda _: resolve_github("EssentialsX/Essentials", "EssentialsXSpawn-*.jar"),
    ),
    # EssentialsX (core — must come after Chat/Spawn)
    (
        lambda url: "EssentialsX/Essentials" in url and "EssentialsXChat" not in url
                    and "EssentialsXSpawn" not in url,
        lambda _: resolve_github("EssentialsX/Essentials", "EssentialsX-[0-9]*.jar"),
    ),
    # Multiverse-Core
    (
        lambda url: "Multiverse/Multiverse-Core" in url and "SignPortals" not in url,
        lambda _: resolve_github("Multiverse/Multiverse-Core", "multiverse-core-*.jar"),
    ),
    # Multiverse-SignPortals
    (
        _contains("Multiverse/Multiverse-SignPortals"),
        lambda _: resolve_github(
            "Multiverse/Multiverse-SignPortals",
            "multiverse-signportals-*.jar",
        ),
    ),
    # Vault
    (
        _contains("MilkBowl/Vault"),
        lambda _: resolve_github("MilkBowl/Vault", "Vault.jar"),
    ),
    # LuckPerms
    (
        _contains("luckperms"),
        lambda _: resolve_luckperms(),
    ),
    # WildLoaders
    (
        _contains("WildLoaders"),
        lambda _: resolve_wildloaders(),
    ),
    # CustomCommands (Modrinth project gES9lvaL)
    (
        lambda url: "modrinth.com" in url or "gES9lvaL" in url,
        lambda _: resolve_modrinth("gES9lvaL"),
    ),
    # Spiget static — no version available, keep as-is
    (
        _contains("api.spiget.org"),
        None,  # None signals "keep unchanged"
    ),
]


def find_resolver(url: str):
    for matcher, resolver in RESOLVERS:
        if matcher(url):
            return resolver
    return None  # unknown URL — keep as-is


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    with open(PLUGINS_FILE) as f:
        lines = f.read().splitlines()

    urls = [l.strip() for l in lines if l.strip()]

    updated_lines = []
    any_changed = False

    for old_url in urls:
        resolver = find_resolver(old_url)

        if resolver is None:
            # Spiget or truly unknown — keep unchanged
            print(f"  [skip]  {old_url}")
            updated_lines.append(old_url)
            continue

        try:
            new_url, label = resolver(old_url)
        except Exception as e:
            print(f"  [WARN]  Could not resolve {old_url[:70]}...\n          {e}")
            updated_lines.append(old_url)
            continue

        if new_url == old_url:
            print(f"  [ok]    {old_url.split('/')[-1] or old_url} ({label})")
            updated_lines.append(old_url)
            continue

        # Validate before committing
        if not url_ok(new_url):
            print(f"  [WARN]  New URL returned non-2xx, keeping old:\n"
                  f"          {new_url}")
            updated_lines.append(old_url)
            continue

        old_name = old_url.rstrip("/").split("/")[-1] or old_url
        new_name = new_url.rstrip("/").split("/")[-1] or new_url
        print(f"  [UP]    {old_name}")
        print(f"       -> {new_name}  ({label})")
        updated_lines.append(new_url)
        any_changed = True

    print()
    if any_changed:
        with open(PLUGINS_FILE, "w") as f:
            f.write("\n".join(updated_lines) + "\n")
        print(f"Written: {PLUGINS_FILE}")
        print()
        print("Next steps:")
        print("  kustomize build --enable-helm "
              "/home/develop/homelab/k8s/applications/games/minecraft")
        print("  kubectl apply -k "
              "/home/develop/homelab/k8s/applications/games/minecraft")
        print("  kubectl delete pod -n minecraft minecraft-bedrock-0")
    else:
        print("All plugins are up to date — plugins.txt unchanged.")


if __name__ == "__main__":
    main()
