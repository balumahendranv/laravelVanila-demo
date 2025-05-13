# Use an official PHP image as a parent image
FROM php:8.2-fpm

# Set the working directory in the container
WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpq-dev \
    libsodium-dev \
    zip \
    unzip \
    nodejs \
    npm \
    supervisor \
    sqlite3 \
    cron

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    mysqli \
    mbstring \
    exif \
    pcntl \
    bcmath \
    intl \
    opcache \
    soap \
    sockets \
    xml \
    zip

# Configure and install GD
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd
    
# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy composer.json and composer.lock to the container
COPY composer*.json ./

# Install Laravel dependencies
RUN composer install --no-scripts --no-autoloader

# Copy the rest of the application files to the container
COPY . .

# Generate optimized autoload files
RUN composer dump-autoload --optimize

# Configure Laravel
RUN php artisan optimize:clear || true
RUN php artisan config:clear || true
RUN php artisan cache:clear || true
RUN php artisan view:clear || true

# Set up Laravel scheduler
RUN echo "* * * * * cd /var/www/html && php artisan schedule:run >> /dev/null 2>&1" | crontab -

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Install NPM dependencies and build assets (if using Laravel Mix/Vite)
RUN npm install && npm run build || true

# Create supervisor configuration directly in the Dockerfile
RUN mkdir -p /etc/supervisor/conf.d/
RUN echo "[supervisord]\n\
nodaemon=true\n\
user=root\n\
logfile=/var/log/supervisor/supervisord.log\n\
pidfile=/var/run/supervisord.pid\n\
\n\
[program:php-fpm]\n\
command=php-fpm\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
autostart=true\n\
autorestart=true\n\
priority=5\n\
\n\
[program:laravel-queue]\n\
process_name=%(program_name)s_%(process_num)02d\n\
command=php /var/www/html/artisan queue:work --sleep=3 --tries=3\n\
autostart=true\n\
autorestart=true\n\
user=www-data\n\
numprocs=2\n\
redirect_stderr=true\n\
stdout_logfile=/var/www/html/storage/logs/queue.log" > /etc/supervisor/conf.d/supervisord.conf

# Increase PHP memory limit and other settings
RUN echo "memory_limit=512M" > /usr/local/etc/php/conf.d/memory-limit.ini \
    && echo "upload_max_filesize=100M" > /usr/local/etc/php/conf.d/upload-limit.ini \
    && echo "post_max_size=100M" >> /usr/local/etc/php/conf.d/upload-limit.ini

# Expose port 9000 (PHP-FPM)
EXPOSE 9000

# Define the command to run the Laravel application with supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]