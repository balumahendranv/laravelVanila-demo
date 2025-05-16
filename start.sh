#!/bin/bash

# Start MySQL service
#echo "Starting MySQL service..."
service mysql start

# Wait for MySQL to start
until mysqladmin ping --silent; do
    sleep 1
done

# Start MySQL and fix root login (optional — use with caution)
#service mysql start

# Optional: fix root auth if needed every time (not ideal for prod)
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'P05tiefs@79';
FLUSH PRIVILEGES;
EOF

# Ensure the Laravel database exists
echo "Creating 'laravel' database if it doesn't exist..."
mysql -u root -p "P05tiefs@79" -e "CREATE DATABASE IF NOT EXISTS laravel;"

# Go to the Laravel project directory
cd /var/www/html/laravelVanila-demo

# Check if .env exists; if not, copy .env.example to .env
if [ ! -f .env ]; then
    cp .env.example .env
fi

# Update .env file to use MySQL
echo "Updating .env file for MySQL connection..."
sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env
sed -i 's/^DB_HOST=.*/DB_HOST=127.0.0.1/' .env
sed -i 's/^DB_PORT=.*/DB_PORT=3306/' .env
sed -i 's/^DB_DATABASE=.*/DB_DATABASE=laravel/' .env
sed -i 's/^DB_USERNAME=.*/DB_USERNAME=root/' .env
sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=P05tiefs@79/' .env

chmod -R 777 /var/www/html/laravelVanila-demo/storage /var/www/html/laravelVanila-demo/bootstrap/cache

# Clear Laravel configuration cache
echo "Clearing Laravel config cache..."
php artisan config:clear
php artisan cache:clear

# Run migrations and seed the database
echo "Running migrations and seeding the database..."
php artisan migrate:fresh --seed

# Start Apache in the foreground
echo "Starting Apache..."
apachectl -D FOREGROUND
