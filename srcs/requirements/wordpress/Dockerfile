FROM debian:bullseye

# Install PHP-FPM and required extensions
RUN apt-get update && \
    apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-mbstring \
    php7.4-soap \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-zip \
    curl \
    mariadb-client && \
    rm -rf /var/lib/apt/lists/*

# Download and install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Configure PHP-FPM to listen on all interfaces for container-to-container access
RUN sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 0.0.0.0:9000/g' /etc/php/7.4/fpm/pool.d/www.conf && \
    mkdir -p /run/php

# Copy setup script
COPY tools/setup-wordpress.sh /usr/local/bin/setup-wordpress.sh
RUN chmod +x /usr/local/bin/setup-wordpress.sh

# Create WordPress directory
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

WORKDIR /var/www/html

# Expose PHP-FPM port
EXPOSE 9000

# Run setup script
ENTRYPOINT ["/usr/local/bin/setup-wordpress.sh"]
