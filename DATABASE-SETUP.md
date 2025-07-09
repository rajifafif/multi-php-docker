# Database Configuration Guide

This setup provides dual MySQL environments to handle both modern and legacy PHP applications.

## Database Overview

### MySQL 8.4.3 (Native macOS)
- **Host**: localhost
- **Port**: 3306 (default)
- **Use Case**: Modern PHP applications (7.4+)
- **Authentication**: caching_sha2_password (default)
- **Management**: Native MySQL tools, phpMyAdmin

### MySQL 8.0 (Docker Container)
- **Host**: localhost (external) / mysql80 (internal)
- **Port**: 3307 (external)
- **Use Case**: Legacy PHP applications (especially PHP 5.6)
- **Authentication**: mysql_native_password (compatible)
- **Management**: Docker commands, phpMyAdmin

## Connection Examples

### PHP 5.6 with MySQL 8.0 (Docker)

```php
// MySQLi
$mysqli = new mysqli('mysql80', 'legacy_user', 'legacy_password', 'php56_test');

// PDO
$pdo = new PDO('mysql:host=mysql80;dbname=php56_test', 'legacy_user', 'legacy_password');

// External connection (from outside Docker)
$mysqli = new mysqli('localhost:3307', 'legacy_user', 'legacy_password', 'php56_test');
```

### Modern PHP with MySQL 8.4 (Native)

```php
// From Docker container
$mysqli = new mysqli('host.docker.internal', 'root', 'your_password', 'your_database');

// External connection
$mysqli = new mysqli('localhost', 'root', 'your_password', 'your_database');
```

## User Accounts

### MySQL 8.0 (Docker) Users:
- **root**: `password` (full access)
- **legacy_user**: `legacy_password` (full access, mysql_native_password)
- **app_user**: `app_password` (limited to test_db)
- **developer**: `dev_password` (general development user)

### MySQL 8.4 (Native) Users:
- **root**: [your chosen password] (full access)

## Database Management Commands

### Start Environment
```bash
./dev.sh up
```

### Database Connections
```bash
# Connect to MySQL 8.0 (Docker)
./dev.sh mysql connect mysql80

# Connect to MySQL 8.4 (Native)
./dev.sh mysql connect native
```

### Check Database Status
```bash
./dev.sh mysql status
```

### Test PHP Connections
```bash
# Test PHP 5.6 connection
./dev.sh test-connection php56

# Test modern PHP connection
./dev.sh test-connection php84
```

### Backup & Restore
```bash
# Backup database
./dev.sh mysql backup php56_test

# Restore database
./dev.sh mysql restore php56_test backup_file.sql
```

## phpMyAdmin Access

Access phpMyAdmin at: http://localhost:6969

The interface will show both database servers:
- **MySQL 8.0 (Docker)**: Use `mysql80` as server, `legacy_user`/`legacy_password`
- **MySQL 8.4 (Native)**: Use `host.docker.internal` as server, `root`/[your password]

## Troubleshooting

### PHP 5.6 Connection Issues

1. **Authentication Plugin Error**: Use `legacy_user` instead of `root`
2. **Host Not Found**: Ensure you're using `mysql80` hostname from within Docker
3. **Port Issues**: Use port 3307 for external connections

### Modern PHP Connection Issues

1. **Host Not Found**: Use `host.docker.internal` from Docker containers
2. **Authentication**: Update password in connection strings
3. **SSL Issues**: Add `sslmode=DISABLED` to connection string if needed

## File Locations

- **Docker Logs**: `./logs/mysql80/`
- **Initialization Scripts**: `./mysql80-init/`
- **Connection Test**: `./test-mysql-connection.php`
- **Data Volume**: Docker managed volume `mysql80_data`

## Security Notes

- Change default passwords in production
- Use environment variables for sensitive data
- Limit user privileges based on application needs
- Enable SSL for production environments
- Regular backup procedures recommended

## Performance Tuning

The MySQL 8.0 container includes optimized settings:
- InnoDB buffer pool: 256MB
- Max connections: 200
- Slow query log enabled
- General log enabled for debugging

For production, adjust these settings in the docker-compose.yml file based on your server resources.
