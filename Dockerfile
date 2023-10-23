# Set the base image to Ubuntu 22.04 (Jammy Jellyfish)
FROM ubuntu:jammy

# Change from /bin/sh to /bin/bash
SHELL ["/bin/bash", "-c"]

# Set maintainer label in lowercase
LABEL maintainer="Dan Dinu <dan.dinu.ro@gmail.com>"

# Environment settings
ARG DEBIAN_FRONTEND=noninteractive
ENV HTTP_PORT=80
ENV HTTPS_PORT=443
ENV LARAVEL_PORT=8000
ENV CODE_SERVER_PORT=8080
ENV HOME="/home/skipper"

# Update and install required packages in one step to reduce layer size
RUN apt-get update && apt-get install -y \
    software-properties-common \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    unzip \
    git \
    jq \
    libatomic1 \
    nano \
    net-tools \
    netcat \
    curl \
    wget \
    mc \
    mlocate \
    php8.1 \
    php8.1-zip \
    php8.1-xml \
    php8.1-mbstring \
    php8.1-curl \
    php8.1-mysql \
    php8.1-gd \
    mysql-client \
    apache2 \
    supervisor \
    imagemagick

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set the working directory to /var/www/html/
WORKDIR /var/www/html/

# Create a default HTML file
RUN echo "<!DOCTYPE html><html><head><style>html, body {height: 100%; margin: 0; padding: 0;} body {display: flex; align-items: center; justify-content: center; height: 100vh;} </style></head><body><h1>Hello, Docker Apache!</h1></body></html>" > /var/www/html/index.html

# Install Code Server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Create a non-root user for running Laravel
RUN useradd -m -s /bin/bash skipper

# add writing rights over directory /home/skipper and /var/www/html for skipper user
RUN chown -R skipper:skipper /home/skipper /var/www/html

# Add the `www-data` user to the `skipper` group
RUN usermod -a -G skipper www-data

# Set the ownership of /var/www/html to the `www-data` group
RUN chown -R :www-data /var/www/html

# Set the permissions to allow the `www-data` group to write
RUN chmod -R 775 /var/www/html

# Install Laravel globally for the non-root user
USER skipper
RUN composer global require laravel/installer

# Add Laravel executable to the user's PATH and set the alias, then source .bashrc
RUN echo 'export PATH="$PATH:/home/skipper/.config/composer/vendor/bin"' >> /home/skipper/.bashrc && \
    echo 'alias laravel="/home/skipper/.config/composer/vendor/bin/laravel"' >> /home/skipper/.bashrc && \
    source /home/skipper/.bashrc

# Switch back to the root user to configure supervisord
USER root

# install FiraCode font
Run add-apt-repository universe && \
    apt-get update && apt-get install -y fonts-firacode
    
# Create a supervisord configuration file
RUN cd / && \
    apt-get update && apt-get install -y supervisor && \
    echo -e "[supervisord]\nnodaemon=true\n\n[program:apache]\ncommand=/usr/sbin/apache2ctl -D FOREGROUND\n\n[program:code-server]\ncommand=code-server --bind-addr 0.0.0.0:8080 /home/skipper" > /etc/supervisor/conf.d/supervisord.conf

# Define localhost as ServerName in Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Expose ports 80, 443, and 8080 (publish them when running the container)
EXPOSE $HTTP_PORT
EXPOSE $HTTPS_PORT
EXPOSE $LARAVEL_PORT
EXPOSE $CODE_SERVER_PORT

# Start supervisord to manage Apache and Code Server
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
