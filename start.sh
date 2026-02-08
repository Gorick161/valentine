#!/usr/bin/env bash
set -euo pipefail
PORT="${PORT:-10000}"

php artisan config:clear || true
php artisan cache:clear || true
php artisan route:clear || true
php artisan view:clear || true

if [ "${DB_CONNECTION:-}" = "sqlite" ]; then
  DB_PATH="${DB_DATABASE:-/tmp/database.sqlite}"
  mkdir -p "$(dirname "$DB_PATH")"
  touch "$DB_PATH"
fi

php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true
php artisan migrate --force || true

exec php -S 0.0.0.0:"$PORT" -t public

