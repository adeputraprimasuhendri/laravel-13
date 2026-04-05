FROM php:8.4-fpm

# Arguments for user and uid (defaulting to laravel:1000)
ARG user=laravel
ARG uid=1000

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    libsqlite3-dev \
    zip \
    unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure intl \
    && docker-php-ext-install pdo_mysql mysqli mbstring exif pcntl bcmath gd zip intl pdo_sqlite

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Ensure /var/www is owned by the user
RUN chown -R $user:$user /var/www

# Copy application files
COPY --chown=$user:$user . /var/www

# Change current user to laravel
USER $user

# Install dependencies (ignoring scripts as we'll run them if needed later)
RUN composer install --no-interaction --no-dev --optimize-autoloader

# Expose port 9000
EXPOSE 9000

# Use artisan serve as the command (matching original intent)
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=9000"]
