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
RUN php artisan optimize:clear
RUN php artisan config:clear
RUN php artisan cache:clear
RUN php artisan view:clear

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Install NPM dependencies and build assets (if using Laravel Mix/Vite)
RUN npm install && npm run build

# Copy supervisor configuration
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port 9000 (PHP-FPM)
EXPOSE 9000

# Define the command to run the Laravel application
CMD ["php-fpm"]