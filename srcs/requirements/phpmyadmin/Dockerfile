FROM debian:bullseye

ENV PHPMYADMIN_VERSION=5.2.1

RUN apt-get update && \
    apt-get install -y \
    apache2 \
    libapache2-mod-php7.4 \
    php7.4-mysql \
    php7.4-mbstring \
    php7.4-zip \
    php7.4-gd \
    php7.4-curl \
    php7.4-xml \
    wget \
    openssl && \
    rm -rf /var/lib/apt/lists/*

RUN wget -q "https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz" \
        -O /tmp/phpmyadmin.tar.gz && \
    tar -xzf /tmp/phpmyadmin.tar.gz -C /var/www/html --strip-components=1 && \
    rm /tmp/phpmyadmin.tar.gz && \
    chown -R www-data:www-data /var/www/html && \
    a2enmod rewrite

COPY tools/start-phpmyadmin.sh /usr/local/bin/start-phpmyadmin.sh
RUN chmod +x /usr/local/bin/start-phpmyadmin.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/start-phpmyadmin.sh"]
