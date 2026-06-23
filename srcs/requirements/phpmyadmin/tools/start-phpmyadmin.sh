#!/bin/bash
set -e

PMA_HOST="${PMA_HOST:-mariadb}"
PMA_PORT="${PMA_PORT:-3306}"
PMA_ABSOLUTE_URI="${PMA_ABSOLUTE_URI:-}"
BLOWFISH_SECRET="$(openssl rand -hex 16)"

cat > /var/www/html/config.inc.php <<EOF
<?php
declare(strict_types=1);

\$cfg['blowfish_secret'] = '${BLOWFISH_SECRET}';
\$cfg['DefaultLang'] = 'en';
\$cfg['Servers'][1]['host'] = '${PMA_HOST}';
\$cfg['Servers'][1]['port'] = '${PMA_PORT}';
\$cfg['Servers'][1]['auth_type'] = 'cookie';
\$cfg['Servers'][1]['AllowNoPassword'] = false;
EOF

if [ -n "${PMA_ABSOLUTE_URI}" ]; then
    echo "\$cfg['PmaAbsoluteUri'] = '${PMA_ABSOLUTE_URI}';" >> /var/www/html/config.inc.php
fi

chown www-data:www-data /var/www/html/config.inc.php

exec apache2ctl -D FOREGROUND
