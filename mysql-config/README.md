# MySQL Configuration Files

This directory contains MySQL configuration files for different environments.

## Files:

- `production.cnf` - Production-optimized settings
- `development.cnf` - Development-friendly settings with verbose logging
- `legacy.cnf` - Settings optimized for legacy PHP applications

## Usage:

Mount the appropriate configuration file in docker-compose.yml:

```yaml
volumes:
  - ./mysql-config/development.cnf:/etc/mysql/conf.d/custom.cnf
```

## Configuration Locations in MySQL Container:

- `/etc/mysql/my.cnf` - Main configuration file
- `/etc/mysql/conf.d/` - Additional configuration files (recommended)
- `/etc/mysql/mysql.conf.d/` - MySQL-specific configurations
