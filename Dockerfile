# Base image
FROM ubuntu:latest

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Update and install system packages
RUN apt-get update && apt-get install -y \
    apache2 \
    mysql-server \
    git \
    unzip \
    curl \
    vim \
    software-properties-common \
    lsb-release \
    gnupg2 \
    ca-certificates

# Add PHP 8.3 repository and install PHP + needed extensions
RUN add-apt-repository ppa:ondrej/php -y && apt-get update && apt-get install -y \
    php8.3 \
    php8.3-cli \
    php8.3-common \
    php8.3-mysql \
    php8.3-xml \
    php8.3-mbstring \
    php8.3-curl \
    php8.3-zip \
    php8.3-bcmath \
    php8.3-intl \
    php8.3-sqlite3 \
    libapache2-mod-php8.3

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --ignore-platform-req=ext-pdo_sqlite

root@instance-20250514-112525docker:~/laravel# cat  Dockerfile 
# Base image
FROM ubuntu:latest

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Update and install system packages
RUN apt-get update && apt-get install -y \
    apache2 \
    mysql-server \
    git \
    unzip \
    curl \
    vim \
    software-properties-common \
    lsb-release \
    gnupg2 \
    ca-certificates

# Add PHP 8.3 repository and install PHP + needed extensions
RUN add-apt-repository ppa:ondrej/php -y && apt-get update && apt-get install -y \
    php8.3 \
    php8.3-cli \
    php8.3-common \
    php8.3-mysql \
    php8.3-xml \
    php8.3-mbstring \
    php8.3-curl \
    php8.3-zip \
    php8.3-bcmath \
    php8.3-intl \
    php8.3-sqlite3 \
    libapache2-mod-php8.3

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --ignore-platform-req=ext-pdo_sqlite

# Set working directory
WORKDIR /var/www/html

# Clone Laravel project
RUN git clone https://github.com/balumahendranv/laravelVanila-demo.git

WORKDIR /var/www/html/laravelVanila-demo

# Copy env file and install dependencies
RUN cp .env.example .env \
    && composer install --no-interaction --prefer-dist \
    && php artisan key:generate

# Set permissions for Laravel
RUN chmod -R 777 storage bootstrap/cache

# Expose Apache and MySQL ports
EXPOSE 80 3306

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Configure Apache site
COPY apache-vhost.conf /etc/apache2/sites-available/000-default.conf

# Create MySQL socket directory
RUN mkdir -p /var/run/mysqld && chown mysql:mysql /var/run/mysqld

# Copy custom startup script into the container
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set entrypoint
CMD ["/start.sh"
