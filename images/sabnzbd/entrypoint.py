"""SABnzbd container entrypoint with deterministic config generation."""

import os
import sys
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

# In-memory representation: dict[str, dict[str, str]] + nested dicts
config: dict[str, dict[str, dict[str, str] | str]] = {}

# Seed defaults
config.setdefault("misc", {})
config["misc"]["host"] = host
config["misc"]["port"] = PORT

config.setdefault("folders", {})
config["folders"]["download_dir"] = incomplete
config["folders"]["complete_dir"] = complete
config["folders"]["nzb_backup_dir"] = f"{downloads}/nzb-backup"

# Parse env overrides
for k, v in os.environ.items():
    if not k.startswith("SAB__"):
        continue
    parts = k.split("__", 3)
    if len(parts) == 3:
        _, section, option = parts
        section = section.lower()
        option = option.lower()
        config.setdefault(section, {})
        config[section][option] = v
    elif len(parts) == 4:
        _, section, subsection, option = parts
        section = section.lower()
        subsection = subsection.lower()
        option = option.lower()
        section_dict = config.setdefault(section, {})
        subsection_dict = section_dict.setdefault(subsection, {})
        if not isinstance(subsection_dict, dict):
            subsection_dict = {}
            section_dict[subsection] = subsection_dict
        subsection_dict[option] = v

# Write ini deterministically
TMP_FILE = f"{cfg_file}.tmp"
with open(TMP_FILE, "w", encoding="utf-8") as f:
    for section, values in config.items():
        f.write(f"[{section}]\n")
        if all(isinstance(v, dict) for v in values.values()):
            # Nested subsections
            for subsection, subvalues in values.items():
                f.write(f"[[{subsection}]]\n")
                for key, val in subvalues.items():
                    f.write(f"{key} = {val}\n")
                f.write("\n")
        else:
            # Flat section
            for key, val in values.items():
                if isinstance(val, dict):
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