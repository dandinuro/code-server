# code-server with PHP 8.3 + Apache 2

A custom Docker image that combines **[code-server](https://github.com/coder/code-server)** with a fully-configured development environment for PHP and Laravel projects. This image includes PHP 8.3, Apache 2, Composer, Laravel, and even Google Chrome for a seamless development experience.

This project is based on the work of the **[LinuxServer.io team](https://github.com/linuxserver/docker-code-server)**, extended with additional tools and configurations for PHP web development.

## Features

- **PHP 8.3** - Latest release of PHP installed.
- **Apache 2** - Web server preconfigured with basic settings for development.
- **Composer** - Dependency manager for PHP included.
- **Laravel** - Automatically installs the latest version of Laravel.
- **Google Chrome** - Installed for use with browse-lite or testing purposes.
- **ServerName Preconfigured** - `localhost` is pre-set as the default `ServerName`.

## About code-server

**code-server** is a version of **[Visual Studio Code](https://code.visualstudio.com/)** you can run on a remote server and access via your browser. It’s lightweight, fast, and perfect for remote or containerized development.

## Quick Start

> The following setup provides a preconfigured **docker-compose.yml** for running the code-server environment.

### Prerequisites

- **Docker** installed and running.
- **Docker Compose** version 3.8 or higher.

---

### YAML Deployment with Data Persistence

Before running the `docker-compose.yml`, kindly update all the lines commented with `#upd-me` and adjust to your requirements. Then remove `#upd-me` before using the file.

```yaml
version: '3.8'
services:
  # MariaDB Service
  mariadb-laravel-service:
    image: ghcr.io/linuxserver/mariadb:latest
    container_name: mariadb-laravel
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London #upd-me
      - MYSQL_ROOT_PASSWORD=my-root-pass #upd-me
      - MYSQL_DATABASE=my-db-name #upd-me
      - MYSQL_USER=my-db-user #upd-me
      - MYSQL_PASSWORD=my-db-pass #upd-me
    volumes:
      - db-data:/var/lib/mysql
    networks:
      - network
    restart: unless-stopped

  # Code-Server Service
  code-server-service:
    image: your-dockerhub-username/code-server:latest
    container_name: code-server-app
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London #upd-me
      - PASSWORD=my-pass-for-code-server-browser-login #upd-me (optional)
      - SUDO_PASSWORD=my-sudo-pass #upd-me (optional)
      - PROXY_DOMAIN=my-subdomain.example.com #upd-me (optional)
      - APP_URL=https://my-subdomain.example.com #upd-me (optional)
      - DEFAULT_WORKSPACE=/home/skipper/.workspace # optional
    volumes:
      - config-data:/home/skipper
      - www-data:/var/www/html
    ports:
      - 8080:80/tcp #upd-me (code-server browser)
      - 80:80/tcp #upd-me (web-server)
    networks:
      - network
    depends_on:
      - mariadb-laravel-service
    restart: unless-stopped

volumes:
  config-data:
    driver: local
    driver_opts:
      type: none
      device: /path/to/config #upd-me
      o: bind
  db-data:
    driver: local
    driver_opts:
      type: none
      device: /path/to/db-data #upd-me
      o: bind
  www-data:
    driver: local
    driver_opts:
      type: none
      device: /path/to/html #upd-me
      o: bind

networks:
  network:
    driver: bridge
```

---

### Post-Installation Steps

1. Switch to the non-root user created automatically:
   ```bash
   su skipper
   ```
2. Create your first Laravel project:
   ```bash
   laravel new my-laravel-project
   ```

#### Reverse Proxy Configuration

If running code-server behind a reverse proxy, apply these changes inside the container:

1. Edit `/etc/apache2/sites-available/000-default.conf` and replace its content with:
   ```apache
   <VirtualHost *:80>
       DocumentRoot /var/www/html/my-laravel-project/public
       ServerName sub-domain.example.com
       <Directory /var/www/html/my-laravel-project/public>
           Options Indexes FollowSymLinks
           AllowOverride All
           Require all granted
       </Directory>
       ErrorLog ${APACHE_LOG_DIR}/error.log
       CustomLog ${APACHE_LOG_DIR}/access.log combined
   </VirtualHost>
   ```

2. Enable `mod_rewrite` for URL rewriting:
   ```bash
   a2enmod rewrite
   ```
3. Restart Apache:
   ```bash
   service apache2 restart
   ```

---

### Example `settings.json` for code-server

You can configure your VS Code experience with the following example `settings.json`:

```json
{
  "workbench.colorTheme": "GitHub Dark",
  "workbench.iconTheme": "vscode-icons",
  "editor.minimap.enabled": false,
  "files.autoSave": "onFocusChange",
  "editor.formatOnSave": true,
  "php.suggest.basic": false,
  "php.validate.enable": false,
  "editor.fontFamily": "'Fira Code'",
  "editor.fontLigatures": true,
  "workbench.editor.enablePreview": false,
  "editor.wordWrap": "on",
  "browse-lite.chromeExecutable": "/usr/bin/google-chrome",
  "browse-lite.startUrl": "https://sub-domain.example.com/"
}
```

---

### License

This repository is licensed under the **Apache 2.0 License**. You can refer to the [LICENSE](LICENSE) file for more details.

---

## Support

If you encounter issues or have questions, feel free to open an issue in the GitHub repository or comment on Docker Hub.

---

## Additional Resources

- [code-server Official Documentation](https://coder.com/docs/code-server/latest)
- [Visual Studio Code Documentation](https://code.visualstudio.com/docs)
- [Laravel Official Documentation](https://laravel.com/docs)
- [Docker Official Documentation](https://docs.docker.com/)
- [Apache License 2.0](https://opensource.org/licenses/Apache-2.0)

Enjoy coding with **code-server** and Laravel! 😊