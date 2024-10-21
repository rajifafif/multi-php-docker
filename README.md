
# PHP Multi Version Docker

Easy setup for multi version php using nginx, multiple php-fpm (5.6, 7.4, 8.1), and extra phpMyAdmin to open local mysql.


## Installation
```bash
  cd this-project-folder
  docker-compose up --build -d
```
in this example we link our local ~/www as /var/www, so access to http://localhost will automatically go to ~/www/html.

## Set PHP Version
to set php version for each directory or usage with virtual host, see the nginx.conf

### Set PHP Version for specific directory
Add new location setup section inside
```
server {
    listen 80;
    server_name localhost;

    root /var/www/html;  # Matches the mounted directory
    index index.php index.html index.htm;

    # Your New Location Setup....

    location ~ /\.ht {
        deny all;  # Deny access to .htaccess files
    }
}
```
Location Setup :
```code
location /hisv2 {
        alias /var/www/html/hisv2;  # Serve hisv2 directory
        try_files $uri $uri/ /hisv2/index.php?$query_string;  # Route requests to index.php if not found
        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_pass php56:9000;  # Use PHP 5.6 for this directory
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $request_filename;  # Ensure the correct script is processed
        }
    }
```

### Set Virtual Host
Just add new server listener, change server_name, root, and fastcgi_pass to your desired version.
```
server {
    listen 80;
    server_name something74.local;

    root /var/www/something74;  # Matches the mounted directory
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$query_string;  # Adjust as necessary
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass php74:9000;  # Change to the PHP service you want to use
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;  # Deny access to .htaccess files
    }
}
```


## Usage

After any change in docker-compose.yml, recreate the container

```bash
  docker compose down && docker compose up --build -d
```

make sure the port 80 is not used by another service, if there are conflict, you will see the container are not running, use docker gui for easy check.

You can access the phpMyAdmin at http://localhost:6969


## NOTES
Turn out, all app in run with this container has its own localhost or / 127.0.0.1. So to be able to access the PC localhost, we have to point at host.docker.internal.
