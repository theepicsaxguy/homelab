import os
import shutil
import sys

config = '/config/sabnzbd.ini'
default = '/defaults/sabnzbd.ini'

# If PVC is empty, seed with current SAB defaults
if not os.path.exists(config):
    os.makedirs(os.path.dirname(config), exist_ok=True)
    shutil.copy(default, config)

# Change to SABnzbd directory and run SABnzbd
os.chdir('/app/sabnzbd')
os.execv(sys.executable, [sys.executable, '-m', 'sabnzbd', '--config-file', config])
