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
RUN apt update && \
    apt install -y \
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
    supervisor \
    imagemagick

# Set locale to avoid issues with add-apt-repository and non-UTF-8 locales
ENV LC_ALL=C.UTF-8

# Install php8.3 and Apache2
RUN add-apt-repository ppa:ondrej/php && \
    apt update && \
    apt install -y \
    php8.3 \
    php8.3-zip \
    php8.3-xml \
    php8.3-mbstring \
    php8.3-curl \
    php8.3-mysql \
    php8.3-gd \
    libapache2-mod-php8.3 \
    mysql-client \
    apache2

# Install chrome browser
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt -f install ./google-chrome-stable_current_amd64.deb -y && \
    rm google-chrome-stable_current_amd64.deb

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
RUN composer global require "laravel/installer"

# Add Laravel executable to the user's PATH and set the alias
RUN echo 'export PATH="$PATH:$HOME/.config/composer/vendor/bin"' >> ~/.bashrc

# Set up Laravel environment by sourcing .bashrc
RUN echo 'source ~/.bashrc' >> ~/.bash_profile

# Start a new shell session to apply changes
SHELL ["/bin/bash", "-c"]
    
# Switch back to the root user to configure supervisord
USER root

# install FiraCode font
RUN add-apt-repository universe && \
    apt update && apt install -y fonts-firacode
    
# Create a supervisord configuration file
RUN cd / && \
    apt update && apt install -y supervisor && \
    echo -e "[supervisord]\nnodaemon=true\n\n[program:apache]\ncommand=/usr/sbin/apache2ctl -D FOREGROUND\n\n[program:code-server]\ncommand=code-server --bind-addr 0.0.0.0:8080 /home/skipper" > /etc/supervisor/conf.d/supervisord.conf

# Check for updates and upgrade everything
RUN apt update && \
    apt upgrade -y

# Define localhost as ServerName in Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Expose ports 80, 443, and 8080 (publish them when running the container)
EXPOSE $HTTP_PORT
EXPOSE $HTTPS_PORT
EXPOSE $LARAVEL_PORT
EXPOSE $CODE_SERVER_PORT

# Start supervisord to manage Apache and Code Server
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]