#!/venv/bin/python
# -*- coding: utf-8 -*-
"""
SABnzbd entrypoint – fully declarative:
- Build sabnzbd.ini from environment on each start.
- Handle sections with mixed flat keys and nested [[subsections]].
- Enforce folder path safety & writability before launch.
- Wait for storage with a real write-probe (configurable, NFS-safe).
- Fail hard on privilege drop failure.
"""

import os
import sys
import time
import tempfile
import secrets
import pathlib
from typing import Dict, Any, Iterable


# -------------------------
# Helpers
# -------------------------

def _clean(v: str) -> str:
    v = v.strip()
    if (len(v) >= 2) and ((v[0] == v[-1] == '"') or (v[0] == v[-1] == "'")):
        return v[1:-1]
    return v

def _abs_path(p: str) -> pathlib.Path:
    q = pathlib.Path(p).resolve(strict=False)
    if not q.is_absolute():
        raise ValueError(f"path must be absolute: {p!r}")
    return q

def _mk_ok(path: pathlib.Path) -> None:
    path.mkdir(parents=True, exist_ok=True)

def _drop_priv(uid: int, gid: int) -> None:
    # Set GID first, then UID. Verify. Fail hard if not effective.
    try:
        os.setgid(gid)
        os.setuid(uid)
        os.umask(0o022)
    except OSError as e:
        sys.stderr.write(f"ERROR: failed to drop privileges to {uid}:{gid} → {e}\n")
        sys.exit(1)
    if os.getuid() != uid or os.getgid() != gid:
        sys.stderr.write(
            f"ERROR: privilege drop verification failed (uid={os.getuid()}, gid={os.getgid()}; "
            f"expected {uid}:{gid})\n"
        )
        sys.exit(1)

def _estr(e: OSError) -> str:
    """Robust OSError formatter even when strerror is None."""
    err = getattr(e, "strerror", None) or str(e)
    eno = getattr(e, "errno", None)
    return f"{err} (errno={eno})" if eno is not None else err

def _write_ini(cfg_file: str, cfg: Dict[str, Dict[str, Any]]) -> None:
    """
    Write INI supporting sections that contain BOTH flat keys and nested [[subsections]].
    - Flat keys are written first.
    - Then each nested dict is emitted as [[subsection]].
    - Deterministic ordering by key for reproducibility.
    """
    with open(cfg_file, "w", encoding="utf-8") as f:
        f.write("__encoding__ = utf-8\n")
        f.write("__version__ = 1\n\n")

        for section in sorted(cfg.keys()):
            values = cfg[section]
            f.write(f"[{section}]\n")

            # Separate flat keys vs nested dicts
            flat_items = {k: v for k, v in values.items() if not isinstance(v, dict)}
            nested_items = {k: v for k, v in values.items() if isinstance(v, dict)}

            # Flat first
            for k in sorted(flat_items.keys()):
                f.write(f"{k} = {flat_items[k]}\n")

            if flat_items and nested_items:
                f.write("\n")

            # Then nested [[subsections]]
            for sub in sorted(nested_items.keys()):
                subvals = nested_items[sub]
                f.write(f"[[{sub}]]\n")
                for k in sorted(subvals.keys()):
                    f.write(f"{k} = {subvals[k]}\n")
                f.write("\n")
            if not nested_items:
                f.write("\n")

def _probe_writable(dirpath: str) -> None:
    """
    Truthful writability check (works on NFSv4): create+write+fsync+unlink a temp file.
    Raises OSError on failure.
    """
    fd = None
    tmp_path = None
    try:
        # mkstemp is unique; add a cryptographically random prefix for defense-in-depth.
        prefix = f".sab_{secrets.token_hex(6)}_"
        fd, tmp_path = tempfile.mkstemp(prefix=prefix, dir=dirpath)
        os.write(fd, b"x")
        os.fsync(fd)
    finally:
        if fd is not None:
            try:
                os.close(fd)
            except OSError:
                pass
        if tmp_path:
            try:
                os.unlink(tmp_path)
            except OSError:
                # best-effort; not fatal for probe
                pass

def _wait_for_paths(paths: Iterable[pathlib.Path],
                    timeout: float,
                    base_interval: float,
                    backoff: float,
                    max_interval: float) -> None:
    """
    Wait for each path to become truly writable using _probe_writable.
    Per-path timeout and exponential backoff.
    """
    for p in paths:
        start = time.monotonic()
        interval = base_interval
        while True:
            try:
                _probe_writable(str(p))
                print(f"READY: storage path usable → {p}", flush=True)
                break
            except OSError as e:
                elapsed = time.monotonic() - start
                if elapsed >= timeout:
                    sys.stderr.write(f"ERROR: storage not ready after {elapsed:.1f}s: {p} → {_estr(e)}\n")
                    sys.exit(1)
                print(f"WAIT: {p} not ready yet ({_estr(e)}); retrying in {interval:.1f}s", flush=True)
                time.sleep(interval)
                interval = min(max_interval, interval * backoff)


