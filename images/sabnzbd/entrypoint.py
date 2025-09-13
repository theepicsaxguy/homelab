"""SABnzbd entrypoint with declarative env overrides."""

import os
import sys
import pathlib
import re

CFG_DIR = os.getenv("SAB_CONFIG_DIR", "/config")
CFG_FILE = os.path.join(CFG_DIR, "sabnzbd.ini")
PUID = int(os.getenv("PUID", "1000"))
PGID = int(os.getenv("PGID", "1000"))

# Ensure config directory exists
pathlib.Path(CFG_DIR).mkdir(parents=True, exist_ok=True)

# Helper: strip wrapping quotes
def clean_val(v: str) -> str:
    v = v.strip()
    if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
        return v[1:-1]
    return v

# Collect env overrides
env_overrides: dict[tuple[str, str], str] = {}

root = os.getenv("SAB_DOWNLOAD_DIR")
inc = os.getenv("SAB_INCOMPLETE_DIR")
comp = os.getenv("SAB_COMPLETE_DIR")

if inc or root:
    env_overrides[("folders", "download_dir")] = clean_val(inc or f"{root.rstrip('/')}/incomplete")
if comp or root:
    env_overrides[("folders", "complete_dir")] = clean_val(comp or f"{root.rstrip('/')}/complete")
if root:
    env_overrides[("folders", "nzb_backup_dir")] = clean_val(f"{root.rstrip('/')}/nzb-backup")

for k, v in os.environ.items():
    if not k.startswith("SAB__"):
        continue
    parts = k.split("__")
    if len(parts) == 3:
        _, section, option = parts
        env_overrides[(section.lower(), option.lower())] = clean_val(v)
    elif len(parts) == 4:
        _, section, subsection, option = parts
        env_overrides[(section.lower(), f"{subsection.lower()}.{option.lower()}")] = clean_val(v)

# Allowed roots for folder paths
ALLOWED_ROOTS = [pathlib.Path("/downloads"), pathlib.Path("/config"), pathlib.Path("/tmp")]

def resolve_and_validate(p: str) -> str:
    rp = pathlib.Path(p).resolve(strict=False)
    if not rp.is_absolute():
        raise ValueError(f"Path must be absolute: {p}")
    if not any(rp == root or rp.is_relative_to(root) for root in ALLOWED_ROOTS):
        raise PermissionError(f"Path outside allowed roots: {rp}")
    rp.mkdir(parents=True, exist_ok=True)
    return str(rp)

# Apply validation to folder overrides
for (section, option), val in list(env_overrides.items()):
    if section == "folders":
        env_overrides[(section, option)] = resolve_and_validate(val)

# If ini exists, load it as lines, else start with empty
lines: list[str] = []
if os.path.exists(CFG_FILE):
    with open(CFG_FILE, encoding="utf-8") as f:
        lines = f.readlines()

# Function to patch a section.option line
def patch_lines(lines: list[str], section: str, option: str, value: str) -> list[str]:
    section_pat = re.compile(rf"^\[{re.escape(section)}\]\s*$", re.I)
    option_pat = re.compile(rf"^{re.escape(option)}\s*=", re.I)

    out = []
    in_section = False
    replaced = False
    for line in lines:
        if line.strip().startswith("[") and line.strip().endswith("]"):
            if in_section and not replaced:
                out.append(f"{option} = {value}\n")
                replaced = True
            in_section = bool(section_pat.match(line.strip()))
            out.append(line)
            continue
        if in_section and option_pat.match(line.strip()):
            if not replaced:
                out.append(f"{option} = {value}\n")
                replaced = True
            continue
        out.append(line)
    if not replaced:
        # append section if missing
        if not any(section_pat.match(l.strip()) for l in lines):
            out.append(f"\n[{section}]\n")
        out.append(f"{option} = {value}\n")
    return out

# Apply all overrides
patched = lines
for (section, option), value in env_overrides.items():
    patched = patch_lines(patched, section, option, value)

# Write back
with open(CFG_FILE, "w", encoding="utf-8") as f:
    f.writelines(patched)

# Drop privileges if running as root
def drop_privileges(uid: int, gid: int):
    try:
        os.setgid(gid)
        os.setuid(uid)
        os.umask(0o022)
    except OSError as e:
        print(f"WARNING: failed to drop privileges: {e}", file=sys.stderr)

if os.getuid() == 0:
    drop_privileges(PUID, PGID)

# Set HOME so SAB defaults resolve under /config
os.environ["HOME"] = CFG_DIR

# Exec SABnzbd
os.execv(
    "/venv/bin/python",
    ["/venv/bin/python", "/app/SABnzbd.py", "-f", CFG_FILE, "-s", f"0.0.0.0:{os.getenv('SAB_PORT','8080')}"],
)