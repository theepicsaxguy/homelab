import os
import shutil
import sys

config_dir = os.environ.get("CONFIG_DIR", "/config/sabnzbd")
config = os.path.join(config_dir, "sabnzbd.ini")
default = "/defaults/sabnzbd.ini"

if not os.path.exists(config):
    os.makedirs(config_dir, exist_ok=True)
    shutil.copy(default, config)

os.chdir("/app/sabnzbd")
os.execv(sys.executable, [sys.executable, "-m", "sabnzbd", "--config-file", config])
