#!/bin/sh
set -e

mkdir -p /app/config

cat <<EOF >/app/config/auth.yaml
bot_account:
  server: "${BOT_SERVER}"
  access_token: "${BOT_TOKEN}"
EOF

exec python -m hype
