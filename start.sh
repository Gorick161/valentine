#!/usr/bin/env bash
set -euo pipefail
PORT="${PORT:-10000}"

if [ "${DB_CONNECTION:-}" = "sqlite" ]; then
  DB_PATH="${DB_DATABASE:-/tmp/database.sqlite}"
  mkdir -p "$(dirname "$DB_PATH")"
  touch "$DB_PATH"
fi

# Don't cache during debugging; just ensure app can boot.
php artisan migrate --force || true

exec php -S 0.0.0.0:"$PORT" -t public
