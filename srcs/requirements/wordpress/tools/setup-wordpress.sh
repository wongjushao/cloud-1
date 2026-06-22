#!/bin/bash
set -e

echo "Connecting to MariaDB..."
for i in $(seq 1 30); do
    if mysqladmin ping -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent 2>/dev/null; then
        break
    fi
    sleep 1
done

if ! mysqladmin ping -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent 2>/dev/null; then
    echo "ERROR: Could not connect to MariaDB as ${MYSQL_USER}."
    exit 1
fi

echo "MariaDB is up and running!"

if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "Installing WordPress..."

    if [ ! -f "/var/www/html/wp-load.php" ]; then
        wp core download --allow-root
    fi

    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${DB_HOST}" \
        --allow-root

    if ! wp core is-installed --allow-root 2>/dev/null; then
        wp core install \
            --url="https://${DOMAIN_NAME}" \
            --title="${WP_TITLE}" \
            --admin_user="${WP_ADMIN_USER}" \
            --admin_password="${WP_ADMIN_PASSWORD}" \
            --admin_email="${WP_ADMIN_EMAIL}" \
            --skip-email \
            --allow-root

        wp user create \
            "${WP_USER}" \
            "${WP_USER_EMAIL}" \
            --role=editor \
            --user_pass="${WP_USER_PASSWORD}" \
            --allow-root 2>/dev/null || true

        wp option update comment_moderation 0 --allow-root
        wp option update comment_whitelist 1 --allow-root
        wp option update comments_notify 1 --allow-root
        wp option update moderation_notify 1 --allow-root
    fi

    echo "WordPress installation complete!"
else
    echo "WordPress is already installed."
fi

# Apply comment settings on every start (idempotent; wp-config.php already exists after first run)
if wp core is-installed --allow-root 2>/dev/null; then
    wp option update siteurl "https://${DOMAIN_NAME}" --allow-root
    wp option update home "https://${DOMAIN_NAME}" --allow-root
    wp option update comment_moderation 0 --allow-root
    wp option update comment_whitelist 1 --allow-root
fi

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "Starting PHP-FPM..."
exec php-fpm7.4 -F
