FROM php:8.4-fpm

ARG user=laravel
ARG uid=1000

# System deps
RUN apt-get update && apt-get install -y \
    git curl zip unzip \
    libpng-dev libonig-dev libxml2-dev libzip-dev libicu-dev libsqlite3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# PHP extensions
RUN docker-php-ext-configure intl \
    && docker-php-ext-install \
        pdo_mysql mysqli mbstring exif pcntl bcmath gd zip intl pdo_sqlite

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# User (safe)
RUN if ! id -u ${user} >/dev/null 2>&1; then \
        if getent passwd ${uid} >/dev/null; then \
            usermod -l ${user} $(getent passwd ${uid} | cut -d: -f1); \
            usermod -d /home/${user} -m ${user}; \
        else \
            useradd -G www-data,root -u ${uid} -d /home/${user} -m ${user}; \
        fi; \
    fi

# Composer env (IMPORTANT)
ENV COMPOSER_MEMORY_LIMIT=-1
ENV COMPOSER_ALLOW_SUPERUSER=1

# Prepare dirs
RUN mkdir -p /home/${user}/.composer \
    && chown -R ${user}:${user} /home/${user} /var/www

# Copy only composer files
COPY composer.json composer.lock* ./

USER ${user}

# ---- FIX: disable scripts during build ----
RUN composer install \
    --no-interaction \
    --no-dev \
    --optimize-autoloader \
    --no-scripts

# Copy full app
COPY --chown=${user}:${user} . .

EXPOSE 9000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=9000"]