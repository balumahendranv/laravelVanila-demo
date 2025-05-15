FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install packages
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

# Install PHP 8.3
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

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --ignore-platform-req=ext-pdo_sqlite

# Set working directory and clone app
WORKDIR /var/www/html
RUN git clone https://github.com/balumahendranv/laravelVanila-demo.git

WORKDIR /var/www/html/laravelVanila-demo

# Install Laravel dependencies and generate app key
RUN cp .env.example .env && composer install --no-interaction --prefer-dist && php artisan key:generate

# Set permissions
RUN chmod -R 777 storage bootstrap/cache

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Replace default Apache vhost config with project version
RUN cp apache-vhost.conf /etc/apache2/sites-available/000-default.conf

# Create MySQL socket directory
RUN mkdir -p /var/run/mysqld && chown mysql:mysql /var/run/mysqld

# Set entrypoint
RUN chmod +x start.sh
CMD ["/var/www/html/laravelVanila-demo/start.sh"]

# Expose ports
EXPOSE 80 3306
