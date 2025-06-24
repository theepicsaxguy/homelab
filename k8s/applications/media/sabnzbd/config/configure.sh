#!/bin/sh
set -eu

CONFIG_FILE="/config/sabnzbd.ini"
TMP_FILE="$(mktemp)"

echo "--- (re)building SABnzbd configuration ---"

cat > "$TMP_FILE" <<EOF
[misc]
api_key        = ${SAB_API_KEY}
host_whitelist = sabnzbd,sabnzbd.media,sabnzbd.media.svc,sabnzbd.media.svc.cluster.local,sabnzbd.pc-tips.se

[servers]
[[news.newshosting.com]]
name = news.newshosting.com
displayname = news.newshosting.com
host     = ${USENET_HOST}
port     = 563
timeout  = 60
username = ${USENET_USERNAME}
password = ${USENET_PASSWORD}
connections = 30
ssl = 1
ssl_verify = 2
ssl_ciphers = ""
enable = 1
required = 0
optional = 0
retention = 0
expire_date = ""
quota = ""
usage_at_start = 0
priority = 0
notes = ""
EOF

if [ ! -f "$CONFIG_FILE" ] || ! cmp -s "$TMP_FILE" "$CONFIG_FILE"; then
  echo "--- Writing updated sabnzbd.ini ---"
  mv "$TMP_FILE" "$CONFIG_FILE"
else
  echo "--- No changes detected, keeping existing sabnzbd.ini ---"
  rm "$TMP_FILE"
fi

echo "--- Final sabnzbd.ini: ---"
cat "$CONFIG_FILE"
