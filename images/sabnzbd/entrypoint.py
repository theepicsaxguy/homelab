"""SABnzbd container entrypoint with per-key declarative overrides from environment."""

import os
import sys
import pathlib
import configparser

# Locations and identity
CFG_DIR = os.getenv("SAB_CONFIG_DIR", "/config")
CFG_FILE = os.path.join(CFG_DIR, "sabnzbd.ini")
PUID = int(os.getenv("PUID", "1000"))
PGID = int(os.getenv("PGID", "1000"))

# Ensure config directory exists
pathlib.Path(CFG_DIR).mkdir(parents=True, exist_ok=True)

# Load existing INI if present
cfg = configparser.ConfigParser()
if os.path.exists(CFG_FILE):
    # Preserve case of options exactly as written
    cfg.optionxform = str  # type: ignore[attr-defined]
    cfg.read(CFG_FILE, encoding="utf-8")
else:
    cfg.optionxform = str  # type: ignore[attr-defined]

# Helper to set a key in a section
def set_k(section: str, option: str, value: str) -> None:
    sec = cfg[section] if section in cfg else cfg.create_section(section)
    sec[option] = value

# 1) Seed minimal sane defaults only if not already present
# We do not hardcode everything. We only touch keys when needed to avoid SAB injecting legacy globals.
host = os.getenv("SAB_HOST", "0.0.0.0")
port = os.getenv("SAB_PORT", "8080")

if "misc" not in cfg:
    cfg.add_section("misc")
if "host" not in cfg["misc"]:
    cfg["misc"]["host"] = host
if "port" not in cfg["misc"]:
    cfg["misc"]["port"] = port

# For folders, we will only enforce keys if caller provided envs or the simple root vars.
# If you set SAB__folders__download_dir etc, those exact keys will be written.
# If you set SAB_DOWNLOAD_DIR, SAB_INCOMPLETE_DIR, SAB_COMPLETE_DIR, we map them as convenience.
root_downloads = os.getenv("SAB_DOWNLOAD_DIR")  # optional
incomplete_dir = os.getenv("SAB_INCOMPLETE_DIR")
complete_dir = os.getenv("SAB_COMPLETE_DIR")

if any([root_downloads, incomplete_dir, complete_dir]):
    # Ensure [folders] exists before overlay
    if "folders" not in cfg:
        cfg.add_section("folders")
    if incomplete_dir:
        cfg["folders"]["download_dir"] = incomplete_dir
    elif root_downloads:
        cfg["folders"]["download_dir"] = f"{root_downloads.rstrip('/')}/incomplete"
    if complete_dir:
        cfg["folders"]["complete_dir"] = complete_dir
    elif root_downloads:
        cfg["folders"]["complete_dir"] = f"{root_downloads.rstrip('/')}/complete"
    # Always set nzb_backup_dir if we have a root to avoid SAB inventing defaults
    if root_downloads and "nzb_backup_dir" not in cfg["folders"]:
        cfg["folders"]["nzb_backup_dir"] = f"{root_downloads.rstrip('/')}/nzb-backup"

# 2) Overlay arbitrary SAB__section__option and SAB__section__subsection__option envs
# Format:
#   SAB__<section>__<option>=value
#   SAB__<section>__<subsection>__<option>=value   -> written as [[subsection]] flattened with dot: subsection.option
for k, v in os.environ.items():
    if not k.startswith("SAB__"):
        continue
    parts = k.split("__")
    if len(parts) == 3:
        _, section, option = parts
        section = section.lower()
        option = option.lower()
        set_k(section, option, v)
    elif len(parts) == 4:
        _, section, subsection, option = parts
        section = section.lower()
        subsection = subsection.lower()
        option = option.lower()
        # configparser has no native nested sections. We store as "subsection.option"
        set_k(section, f"{subsection}.{option}", v)

# 3) Ensure any folder paths we are enforcing actually exist to satisfy SAB checks at launch
# We only create directories for keys we explicitly wrote or that already exist in the INI.
folders = []
if "folders" in cfg:
    for key in ("download_dir", "complete_dir", "nzb_backup_dir", "admin_dir", "log_dir", "cache_dir", "dirscan_dir"):
        val = cfg["folders"].get(key)
        if val and val.startswith("/"):
            folders.append(val)

for p in folders:
    try:
        pathlib.Path(p).mkdir(parents=True, exist_ok=True)
    except Exception as e:
        print(f"WARNING: could not create path {p}: {e}", file=sys.stderr)

# 4) Persist merged INI
with open(CFG_FILE, "w", encoding="utf-8") as f:
    cfg.write(f)

# 5) Drop privileges if running as root
def drop_privileges(uid: int, gid: int) -> None:
    try:
        os.setgid(gid)
        os.setuid(uid)
        os.umask(0o022)
    except PermissionError as e:
        print(f"WARNING: failed to drop privileges: {e}", file=sys.stderr)

if os.getuid() == 0:
    drop_privileges(PUID, PGID)

# 6) Set HOME so SAB defaults resolve under /config when it creates any missing files
os.environ["HOME"] = CFG_DIR

# 7) Exec SABnzbd with the INI we just wrote
os.execv(
    "/venv/bin/python",
    ["/venv/bin/python", "/app/SABnzbd.py", "-f", CFG_FILE, "-s", f"{cfg['misc']['host']}:{cfg['misc']['port']}"],
)