# -------------------------
# Core
# -------------------------

CFG_DIR = os.getenv("SAB_CONFIG_DIR", "/config")
CFG_FILE = os.path.join(CFG_DIR, "sabnzbd.ini")

PUID = int(os.getenv("PUID", "1000"))
PGID = int(os.getenv("PGID", "1000"))

HOST = _clean(os.getenv("SAB_HOST", "0.0.0.0"))
PORT = _clean(str(os.getenv("SAB_PORT", "8080")))

# Derive folder defaults (caller can override via SAB__folders__*)
ROOT = _clean(os.getenv("SAB_DOWNLOAD_DIR", "/downloads"))
INCOMPLETE = _clean(os.getenv("SAB_INCOMPLETE_DIR", f"{ROOT.rstrip('/')}/incomplete"))
COMPLETE   = _clean(os.getenv("SAB_COMPLETE_DIR",   f"{ROOT.rstrip('/')}/complete"))
NZB_BACKUP = f"{ROOT.rstrip('/')}/nzb-backup"

# Wait-probe controls (safe defaults)
WAIT_PROBE = os.getenv("SAB_WAIT_PROBE", "1").strip().lower() in {"1", "true", "yes", "on"}
WAIT_TIMEOUT = float(os.getenv("SAB_WAIT_TIMEOUT", "60"))
WAIT_INTERVAL = float(os.getenv("SAB_WAIT_INTERVAL", "1"))
WAIT_BACKOFF = float(os.getenv("SAB_WAIT_BACKOFF", "1.5"))
WAIT_MAX_INTERVAL = float(os.getenv("SAB_WAIT_MAX_INTERVAL", "5"))
WAIT_DIRS_CSV = os.getenv("SAB_WAIT_DIRS", "download_dir,complete_dir,nzb_backup_dir")

# Build config map
config: Dict[str, Dict[str, Any]] = {
    "misc": {
        "host": HOST,
        "port": PORT,
    },
    "folders": {
        "download_dir": INCOMPLETE,
        "complete_dir": COMPLETE,
        "nzb_backup_dir": NZB_BACKUP,
    },
}

# Parse SAB__section__option and SAB__section__subsection__option
for k, v in os.environ.items():
    if not k.startswith("SAB__"):
        continue
    parts = k.split("__", 3)
    val = _clean(v)
    if len(parts) == 3:
        _, section, option = parts
        section = section.lower()
        option = option.lower()
        config.setdefault(section, {})
        config[section][option] = val
    elif len(parts) == 4:
        _, section, subsection, option = parts
        section = section.lower()
        subsection = subsection.lower()
        option = option.lower()
        section_dict = config.setdefault(section, {})
        sub_dict = section_dict.get(subsection)
        if sub_dict is None or not isinstance(sub_dict, dict):
            sub_dict = {}
            section_dict[subsection] = sub_dict
        sub_dict[option] = val

# Prepare folders: resolve & create (idempotent)
folders_section = config.get("folders", {})
key_to_path: Dict[str, pathlib.Path] = {}
for key in ("download_dir", "complete_dir", "nzb_backup_dir", "admin_dir", "log_dir", "cache_dir", "dirscan_dir"):
    val = folders_section.get(key)
    if not val:
        continue
    p = _abs_path(val)
    _mk_ok(p)
    key_to_path[key] = p

# Ensure config dir exists
pathlib.Path(CFG_DIR).mkdir(parents=True, exist_ok=True)

# Write INI deterministically
_write_ini(CFG_FILE, config)

# Drop privileges if root; fail hard on error
if os.getuid() == 0:
    _drop_priv(PUID, PGID)

# Optionally wait for storage using truthful write-probe (NFS-safe)
if WAIT_PROBE:
    wanted_keys = [k.strip() for k in WAIT_DIRS_CSV.split(",") if k.strip()]
    to_wait = [key_to_path[k] for k in wanted_keys if k in key_to_path]
    if to_wait:
        _wait_for_paths(
            to_wait,
            timeout=WAIT_TIMEOUT,
            base_interval=WAIT_INTERVAL,
            backoff=WAIT_BACKOFF,
            max_interval=WAIT_MAX_INTERVAL,
        )

# Make SAB defaults land under /config for anything we didn’t set
os.environ["HOME"] = CFG_DIR

# Exec SAB
os.execv(
    "/venv/bin/python",
    ["/venv/bin/python", "/app/SABnzbd.py", "-f", CFG_FILE, "-s", f"{HOST}:{PORT}"],
)
```0