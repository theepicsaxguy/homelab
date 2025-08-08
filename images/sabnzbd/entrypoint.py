import os
import shutil
import sys
config = '/config/sabnzbd.ini'
default = '/defaults/sabnzbd.ini'
if not os.path.exists(config):
    os.makedirs(os.path.dirname(config), exist_ok=True)
    shutil.copy(default, config)
os.execv(sys.executable, [sys.executable, '-m', 'sabnzbd', '--config-file', config])
