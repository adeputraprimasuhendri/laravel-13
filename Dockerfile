FROM php:8.4-fpm

# Args
ARG user=laravel
ARG uid=1000

# Install system deps
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

# ---- FIXED USER CREATION (idempotent + UID-safe) ----
RUN if ! id -u ${user} >/dev/null 2>&1; then \
        if getent passwd ${uid} >/dev/null; then \
            usermod -l ${user} $(getent passwd ${uid} | cut -d: -f1); \
            usermod -d /home/${user} -m ${user}; \
        else \
            useradd -G www-data,root -u ${uid} -d /home/${user} -m ${user}; \
        fi; \
    fi

# Composer home
RUN mkdir -p /home/${user}/.composer \
    && chown -R ${user}:${user} /home/${user}

# Copy only composer files first (cache optimization)
COPY composer.json composer.lock* ./

RUN chown -R ${user}:${user} /var/www

USER ${user}

# Install deps first (better caching)
RUN composer install --no-interaction --no-dev --optimize-autoloader

# Copy rest of app
COPY --chown=${user}:${user} . .

EXPOSE 9000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=9000"]