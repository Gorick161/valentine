#!/usr/bin/env bash
set -euo pipefail
PORT="${PORT:-10000}"

mkdir -p storage/framework/{cache,sessions,views} bootstrap/cache
chmod -R 775 storage bootstrap/cache || true

if [ "${DB_CONNECTION:-}" = "sqlite" ]; then
  DB_PATH="${DB_DATABASE:-/tmp/database.sqlite}"
  mkdir -p "$(dirname "$DB_PATH")"
  touch "$DB_PATH"
fi

php artisan migrate --force || true
exec php -S 0.0.0.0:"$PORT" -t public
