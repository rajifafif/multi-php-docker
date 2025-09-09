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
# Backup database (uncompressed)
./dev.sh mysql backup php56_test

# Backup database (compressed)
./dev.sh mysql backup php56_test gz

# Restore from uncompressed backup
./dev.sh mysql restore php56_test backup_file.sql

# Restore from compressed backup
./dev.sh mysql restore php56_test backup_file.sql.gz

# Import existing SQL file
./dev.sh mysql import myapp_db existing_dump.sql

# Import compressed SQL file
./dev.sh mysql import myapp_db large_dump.sql.gz

# Export database
./dev.sh mysql export myapp_db export_file.sql.gz

# List all databases
./dev.sh mysql list

# Check database sizes
./dev.sh mysql size
./dev.sh mysql size specific_database
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
- **Backups**: Generated in current directory as `backup_*` or `export_*`

## Import/Export Features

### Supported Formats
- **Uncompressed**: `.sql` files
- **Compressed**: `.sql.gz` files (automatically detected)

### Import Large Databases
```bash
# Import large compressed database
./dev.sh mysql import production_db large_backup.sql.gz

# Import from external source
wget https://example.com/database.sql.gz
./dev.sh mysql import myapp_db database.sql.gz
```

### Backup Strategies
```bash
# Daily backup (compressed)
./dev.sh mysql backup production_db gz

# Quick backup for development
./dev.sh mysql backup dev_db

# Export specific database with custom name
./dev.sh mysql export myapp_db myapp_$(date +%Y%m%d).sql.gz
```

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
