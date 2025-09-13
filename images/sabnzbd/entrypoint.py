"""SABnzbd container entrypoint with per-key declarative overrides and safe path validation."""

import os
import sys
import pathlib
import configparser
from typing import Dict, Set, Tuple

CFG_DIR = os.getenv("SAB_CONFIG_DIR", "/config")
CFG_FILE = os.path.join(CFG_DIR, "sabnzbd.ini")
PUID = int(os.getenv("PUID", "1000"))
PGID = int(os.getenv("PGID", "1000"))

# Ensure config directory exists
pathlib.Path(CFG_DIR).mkdir(parents=True, exist_ok=True)

# Load existing INI if present, preserving option case
cfg = configparser.ConfigParser()
cfg.optionxform = str  # keep keys as written
if os.path.exists(CFG_FILE):
    cfg.read(CFG_FILE, encoding="utf-8")

def set_k(section: str, option: str, value: str) -> None:
    if section not in cfg:
        cfg.add_section(section)
    cfg[section][option] = value

def split_env_list(val: str) -> Tuple[str, ...]:
    # Accept comma or colon separated lists
    parts = [p.strip() for p in val.replace(":", ",").split(",")]
    return tuple(p for p in parts if p)

def collect_env_overrides() -> Dict[Tuple[str, str], str]:
    """
    Collect SAB__section__option and SAB__section__subsection__option envs.
    Nested becomes 'subsection.option' to keep INI flat.
    """
    out: Dict[Tuple[str, str], str] = {}
    for k, v in os.environ.items():
        if not k.startswith("SAB__"):
            continue
        parts = k.split("__")
        if len(parts) == 3:
            _, section, option = parts
            out[(section.lower(), option.lower())] = v
        elif len(parts) == 4:
            _, section, subsection, option = parts
            out[(section.lower(), f"{subsection.lower()}.{option.lower()}")] = v
    return out

def infer_folder_overrides_from_simple_roots() -> Dict[Tuple[str, str], str]:
    """
    Map convenience vars into folder keys if provided.
    No hardcoded defaults. Only map what the caller set.
    """
    out: Dict[Tuple[str, str], str] = {}
    root = os.getenv("SAB_DOWNLOAD_DIR")
    inc = os.getenv("SAB_INCOMPLETE_DIR")
    comp = os.getenv("SAB_COMPLETE_DIR")

    if inc or root:
        out[("folders", "download_dir")] = inc or f"{root.rstrip('/')}/incomplete"
    if comp or root:
        out[("folders", "complete_dir")] = comp or f"{root.rstrip('/')}/complete"
    if root:
        out[("folders", "nzb_backup_dir")] = f"{root.rstrip('/')}/nzb-backup"
    return out

def resolve_safe(path_str: str) -> pathlib.Path:
    """
    Resolve to an absolute canonical path without requiring it to exist.
    Reject non-absolute inputs early.
    """
    p = pathlib.Path(path_str)
    if not p.is_absolute():
        raise ValueError(f"path must be absolute: {path_str}")
    # strict=False so we can validate and then create if needed
    return p.resolve(strict=False)

def build_allowed_roots(overrides: Dict[Tuple[str, str], str]) -> Set[pathlib.Path]:
    """
    Allowed roots are:
    - Explicit SAB_ALLOWED_ROOTS if provided
    - CFG_DIR
    - For any folder override we are about to write, include its top-level root
      and its immediate parent. This derives the policy from caller intent.
    """
    roots: Set[pathlib.Path] = set()
    roots.add(pathlib.Path(CFG_DIR).resolve(strict=False))

    allowed_env = os.getenv("SAB_ALLOWED_ROOTS", "")
    for root_str in split_env_list(allowed_env):
        try:
            roots.add(resolve_safe(root_str))
        except Exception:
            # Ignore malformed allowlist entries silently
            pass

    for (section, option), val in overrides.items():
        if section != "folders":
            continue
        try:
            rp = resolve_safe(val)
            # include the top-level like /downloads, and the parent dir
            parts = rp.parts
            if len(parts) >= 2:
                roots.add(pathlib.Path("/" + parts[1]))
            roots.add(rp.parent)
        except Exception:
            # Validation will catch on actual write
            pass
    return roots

def ensure_within_allowed(rp: pathlib.Path, allowed_roots: Set[pathlib.Path]) -> None:
    """
    Enforce that resolved path is within at least one allowed root.
    """
    for root in allowed_roots:
        try:
            if rp == root or rp.is_relative_to(root):
                return
        except Exception:
            # Defensive: skip broken roots
            continue
    raise PermissionError(f"path outside allowed roots: {rp}")

def mkdir_if_needed(rp: pathlib.Path) -> None:
    try:
        rp.mkdir(parents=True, exist_ok=True)
    except (OSError, PermissionError, FileExistsError) as e:
        print(f"WARNING: could not create path {rp}: {e}", file=sys.stderr)

# Collect overrides
env_overrides = collect_env_overrides()
env_overrides.update(infer_folder_overrides_from_simple_roots())

# Build allowlist dynamically based on what caller asked us to write
allowed_roots = build_allowed_roots(env_overrides)

# Apply overrides with validation for folders.*
for (section, option), value in env_overrides.items():
    # Validate only folder paths; other keys are written as-is
    if section == "folders":
        rp = resolve_safe(value)
        ensure_within_allowed(rp, allowed_roots)
        mkdir_if_needed(rp)
        set_k(section, option, str(rp))
    else:
        set_k(section, option, value)

# Minimal misc defaults only if absent, to avoid SAB inventing globals
host = os.getenv("SAB_HOST", "0.0.0.0")
port = os.getenv("SAB_PORT", "8080")
if "misc" not in cfg:
    cfg.add_section("misc")
if "host" not in cfg["misc"]:
    cfg["misc"]["host"] = host
if "port" not in cfg["misc"]:
    cfg["misc"]["port"] = port

# Persist merged INI
with open(CFG_FILE, "w", encoding="utf-8") as f:
    cfg.write(f)

def drop_privileges(uid: int, gid: int) -> None:
    try:
        os.setgid(gid)
        os.setuid(uid)
        os.umask(0o022)
    except (OSError, PermissionError) as e:
        print(f"WARNING: failed to drop privileges: {e}", file=sys.stderr)

if os.getuid() == 0:
    drop_privileges(PUID, PGID)

# Keep SAB defaults under /config for non-overridden stuff
os.environ["HOME"] = CFG_DIR

# Exec SABnzbd
os.execv(
    "/venv/bin/python",
    ["/venv/bin/python", "/app/SABnzbd.py", "-f", CFG_FILE, "-s", f"{cfg['misc']['host']}:{cfg['misc']['port']}"],
)