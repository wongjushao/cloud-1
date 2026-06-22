FROM debian:bullseye

# Install NGINX and OpenSSL
RUN apt-get update && \
    apt-get install -y \
    nginx \
    openssl \
    gettext-base && \
    rm -rf /var/lib/apt/lists/*

# Copy NGINX configuration template
COPY conf/nginx.conf /etc/nginx/nginx.conf.template

# Copy SSL generation script
COPY tools/generate-ssl.sh /usr/local/bin/generate-ssl.sh
RUN chmod +x /usr/local/bin/generate-ssl.sh

# Create SSL directory
RUN mkdir -p /etc/nginx/ssl

# Expose HTTP and HTTPS ports
EXPOSE 80 443

# Generate SSL certificates and start NGINX
ENTRYPOINT ["/usr/local/bin/generate-ssl.sh"]
