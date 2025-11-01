#!/usr/bin/env bash
set -euo pipefail

if [ ! -d /var/www/storage ]; then
  mkdir -p /var/www/storage
fi

if [ "$(ls -A /var/www/storage 2>/dev/null | wc -l)" -eq 0 ]; then
  cp -a /var/www/storage-init/. /var/www/storage
fi

if [ ! -L /var/www/public/storage ] && [ -d /var/www/storage/app/public ]; then
  ln -s /var/www/storage/app/public /var/www/public/storage
fi

exec "$@"
