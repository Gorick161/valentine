#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-10000}"

# 1) Ensure SQLite exists early
if [ "${DB_CONNECTION:-}" = "sqlite" ]; then
  DB_PATH="${DB_DATABASE:-/tmp/database.sqlite}"
  mkdir -p "$(dirname "$DB_PATH")"
  touch "$DB_PATH"
fi

# 2) Clear caches (now DB file exists)
php artisan config:clear || true
php artisan cache:clear || true
php artisan route:clear || true

# View commands only if view path exists
if [ -d "resources/views" ]; then
  php artisan view:clear || true
fi

# 3) Rebuild caches (optional but fine)
php artisan config:cache || true
php artisan route:cache || true
if [ -d "resources/views" ]; then
  php artisan view:cache || true
fi

# 4) Migrate (optional)
php artisan migrate --force || true

exec php -S 0.0.0.0:"$PORT" -t public
