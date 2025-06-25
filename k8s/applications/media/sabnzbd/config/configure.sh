#!/bin/sh
set -eu

CONFIG_FILE="/config/sabnzbd.ini"
TMP_FILE="$(mktemp)"

echo "--- (re)building SABnzbd configuration ---"

cat > "$TMP_FILE" <<EOF
[misc]
api_key        = ${SAB_API_KEY}
host_whitelist = sabnzbd,sabnzbd.media,sabnzbd.media.svc,sabnzbd.media.svc.cluster.local,sabnzbd.pc-tips.se
bandwidth_perc = 100
port = 8080
bandwidth_max = ""
cache_limit = 256M
nzb_key = ${NZB_KEY}
download_dir = /downloads/incomplete
complete_dir = /app/data/downloads

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
ssl_verify = 3
enable = 1
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
