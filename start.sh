#!/usr/bin/env bash
set -euo pipefail

# Render sets PORT; fallback for local docker runs
PORT="${PORT:-10000}"

# Ensure SQLite file exists if configured
if [ "${DB_CONNECTION:-}" = "sqlite" ]; then
  DB_PATH="${DB_DATABASE:-/tmp/database.sqlite}"
  mkdir -p "$(dirname "$DB_PATH")"
  touch "$DB_PATH"
fi

# Cache configs/routes/views (requires APP_KEY etc. to be present)
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

# Migrations only if you actually have tables/migrations (won't fail the deploy)
php artisan migrate --force || true

exec php -S 0.0.0.0:"$PORT" -t public
