"""SABnzbd container entrypoint with deterministic config generation."""

import os
import sys
import configparser
import pathlib

# === Core, overridable defaults ===
cfg_dir = os.getenv("SAB_CONFIG_DIR", "/config")
cfg_file = os.path.join(cfg_dir, "sabnzbd.ini")
overwrite = os.getenv("SAB_OVERWRITE_CONFIG", "true").lower() == "true"

downloads = os.getenv("SAB_DOWNLOAD_DIR", "/downloads")
incomplete = os.getenv("SAB_INCOMPLETE_DIR", f"{downloads}/incomplete")
complete = os.getenv("SAB_COMPLETE_DIR", f"{downloads}/complete")
host = os.getenv("SAB_HOST", "0.0.0.0")
PORT = str(os.getenv("SAB_PORT", "8080"))

PUID = int(os.getenv("PUID", "1000"))
PGID = int(os.getenv("PGID", "1000"))

# Ensure dirs exist before config write
for p in (cfg_dir, downloads, incomplete, complete):
    pathlib.Path(p).mkdir(parents=True, exist_ok=True)


class _CaseConfigParser(configparser.ConfigParser):
    """Preserve case but allow writing nested [[subsections]]."""

    def optionxform(self, optionstr: str) -> str:  # type: ignore[override]
        return optionstr


cfg = _CaseConfigParser(allow_no_value=True, delimiters=("=",))
if not overwrite and os.path.exists(cfg_file):
    cfg.read(cfg_file)

# Seed required sections
for section in ("misc", "folders", "servers"):
    if section not in cfg:
        cfg[section] = {}

cfg["misc"]["host"] = host
cfg["misc"]["port"] = PORT
cfg["folders"]["download_dir"] = incomplete
cfg["folders"]["complete_dir"] = complete
cfg["folders"]["nzb_backup_dir"] = f"{downloads}/nzb-backup"

# Helper: ensure nested section
def ensure_nested(section: str, subsection: str):
    secname = f"{section}:{subsection}"
    if secname not in cfg:
        cfg.add_section(secname)
        # Mark it as a subsection
        cfg.set(secname, None, f"[[{subsection}]]")


# Apply overrides from env
for k, v in os.environ.items():
    if not k.startswith("SAB__"):
        continue
    parts = k.split("__", 3)
    if len(parts) == 3:
        _, section, option = parts
        section = section.lower()
        option = option.lower()
        if section not in cfg:
            cfg[section] = {}
        cfg[section][option] = v
    elif len(parts) == 4:
        _, section, subsection, option = parts
        section = section.lower()
        subsection = subsection.lower()
        option = option.lower()
        ensure_nested(section, subsection)
        secname = f"{section}:{subsection}"
        cfg[secname][option] = v

# Atomic write
TMP_FILE = f"{cfg_file}.tmp"
with open(TMP_FILE, "w", encoding="utf-8") as f:
    # Custom writer to support [[subsection]] lines
    for section in cfg.sections():
        base, _, subsection = section.partition(":")
        if subsection:
            # Write parent section if not already written
            if not any(s == base for s in cfg.sections()):
                f.write(f"[{base}]\n")
            f.write(f"[[{subsection}]]\n")
        else:
            f.write(f"[{section}]\n")
        for key, val in cfg.items(section):
            if key is None and val and val.startswith("[["):
                # subsection marker, skip writing again
                continue
            f.write(f"{key} = {val}\n")
        f.write("\n")
os.replace(TMP_FILE, cfg_file)

# Drop privileges if running as root
def drop_privileges(uid: int, gid: int):
    try:
        os.setgid(gid)
        os.setuid(uid)
        os.umask(0o022)
    except PermissionError as e:
        print(f"WARNING: failed to drop privileges: {e}", file=sys.stderr)


if os.getuid() == 0:
    drop_privileges(PUID, PGID)

# Set HOME to config dir
os.environ["HOME"] = cfg_dir

# Exec SABnzbd
os.execv(
    "/venv/bin/python",
    ["/venv/bin/python", "/app/SABnzbd.py", "-f", cfg_file, "-s", f"{host}:{PORT}"],
)