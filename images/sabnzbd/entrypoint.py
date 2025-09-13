"""SABnzbd entrypoint enforcing declarative config."""

import os, sys, re, pathlib, stat

CFG_DIR = os.getenv("SAB_CONFIG_DIR", "/config")
CFG_FILE = os.path.join(CFG_DIR, "sabnzbd.ini")
PUID = int(os.getenv("PUID", "1000"))
PGID = int(os.getenv("PGID", "1000"))

ALLOWED_ROOTS = [pathlib.Path("/downloads"), pathlib.Path("/config"), pathlib.Path("/tmp")]

def clean_value(val: str) -> str:
    val = val.strip()
    if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
        val = val[1:-1]
    return val

def resolve_path(val: str) -> str:
    path = pathlib.Path(val).resolve(strict=False)
    if not path.is_absolute():
        raise ValueError(f"Path must be absolute: {val}")
    if not any(path == root or path.is_relative_to(root) for root in ALLOWED_ROOTS):
        raise PermissionError(f"Path {path} outside allowed roots")
    path.mkdir(parents=True, exist_ok=True)
    return str(path)

# Collect env overrides
overrides = {}
root = os.getenv("SAB_DOWNLOAD_DIR")
inc  = os.getenv("SAB_INCOMPLETE_DIR")
comp = os.getenv("SAB_COMPLETE_DIR")
if inc or root:
    overrides[("", "download_dir")] = clean_value(inc or f"{root.rstrip('/')}/incomplete")
if comp or root:
    overrides[("", "complete_dir")] = clean_value(comp or f"{root.rstrip('/')}/complete")
if root:
    overrides[("", "nzb_backup_dir")] = clean_value(f"{root.rstrip('/')}/nzb-backup")

for k, v in os.environ.items():
    if not k.startswith("SAB__"):
        continue
    parts = k.split("__")
    if len(parts) == 3:
        _, section, option = parts
        overrides[(section.lower(), option.lower())] = clean_value(v)
    elif len(parts) == 4:
        _, section, subsection, option = parts
        overrides[(section.lower(), f"{subsection.lower()}.{option.lower()}")] = clean_value(v)

# Prepare folder paths
for (section, option), val in list(overrides.items()):
    if (section == "folders" or section == "") and option in {"download_dir", "complete_dir", "nzb_backup_dir"}:
        overrides[(section, option)] = resolve_path(val)

# Load existing ini text
lines = []
if os.path.exists(CFG_FILE):
    with open(CFG_FILE, "r", encoding="utf-8") as f:
        lines = f.readlines()

def patch_root(lines, key, value):
    out, replaced, in_root = [], False, True
    for line in lines:
        if in_root and re.match(rf"^{re.escape(key)}\s*=", line, re.I):
            if not replaced:
                out.append(f"{key} = {value}\n")
                replaced = True
            # skip existing
            continue
        if line.strip().startswith("["):
            in_root = False
        out.append(line)
    if not replaced:
        insert_idx = 0
        for idx, line in enumerate(out):
            if line.strip().startswith("["):
                insert_idx = idx
                break
        out.insert(insert_idx, f"{key} = {value}\n")
    return out

def patch_section(lines, section, key, value):
    sec_pat   = re.compile(rf"^\[{re.escape(section)}\]\s*$", re.I)
    key_pat   = re.compile(rf"^{re.escape(key)}\s*=", re.I)
    out, in_sec, replaced = [], False, False
    for line in lines:
        if sec_pat.match(line.strip()):
            if in_sec and not replaced:
                out.append(f"{key} = {value}\n")
                replaced = True
            in_sec = True
            out.append(line)
            continue
        if in_sec and line.strip().startswith("[") and line.strip().endswith("]"):
            if not replaced:
                out.append(f"{key} = {value}\n")
                replaced = True
            in_sec = False
        if in_sec and key_pat.match(line.strip()):
            if not replaced:
                out.append(f"{key} = {value}\n")
                replaced = True
            continue
        out.append(line)
    if not replaced:
        out.append(f"\n[{section}]\n{key} = {value}\n")
    return out

# Patch ini lines
for (section, key), value in overrides.items():
    if section == "" :  # root-level keys
        lines = patch_root(lines, key, value)
        lines = patch_section(lines, "folders", key, value)
    else:
        lines = patch_section(lines, section, key, value)

# Write ini
with open(CFG_FILE, "w", encoding="utf-8") as f:
    f.writelines(lines)

# Drop privileges
if os.getuid() == 0:
    os.setgid(PGID)
    os.setuid(PUID)
    os.umask(0o022)

# Verify declared folders are writable after dropping privileges
for (section, key), value in overrides.items():
    if (section == "folders" or section == "") and key in {"download_dir", "complete_dir", "nzb_backup_dir"}:
        if not os.access(value, os.W_OK):
            sys.stderr.write(f"ERROR: SABnzbd cannot write to {value}\n")
            sys.exit(1)

# Set HOME so SAB uses /config
os.environ["HOME"] = CFG_DIR
os.execv("/venv/bin/python", ["/venv/bin/python", "/app/SABnzbd.py", "-f", CFG_FILE, "-s", f"0.0.0.0:{os.getenv('SAB_PORT','8080')}"])