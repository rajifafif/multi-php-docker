-- Initialize MySQL 8.0 for PHP 5.6 compatibility
-- This script runs automatically when the container starts for the first time

-- Create additional user with mysql_native_password for PHP 5.6 compatibility
CREATE USER IF NOT EXISTS 'legacy_user'@'%' IDENTIFIED WITH mysql_native_password BY 'legacy_password';
GRANT ALL PRIVILEGES ON *.* TO 'legacy_user'@'%' WITH GRANT OPTION;

-- Create user for specific applications
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED WITH mysql_native_password BY 'app_password';
GRANT ALL PRIVILEGES ON test_db.* TO 'app_user'@'%';

-- Create sample database for testing
CREATE DATABASE IF NOT EXISTS `php56_test` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON php56_test.* TO 'legacy_user'@'%';
GRANT ALL PRIVILEGES ON php56_test.* TO 'app_user'@'%';

-- Create sample table for testing
USE php56_test;
CREATE TABLE IF NOT EXISTS `users` (
    `id` int NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `email` varchar(100) NOT NULL,
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert sample data
INSERT IGNORE INTO `users` (`name`, `email`) VALUES
('John Doe', 'john@example.com'),
('Jane Smith', 'jane@example.com'),
('Bob Johnson', 'bob@example.com');

-- Flush privileges to ensure all changes are applied
FLUSH PRIVILEGES;

-- Log the completion
SELECT 'MySQL 8.0 initialization completed for PHP 5.6 compatibility' AS message;
