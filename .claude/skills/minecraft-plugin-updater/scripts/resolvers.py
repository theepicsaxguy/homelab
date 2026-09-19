"""Per-source plugin resolvers.

Each resolver returns (new_url, version_label) or raises.

GeyserMC note: Geyser/Floodgate download as fixed filenames (no version in the
name), so mc-image-helper's manifest never detects a version change. The init
container in statefulset.yaml always deletes these jars to force a fresh
download. The URLs here use specific build numbers (not `builds/latest`) so
changes are visible in git.
"""

from fnmatch import fnmatch
from urllib.parse import urlparse

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


def _host(url: str) -> str:
    """Hostname of a URL, lowercased and without a port."""
    return (urlparse(url).hostname or "").lower()


def _from(host: str, path_fragment: str = ""):
    """Match a URL by exact host, optionally also requiring a path fragment.

    Matching the parsed hostname rather than a substring of the whole URL keeps
    a lookalike domain (or a host smuggled into a query string) from routing to
    the wrong resolver.
    """
    def matcher(url: str) -> bool:
        return _host(url) == host and path_fragment in urlparse(url).path
    return matcher


def _github_repo(repo: str, requires: str = "", excludes: tuple[str, ...] = ()):
    """Match a github.com release URL for a repo, refined by filename hints."""
    def matcher(url: str) -> bool:
        if _host(url) != "github.com":
            return False
        path = urlparse(url).path
        if not path.startswith(f"/{repo}/"):
            return False
        return requires in path and not any(x in path for x in excludes)
    return matcher


GEYSER_HOST = "download.geysermc.org"

RESOLVERS = [
    (_from(GEYSER_HOST, "/projects/geyser/"),
     lambda _: resolve_geysermc("geyser")),
    (_from(GEYSER_HOST, "/projects/floodgate/"),
     lambda _: resolve_geysermc("floodgate")),
    (_github_repo("SniperTVmc/EssentialsX-GUI"),
     lambda _: resolve_github("SniperTVmc/EssentialsX-GUI", "EssentialsX-GUI-*.jar")),
    (_github_repo("IntellectualSites/FastAsyncWorldEdit"),
     lambda _: resolve_github("IntellectualSites/FastAsyncWorldEdit",
                              "FastAsyncWorldEdit-Paper-*.jar")),
    (_github_repo("EssentialsX/Essentials", requires="EssentialsXChat"),
     lambda _: resolve_github("EssentialsX/Essentials", "EssentialsXChat-*.jar")),
    (_github_repo("EssentialsX/Essentials", requires="EssentialsXSpawn"),
     lambda _: resolve_github("EssentialsX/Essentials", "EssentialsXSpawn-*.jar")),
    (_github_repo("EssentialsX/Essentials",
                  excludes=("EssentialsXChat", "EssentialsXSpawn")),
     lambda _: resolve_github("EssentialsX/Essentials", "EssentialsX-[0-9]*.jar")),
    (_github_repo("Multiverse/Multiverse-Core"),
     lambda _: resolve_github("Multiverse/Multiverse-Core", "multiverse-core-*.jar")),
    (_github_repo("Multiverse/Multiverse-SignPortals"),
     lambda _: resolve_github("Multiverse/Multiverse-SignPortals",
                              "multiverse-signportals-*.jar")),
    (_github_repo("MilkBowl/Vault"),
     lambda _: resolve_github("MilkBowl/Vault", "Vault.jar")),
    (_from("download.luckperms.net"),
     lambda _: resolve_luckperms()),
    (_from("hub.bg-software.com", "/job/WildLoaders"),
     lambda _: resolve_wildloaders()),
    (_from("cdn.modrinth.com"),
     lambda _: resolve_modrinth("gES9lvaL")),
    # Static redirect to the newest file; there is no version to track.
    (_from("api.spiget.org"), None),
]


def find_resolver(url: str):
    for matcher, resolver in RESOLVERS:
        if matcher(url):
            return resolver
    return None
