#!/bin/bash

# PHP Docker Development Environment Manager
# Usage: ./dev.sh [command] [options]

set -e

COMPOSE_FILE="docker-compose.yml"
PROJECT_NAME="php-docker"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Commands
case "$1" in
    "up")
        log "Starting PHP Docker environment..."
        docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME up -d
        log "Environment started successfully!"
        log "Services available:"
        echo "  - Nginx: http://localhost"
        echo "  - phpMyAdmin: http://localhost:6969"
        echo "  - MySQL 8.0 (Legacy): localhost:3307"
        echo "  - MySQL 8.4 (Native): localhost:3306"
        echo "  - PHP 5.6 FPM: localhost:9056"
        echo "  - PHP 7.4 FPM: localhost:9074"
        echo "  - PHP 8.1 FPM: localhost:9081"
        echo "  - PHP 8.2 FPM: localhost:9082"
        echo "  - PHP 8.4 FPM: localhost:9084"
        echo ""
        log "Database Connection Info:"
        echo "  MySQL 8.4 (Native macOS):"
        echo "    Host: localhost / Port: 3306"
        echo "    User: root / Password: [your native password]"
        echo ""
        echo "  MySQL 8.0 (Docker - PHP 5.6 Compatible):"
        echo "    Host: localhost / Port: 3307"
        echo "    Root: root / password"
        echo "    Legacy User: legacy_user / legacy_password"
        echo "    App User: app_user / app_password"
        ;;
    "down")
        log "Stopping PHP Docker environment..."
        docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME down
        log "Environment stopped successfully!"
        ;;
    "restart")
        log "Restarting PHP Docker environment..."
        docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME restart
        log "Environment restarted successfully!"
        ;;
    "rebuild")
        log "Rebuilding PHP Docker environment..."
        docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME down
        docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME build --no-cache
        docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME up -d
        log "Environment rebuilt successfully!"
        ;;
    "logs")
        SERVICE=${2:-""}
        if [ -z "$SERVICE" ]; then
            docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME logs -f
        else
            docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME logs -f $SERVICE
        fi
        ;;
    "exec")
        SERVICE=${2:-"php84"}
        COMMAND=${3:-"bash"}
        log "Executing command in $SERVICE container..."
        docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE $COMMAND
        ;;
    "shell")
        SERVICE=${2:-"php84"}
        log "Opening shell in $SERVICE container..."
        docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE bash
        ;;
    "status")
        log "PHP Docker environment status:"
        docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME ps
        ;;
    "clean")
        warn "This will remove all containers, images, and volumes!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME down -v --rmi all
            docker system prune -f
            log "Environment cleaned successfully!"
        else
            log "Clean operation cancelled."
        fi
        ;;
    "xdebug")
        ACTION=${2:-"status"}
        SERVICE=${3:-"php84"}
        case "$ACTION" in
            "enable")
                log "Enabling XDebug for $SERVICE..."
                docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE bash -c "echo 'xdebug.mode=debug' >> /usr/local/etc/php/conf.d/99-custom.ini"
                docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME restart $SERVICE
                ;;
            "disable")
                log "Disabling XDebug for $SERVICE..."
                docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE bash -c "sed -i '/xdebug.mode=debug/d' /usr/local/etc/php/conf.d/99-custom.ini"
                docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME restart $SERVICE
                ;;
            "status")
                log "XDebug status for $SERVICE:"
                docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE php -m | grep -i xdebug || echo "XDebug not loaded"
                ;;
        esac
        ;;
    "composer")
        SERVICE=${2:-"php84"}
        shift 2
        log "Running Composer in $SERVICE container..."
        docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE composer "$@"
        ;;
    "npm")
        SERVICE=${2:-"php84"}
        shift 2
        log "Running npm in $SERVICE container..."
        docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE npm "$@"
        ;;
    "mysql")
        ACTION=${2:-"status"}
        case "$ACTION" in
            "connect"|"cli")
                DATABASE=${3:-"mysql80"}
                if [ "$DATABASE" = "mysql80" ] || [ "$DATABASE" = "legacy" ]; then
                    log "Connecting to MySQL 8.0 (Legacy/Docker)..."
                    docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysql -u root -ppassword
                elif [ "$DATABASE" = "native" ] || [ "$DATABASE" = "mysql84" ]; then
                    log "Connecting to MySQL 8.4 (Native macOS)..."
                    mysql -u root -p
                else
                    error "Unknown database: $DATABASE. Use 'mysql80', 'legacy', 'native', or 'mysql84'"
                fi
                ;;
            "status")
                log "Database Status:"
                echo ""
                echo "MySQL 8.0 (Docker):"
                docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysqladmin -u root -ppassword status || echo "  MySQL 8.0 container not running"
                echo ""
                echo "MySQL 8.4 (Native):"
                mysqladmin -u root -p status 2>/dev/null || echo "  MySQL 8.4 native not running or not accessible"
                ;;
            "logs")
                log "MySQL 8.0 logs:"
                docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME logs mysql80
                ;;
            "backup")
                DATABASE=${3:-"test_db"}
                BACKUP_FILE="backup_${DATABASE}_$(date +%Y%m%d_%H%M%S).sql"
                log "Creating backup of database '$DATABASE' to '$BACKUP_FILE'..."
                docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysqldump -u root -ppassword $DATABASE > $BACKUP_FILE
                log "Backup created: $BACKUP_FILE"
                ;;
            "restore")
                DATABASE=${3:-"test_db"}
                BACKUP_FILE=${4}
                if [ -z "$BACKUP_FILE" ]; then
                    error "Please specify backup file: ./dev.sh mysql restore <database> <backup_file.sql>"
                    exit 1
                fi
                if [ ! -f "$BACKUP_FILE" ]; then
                    error "Backup file not found: $BACKUP_FILE"
                    exit 1
                fi
                log "Restoring database '$DATABASE' from '$BACKUP_FILE'..."
                docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec -T mysql80 mysql -u root -ppassword $DATABASE < $BACKUP_FILE
                log "Database restored successfully"
                ;;
            *)
                error "Unknown mysql action: $ACTION"
                echo "Available actions: connect, status, logs, backup, restore"
                ;;
        esac
        ;;
    "db")
        # Alias for mysql command
        shift
        $0 mysql "$@"
        ;;
    "test-connection")
        SERVICE=${2:-"php56"}
        log "Testing database connection for $SERVICE..."
        
        case "$SERVICE" in
            "php56")
                log "Testing PHP 5.6 connection to MySQL 8.0 (Legacy)..."
                docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE php -r "
                \$conn = new mysqli('mysql80', 'legacy_user', 'legacy_password', 'php56_test');
                if (\$conn->connect_error) {
                    echo 'Connection failed: ' . \$conn->connect_error . PHP_EOL;
                    exit(1);
                } else {
                    echo 'Connected successfully to MySQL 8.0!' . PHP_EOL;
                    echo 'Server version: ' . \$conn->server_info . PHP_EOL;
                    \$result = \$conn->query('SELECT COUNT(*) as count FROM users');
                    if (\$result) {
                        \$row = \$result->fetch_assoc();
                        echo 'Test table has ' . \$row['count'] . ' records' . PHP_EOL;
                    }
                    \$conn->close();
                }
                "
                ;;
            "php74"|"php81"|"php82"|"php84")
                log "Testing $SERVICE connection to MySQL 8.4 (Native)..."
                docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE php -r "
                \$conn = new mysqli('host.docker.internal', 'root', 'YOUR_NATIVE_PASSWORD', 'mysql');
                if (\$conn->connect_error) {
                    echo 'Connection failed: ' . \$conn->connect_error . PHP_EOL;
                    echo 'Note: Update YOUR_NATIVE_PASSWORD with your actual MySQL 8.4 password' . PHP_EOL;
                    exit(1);
                } else {
                    echo 'Connected successfully to MySQL 8.4!' . PHP_EOL;
                    echo 'Server version: ' . \$conn->server_info . PHP_EOL;
                    \$conn->close();
                }
                "
                ;;
            *)
                error "Unknown PHP service: $SERVICE"
                echo "Available services: php56, php74, php81, php82, php84"
                ;;
        esac
        ;;
    "help"|*)
        echo -e "${BLUE}PHP Docker Development Environment Manager${NC}"
        echo ""
        echo "Usage: ./dev.sh [command] [options]"
        echo ""
        echo "Commands:"
        echo "  up          Start the environment"
        echo "  down        Stop the environment"
        echo "  restart     Restart the environment"
        echo "  rebuild     Rebuild and restart the environment"
        echo "  logs        Show logs (optionally for specific service)"
        echo "  exec        Execute command in container"
        echo "  shell       Open shell in container"
        echo "  status      Show container status"
        echo "  clean       Remove all containers, images, and volumes"
        echo "  xdebug      Manage XDebug (enable|disable|status) [service]"
        echo "  composer    Run Composer commands [service] [args...]"
        echo "  npm         Run npm commands [service] [args...]"
        echo "  mysql       Database management (connect|status|logs|backup|restore)"
        echo "  db          Alias for mysql command"
        echo "  test-connection  Test database connection for PHP service"
        echo "  help        Show this help message"
        echo ""
        echo "Database Commands:"
        echo "  ./dev.sh mysql connect [mysql80|native]    # Connect to database"
        echo "  ./dev.sh mysql status                      # Show database status"
        echo "  ./dev.sh mysql logs                        # Show MySQL 8.0 logs"
        echo "  ./dev.sh mysql backup [database]           # Backup database"
        echo "  ./dev.sh mysql restore [database] [file]   # Restore database"
        echo "  ./dev.sh test-connection [php_service]     # Test PHP-MySQL connection"
        echo ""
        echo "Examples:"
        echo "  ./dev.sh up"
        echo "  ./dev.sh logs nginx"
        echo "  ./dev.sh shell php84"
        echo "  ./dev.sh xdebug enable php84"
        echo "  ./dev.sh composer php84 install"
        echo "  ./dev.sh mysql connect mysql80"
        echo "  ./dev.sh test-connection php56"
        ;;
esac
