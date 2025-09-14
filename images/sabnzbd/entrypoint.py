"""SABnzbd entrypoint that enforces declarative config from environment."""

import os
import sys
import pathlib

cfg_dir = os.getenv("SAB_CONFIG_DIR", "/config")
cfg_file = os.path.join(cfg_dir, "sabnzbd.ini")

downloads = os.getenv("SAB_DOWNLOAD_DIR", "/downloads")
incomplete = os.getenv("SAB_INCOMPLETE_DIR", f"{downloads}/incomplete")
complete = os.getenv("SAB_COMPLETE_DIR", f"{downloads}/complete")
host = os.getenv("SAB_HOST", "0.0.0.0")
port = str(os.getenv("SAB_PORT", "8080"))

PUID = int(os.getenv("PUID", "1000"))
PGID = int(os.getenv("PGID", "1000"))

# Ensure required dirs exist
for p in (cfg_dir, downloads, incomplete, complete, f"{downloads}/nzb-backup"):
    pathlib.Path(p).mkdir(parents=True, exist_ok=True)

# Build config dict from envs
config: dict[str, dict] = {}

config["misc"] = {
    "host": host,
    "port": port,
}

config["folders"] = {
    "download_dir": incomplete,
    "complete_dir": complete,
    "nzb_backup_dir": f"{downloads}/nzb-backup",
}

# Walk env overrides
for k, v in os.environ.items():
    if not k.startswith("SAB__"):
        continue
    parts = k.split("__")
    if len(parts) == 3:
        _, section, option = parts
        config.setdefault(section.lower(), {})[option.lower()] = v
    elif len(parts) == 4:
        _, section, subsection, option = parts
        section_dict = config.setdefault(section.lower(), {})
        subsection_dict = section_dict.setdefault(subsection.lower(), {})
        subsection_dict[option.lower()] = v

# Write sabnzbd.ini from scratch
with open(cfg_file, "w", encoding="utf-8") as f:
    f.write("__encoding__ = utf-8\n")
    f.write("__version__ = 1\n\n")
    for section, values in config.items():
        f.write(f"[{section}]\n")
        if all(isinstance(v, dict) for v in values.values()):
            for subsection, subvalues in values.items():
                f.write(f"[[{subsection}]]\n")
                for key, val in subvalues.items():
                    f.write(f"{key} = {val}\n")
                f.write("\n")
        else:
            for key, val in values.items():
                if not isinstance(val, dict):
                    f.write(f"{key} = {val}\n")
            f.write("\n")

# Drop privileges
def drop_privileges(uid, gid):
    try:
        os.setgid(gid)
        os.setuid(uid)
        os.umask(0o022)
    except PermissionError as e:
        print(f"WARNING: could not drop privileges: {e}", file=sys.stderr)

if os.getuid() == 0:
    drop_privileges(PUID, PGID)

os.environ["HOME"] = cfg_dir

os.execv(
    "/venv/bin/python",
    ["/venv/bin/python", "/app/SABnzbd.py", "-f", cfg_file, "-s", f"{host}:{port}"],
)