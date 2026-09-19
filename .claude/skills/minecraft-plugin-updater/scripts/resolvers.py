"""Per-source plugin resolvers.

Each resolver returns (new_url, version_label) or raises.

GeyserMC note: Geyser/Floodgate download as fixed filenames (no version in the
name), so mc-image-helper's manifest never detects a version change. The init
container in statefulset.yaml always deletes these jars to force a fresh
download. The URLs here use specific build numbers (not `builds/latest`) so
changes are visible in git.
"""

from fnmatch import fnmatch

from http_util import fetch_json

# How many GitHub releases to scan back when the newest one carries no jars.
GITHUB_RELEASE_SCAN = 10


def resolve_geysermc(project: str) -> tuple[str, str]:
    """Latest release version + specific build number for a GeyserMC project."""
    meta = fetch_json(f"https://download.geysermc.org/v2/projects/{project}")
    version = meta["versions"][-1]
    build_meta = fetch_json(
        f"https://download.geysermc.org/v2/projects/{project}"
        f"/versions/{version}/builds/latest"
    )
    build = build_meta["build"]
    url = (
        f"https://download.geysermc.org/v2/projects/{project}"
        f"/versions/{version}/builds/{build}/downloads/spigot"
    )
    return url, f"{version}-b{build}"


def resolve_github(repo: str, asset_glob: str) -> tuple[str, str]:
    """Newest GitHub release that actually publishes an asset matching the glob.

    Upstream sometimes tags a release before (or without) attaching jars — FAWE
    2.15.4 is one. Falling back to the newest release that has a matching asset
    keeps the updater moving instead of stalling on an assetless tag.
    """
    releases = fetch_json(
        f"https://api.github.com/repos/{repo}/releases?per_page={GITHUB_RELEASE_SCAN}"
    )
    published = [r for r in releases if not r.get("draft")]

    for release in published:
        for asset in release.get("assets", []):
            if fnmatch(asset["name"], asset_glob):
                return asset["browser_download_url"], release["tag_name"]

    scanned = [r["tag_name"] for r in published]
    raise ValueError(
        f"No asset matching '{asset_glob}' in the last {len(scanned)} "
        f"{repo} releases: {scanned}"
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
    return latest["files"][0]["url"], latest["version_number"]


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
