#!/bin/bash

# Regenerate nginx.conf on every start; recreate the cert when the domain changes
envsubst '${DOMAIN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

needs_cert=false
if [ ! -f "/etc/nginx/ssl/nginx.crt" ]; then
    needs_cert=true
elif ! openssl x509 -in /etc/nginx/ssl/nginx.crt -noout -subject 2>/dev/null | grep -q "CN=${DOMAIN_NAME}"; then
    echo "Domain changed to ${DOMAIN_NAME}, regenerating SSL certificate..."
    rm -f /etc/nginx/ssl/nginx.crt /etc/nginx/ssl/nginx.key
    needs_cert=true
fi

if [ "$needs_cert" = true ]; then
    echo "Generating self-signed SSL certificate for ${DOMAIN_NAME}..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=${DOMAIN_NAME}"
    echo "SSL certificate generated!"
fi

# Start NGINX in the foreground
echo "Starting NGINX..."
exec nginx -g "daemon off;"
