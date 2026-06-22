#!/bin/bash
set -e

chown -R mysql:mysql /var/lib/mysql
chmod -R 755 /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    first_init=1
else
    first_init=0
fi

echo "Ensuring database and users exist..."
mysqld --user=mysql --bootstrap << EOF
USE mysql;
FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

FLUSH PRIVILEGES;
EOF

if [ "$first_init" = "1" ]; then
    echo "MariaDB initialization complete."
else
    echo "MariaDB users and grants verified."
fi

exec mysqld --user=mysql --console
