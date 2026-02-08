# ---------- Stage 1: PHP deps (composer) ----------
FROM composer:2 AS vendor
WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader --no-scripts

# ---------- Stage 2: Frontend build (vite) ----------
FROM node:20-alpine AS assets
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY resources ./resources
COPY vite.config.* postcss.config.* tailwind.config.* ./
# Some setups also need these:
COPY public ./public

RUN npm run build

# ---------- Stage 3: Runtime ----------
FROM php:8.3-cli-alpine AS runtime
WORKDIR /app

# System deps + PHP extensions for SQLite
RUN apk add --no-cache \
    bash curl git icu-dev oniguruma-dev sqlite sqlite-dev \
    && docker-php-ext-install intl pdo pdo_sqlite \
    && rm -rf /var/cache/apk/*

# Copy app source
COPY . .

# Copy vendor + built assets from previous stages
COPY --from=vendor /app/vendor ./vendor
COPY --from=assets /app/public/build ./public/build
RUN php artisan package:discover --ansi || true


# Optional hardening: don't ship local env
RUN rm -f .env || true

# App optimizations (safe; relies on env at runtime)
RUN php artisan storage:link || true

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]
