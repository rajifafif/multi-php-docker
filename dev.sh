#!/bin/bash

# PHP Docker Development Environment Manager
# Usage: ./dev.sh [command] [options]

set -e

COMPOSE_FILE="docker-compose.yml"
PROJECT_NAME="php-docker"

# Docker Compose command (check for new vs old syntax)
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

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

# MySQL Configuration Management
set_mysql_config() {
    local config_type="$1"
    local config_file=""
    
    case "$config_type" in
        "development"|"dev")
            config_file="./mysql-config/development.cnf"
            ;;
        "production"|"prod")
            config_file="./mysql-config/production.cnf"
            ;;
        "legacy")
            config_file="./mysql-config/legacy.cnf"
            ;;
        "default")
            config_file="./mysql80.cnf"
            ;;
        *)
            error "Invalid MySQL config type: $config_type"
            echo "Available types: development, production, legacy, default"
            exit 1
            ;;
    esac
    
    if [[ ! -f "$config_file" ]]; then
        error "Configuration file not found: $config_file"
        exit 1
    fi
    
    # Update the docker-compose.yml to use the selected config
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|./mysql.*\.cnf:/etc/mysql/conf.d/custom.cnf|${config_file}:/etc/mysql/conf.d/custom.cnf|g" docker-compose.yml
    else
        # Linux
        sed -i "s|./mysql.*\.cnf:/etc/mysql/conf.d/custom.cnf|${config_file}:/etc/mysql/conf.d/custom.cnf|g" docker-compose.yml
    fi
    
    log "MySQL configuration set to: $config_type ($config_file)"
    warn "Restart MySQL container to apply changes: ./dev.sh restart mysql80"
}

show_mysql_config() {
    local current_config=$(grep "mysql.*\.cnf:/etc/mysql/conf.d/custom.cnf" docker-compose.yml | head -1 | sed 's/.*- \(.*\):/etc\/mysql.*/\1/')
    
    echo -e "${BLUE}Current MySQL Configuration:${NC}"
    echo "  File: $current_config"
    echo ""
    echo -e "${BLUE}Available Configurations:${NC}"
    echo "  development  - Development settings with extensive logging"
    echo "  production   - Production-optimized settings"
    echo "  legacy       - Legacy PHP compatibility settings"
    echo "  default      - Basic MySQL 8.0 settings"
    echo ""
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./dev.sh mysql-config [type]"
    echo "  ./dev.sh mysql-config show"
}

