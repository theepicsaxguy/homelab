"""SABnzbd container entrypoint with PUID/PGID support and config management."""

import os
import sys
import configparser
import pathlib
import pwd
import grp

# === Core, overridable defaults ===
cfg_dir = os.getenv("SAB_CONFIG_DIR", "/config")
cfg_file = os.path.join(cfg_dir, "sabnzbd.ini")
overwrite = os.getenv("SAB_OVERWRITE_CONFIG", "true").lower() == "true"

downloads = os.getenv("SAB_DOWNLOAD_DIR", "/downloads")
incomplete = os.getenv("SAB_INCOMPLETE_DIR", f"{downloads}/incomplete")
complete = os.getenv("SAB_COMPLETE_DIR", f"{downloads}/complete")
host = os.getenv("SAB_HOST", "0.0.0.0")
PORT = str(os.getenv("SAB_PORT", "8080"))

# PUID/PGID mapping (LSIO/hotio/binhex convention)
PUID = int(os.getenv("PUID", "1000"))
PGID = int(os.getenv("PGID", "1000"))

# Ensure dirs exist before ownership and config write
for p in (cfg_dir, downloads, incomplete, complete):
    pathlib.Path(p).mkdir(parents=True, exist_ok=True)


def ensure_uid_gid(uid: int, gid: int):
    """Create user and group if they don't exist."""
    try:
        grp.getgrgid(gid)
    except KeyError:
        os.system(f"addgroup -g {gid} sab || true")
    try:
        pwd.getpwuid(uid)
    except KeyError:
        os.system(f"adduser -D -H -u {uid} -G sab -s /sbin/nologin sab || true")


ensure_uid_gid(PUID, PGID)

# Make sure config dir is owned by target uid:gid so SAB can write logs/state
try:
    os.chown(cfg_dir, PUID, PGID)
except PermissionError:
    pass


# === Build sabnzbd.ini from env deterministically ===
class _CaseConfigParser(configparser.ConfigParser):
    """ConfigParser preserving option key case."""

    def optionxform(self, optionstr: str) -> str:  # type: ignore[override]
        return optionstr


cfg = _CaseConfigParser()

if not overwrite and os.path.exists(cfg_file):
    cfg.read(cfg_file)

for section in ("misc", "folders"):
    if section not in cfg:
        cfg[section] = {}

# Baseline values (these can still be overridden by SAB__* envs below)
cfg["misc"]["host"] = host
cfg["misc"]["port"] = PORT
cfg["folders"]["download_dir"] = incomplete
cfg["folders"]["complete_dir"] = complete
cfg["folders"]["nzb_backup_dir"] = f"{downloads}/nzb-backup"

# Arbitrary overrides via SAB__section__option=value
for k, v in os.environ.items():
    if not k.startswith("SAB__"):
        continue
    parts = k.split("__", 2)
    if len(parts) != 3:
        continue
    _, section, option = parts
    if section not in cfg:
        cfg[section] = {}
    cfg[section][option] = v

# Atomic write
TMP_FILE = f"{cfg_file}.tmp"
with open(TMP_FILE, "w", encoding="utf-8") as f:
    cfg.write(f)
os.replace(TMP_FILE, cfg_file)

# Set HOME to config dir so SAB writes under /config
os.environ["HOME"] = cfg_dir


def drop_privileges(uid: int, gid: int):
    """Drop privileges to specified UID and GID."""
    try:
        os.setgid(gid)
        os.setuid(uid)
        os.umask(0o022)
    except PermissionError as e:
        print(f"WARNING: failed to drop privileges: {e}", file=sys.stderr)


drop_privileges(PUID, PGID)

# Exec SAB from source using the venv interpreter
os.execv(
    "/venv/bin/python",
    ["/venv/bin/python", "/app/SABnzbd.py", "-f", cfg_file, "-s", f"{host}:{PORT}"],
)
