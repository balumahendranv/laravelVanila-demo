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
    zip \
    unzip \
    nodejs \
    npm

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

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

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Install NPM dependencies and build assets (if using Laravel Mix)
RUN npm install && npm run build

# Expose port 9000 (PHP-FPM)
EXPOSE 9000

# Define the command to run the Laravel application
CMD ["php-fpm"]