# Commands
case "$1" in
    "up")
        log "Starting PHP Docker environment..."
        $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME up -d
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
        $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME down
        log "Environment stopped successfully!"
        ;;
    "restart")
        log "Restarting PHP Docker environment..."
        $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME restart
        log "Environment restarted successfully!"
        ;;
    "rebuild")
        log "Rebuilding PHP Docker environment..."
        $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME down
        $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME build --no-cache
        $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME up -d
        log "Environment rebuilt successfully!"
        ;;
    "logs")
        SERVICE=${2:-""}
        if [ -z "$SERVICE" ]; then
            $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME logs -f
        else
            $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME logs -f $SERVICE
        fi
        ;;
    "exec")
        SERVICE=${2:-"php84"}
        COMMAND=${3:-"bash"}
        log "Executing command in $SERVICE container..."
        $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE $COMMAND
        ;;
    "shell")
        SERVICE=${2:-"php84"}
        log "Opening shell in $SERVICE container..."
        $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE bash
        ;;
    "status")
        log "PHP Docker environment status:"
        $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME ps
        ;;
    "clean")
        warn "This will remove all containers, images, and volumes!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME down -v --rmi all
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
                $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE bash -c "echo 'xdebug.mode=debug' >> /usr/local/etc/php/conf.d/99-custom.ini"
                $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME restart $SERVICE
                ;;
            "disable")
                log "Disabling XDebug for $SERVICE..."
                $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE bash -c "sed -i '/xdebug.mode=debug/d' /usr/local/etc/php/conf.d/99-custom.ini"
                $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME restart $SERVICE
                ;;
            "status")
                log "XDebug status for $SERVICE:"
                $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE php -m | grep -i xdebug || echo "XDebug not loaded"
                ;;
        esac
        ;;
    "composer")
        SERVICE=${2:-"php84"}
        shift 2
        log "Running Composer in $SERVICE container..."
        $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE composer "$@"
        ;;
    "npm")
        SERVICE=${2:-"php84"}
        shift 2
        log "Running npm in $SERVICE container..."
        $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE npm "$@"
        ;;
    "mysql")
        ACTION=${2:-"status"}
        case "$ACTION" in
            "connect"|"cli")
                DATABASE=${3:-"mysql80"}
                if [ "$DATABASE" = "mysql80" ] || [ "$DATABASE" = "legacy" ]; then
                    log "Connecting to MySQL 8.0 (Legacy/Docker)..."
                    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysql -u root -ppassword
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
                $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysqladmin -u root -ppassword status || echo "  MySQL 8.0 container not running"
                echo ""
                echo "MySQL 8.4 (Native):"
                mysqladmin -u root -p status 2>/dev/null || echo "  MySQL 8.4 native not running or not accessible"
                ;;
            "logs")
                log "MySQL 8.0 logs:"
                $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME logs mysql80
                ;;
            "backup")
                DATABASE=${3:-"test_db"}
                FORMAT=${4:-"sql"}
                if [ "$FORMAT" = "gz" ] || [ "$FORMAT" = "compressed" ]; then
                    BACKUP_FILE="backup_${DATABASE}_$(date +%Y%m%d_%H%M%S).sql.gz"
                    log "Creating compressed backup of database '$DATABASE' to '$BACKUP_FILE'..."
                    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysqldump -u root -ppassword --single-transaction --routines --triggers $DATABASE | gzip > $BACKUP_FILE
                else
                    BACKUP_FILE="backup_${DATABASE}_$(date +%Y%m%d_%H%M%S).sql"
                    log "Creating backup of database '$DATABASE' to '$BACKUP_FILE'..."
                    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysqldump -u root -ppassword --single-transaction --routines --triggers $DATABASE > $BACKUP_FILE
                fi
                log "Backup created: $BACKUP_FILE"
                ;;
            "restore")
                DATABASE=${3:-"test_db"}
                BACKUP_FILE=${4}
                if [ -z "$BACKUP_FILE" ]; then
                    error "Please specify backup file: ./dev.sh mysql restore <database> <backup_file.sql[.gz]>"
                    exit 1
                fi
                if [ ! -f "$BACKUP_FILE" ]; then
                    error "Backup file not found: $BACKUP_FILE"
                    exit 1
                fi
                
                # Check if file is compressed
                if [[ "$BACKUP_FILE" == *.gz ]]; then
                    log "Restoring database '$DATABASE' from compressed file '$BACKUP_FILE'..."
                    # Create database if it doesn't exist
                    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysql -u root -ppassword -e "CREATE DATABASE IF NOT EXISTS \`$DATABASE\`;"
                    # Import compressed file
                    gunzip -c "$BACKUP_FILE" | $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec -T mysql80 mysql -u root -ppassword $DATABASE
                else
                    log "Restoring database '$DATABASE' from '$BACKUP_FILE'..."
                    # Create database if it doesn't exist
                    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysql -u root -ppassword -e "CREATE DATABASE IF NOT EXISTS \`$DATABASE\`;"
                    # Import regular SQL file
                    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec -T mysql80 mysql -u root -ppassword $DATABASE < $BACKUP_FILE
                fi
                log "Database restored successfully"
                ;;
            "import")
                DATABASE=${3}
                IMPORT_FILE=${4}
                if [ -z "$DATABASE" ] || [ -z "$IMPORT_FILE" ]; then
                    error "Please specify database and import file: ./dev.sh mysql import <database> <file.sql[.gz]>"
                    exit 1
                fi
                if [ ! -f "$IMPORT_FILE" ]; then
                    error "Import file not found: $IMPORT_FILE"
                    exit 1
                fi
                
                # Create database if it doesn't exist
                log "Creating database '$DATABASE' if it doesn't exist..."
                $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysql -u root -ppassword -e "CREATE DATABASE IF NOT EXISTS \`$DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
                
                # Check if file is compressed
                if [[ "$IMPORT_FILE" == *.gz ]]; then
                    log "Importing compressed database file '$IMPORT_FILE' into '$DATABASE'..."
                    gunzip -c "$IMPORT_FILE" | $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec -T mysql80 mysql -u root -ppassword $DATABASE
                else
                    log "Importing database file '$IMPORT_FILE' into '$DATABASE'..."
                    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec -T mysql80 mysql -u root -ppassword $DATABASE < $IMPORT_FILE
                fi
                log "Database import completed successfully"
                ;;
            "export")
                DATABASE=${3}
                OUTPUT_FILE=${4}
                if [ -z "$DATABASE" ]; then
                    error "Please specify database: ./dev.sh mysql export <database> [output_file.sql[.gz]]"
                    exit 1
                fi
                
                # Generate filename if not provided
                if [ -z "$OUTPUT_FILE" ]; then
                    OUTPUT_FILE="export_${DATABASE}_$(date +%Y%m%d_%H%M%S).sql.gz"
                fi
                
                # Check if output should be compressed
                if [[ "$OUTPUT_FILE" == *.gz ]]; then
                    log "Exporting database '$DATABASE' to compressed file '$OUTPUT_FILE'..."
                    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysqldump -u root -ppassword --single-transaction --routines --triggers --add-drop-database --databases $DATABASE | gzip > $OUTPUT_FILE
                else
                    log "Exporting database '$DATABASE' to '$OUTPUT_FILE'..."
                    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysqldump -u root -ppassword --single-transaction --routines --triggers --add-drop-database --databases $DATABASE > $OUTPUT_FILE
                fi
                log "Database exported to: $OUTPUT_FILE"
                ;;
            "list")
                log "Available databases in MySQL 8.0:"
                $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysql -u root -ppassword -e "SHOW DATABASES;"
                ;;
            "size")
                DATABASE=${3}
                if [ -z "$DATABASE" ]; then
                    log "Database sizes in MySQL 8.0:"
                    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysql -u root -ppassword -e "
                    SELECT 
                        table_schema AS 'Database',
                        ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
                    FROM information_schema.tables 
                    WHERE table_schema NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
                    GROUP BY table_schema
                    ORDER BY SUM(data_length + index_length) DESC;"
                else
                    log "Tables in database '$DATABASE':"
                    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec mysql80 mysql -u root -ppassword -e "
                    SELECT 
                        table_name AS 'Table',
                        ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)',
                        table_rows AS 'Rows'
                    FROM information_schema.TABLES 
                    WHERE table_schema = '$DATABASE'
                    ORDER BY (data_length + index_length) DESC;"
                fi
                ;;
            *)
                error "Unknown mysql action: $ACTION"
                echo "Available actions:"
                echo "  connect    - Connect to database CLI"
                echo "  status     - Show database status"
                echo "  logs       - Show MySQL logs"
                echo "  backup     - Create database backup [database] [format: sql|gz]"
                echo "  restore    - Restore from backup [database] [backup_file.sql[.gz]]"
                echo "  import     - Import SQL file [database] [file.sql[.gz]]"
                echo "  export     - Export database [database] [output_file.sql[.gz]]"
                echo "  list       - List all databases"
                echo "  size       - Show database/table sizes [database]"
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
                $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE php -r "
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
                $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE php -r "
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
    "mysql-config")
        ACTION=${2:-"show"}
        case "$ACTION" in
            "show")
                show_mysql_config
                ;;
            "development"|"dev"|"production"|"prod"|"legacy"|"default")
                set_mysql_config "$ACTION"
                ;;
            *)
                error "Unknown mysql-config action: $ACTION"
                show_mysql_config
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
        echo "  mysql-config Configure MySQL settings (development|production|legacy|default)"
        echo "  db          Alias for mysql command"
        echo "  test-connection  Test database connection for PHP service"
        echo "  help        Show this help message"
        echo ""
        echo "Database Commands:"
        echo "  ./dev.sh mysql connect [mysql80|native]      # Connect to database"
        echo "  ./dev.sh mysql status                        # Show database status"
        echo "  ./dev.sh mysql logs                          # Show MySQL 8.0 logs"
        echo "  ./dev.sh mysql backup [database] [gz]        # Backup database (optionally compressed)"
        echo "  ./dev.sh mysql restore [database] [file]     # Restore database from .sql or .sql.gz"
        echo "  ./dev.sh mysql import [database] [file]      # Import .sql or .sql.gz file"
        echo "  ./dev.sh mysql export [database] [file]      # Export database to .sql or .sql.gz"
        echo "  ./dev.sh mysql list                          # List all databases"
        echo "  ./dev.sh mysql size [database]               # Show database/table sizes"
        echo "  ./dev.sh mysql-config [type]                # Set MySQL configuration"
        echo "  ./dev.sh test-connection [php_service]       # Test PHP-MySQL connection"
        echo ""
        echo "Examples:"
        echo "  ./dev.sh up"
        echo "  ./dev.sh logs nginx"
        echo "  ./dev.sh shell php84"
        echo "  ./dev.sh xdebug enable php84"
        echo "  ./dev.sh composer php84 install"
        echo "  ./dev.sh mysql connect mysql80"
        echo "  ./dev.sh mysql import myapp_db backup.sql.gz"
        echo "  ./dev.sh mysql backup production_db gz"
        echo "  ./dev.sh test-connection php56"
        ;;
esac
