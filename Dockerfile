# Stage 1: Build PHP-FPM image with system dependencies and PHP extensions
FROM php:7.4-fpm AS php-builder

# Arguments defined in docker-compose.yml
ARG user=robinsonjose7777
ARG uid=10002

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Stage 2: Build MySQL image
FROM mysql:8.0 AS mysql-builder

# Set environment variables for MySQL
ENV MYSQL_DATABASE=${DB_DATABASE} \
    MYSQL_ROOT_PASSWORD=${DB_PASSWORD} \
    MYSQL_PASSWORD=${DB_PASSWORD} \
    MYSQL_USER=${DB_USERNAME} \
    SERVICE_TAGS=dev \
    SERVICE_NAME=mysql

# Copy initialization scripts into the container
COPY ./docker-compose/mysql /docker-entrypoint-initdb.d

# Stage 3: Create the final image with Nginx/PHP-FPM and MySQL
FROM nginx:stable-alpine

# Copy the built PHP-FPM image and set the working directory
COPY --from=php-builder /var/www /var/www

# Copy your application code into the container
COPY . /var/www

# Copy nginx configuration files
COPY ./docker-compose/nginx /etc/nginx/conf.d/

# Expose the ports
EXPOSE 80

# Set the user for running the container
USER $user

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
