<?php
// PHP 5.6 MySQL 8.0 Connection Test
// Place this file in your web directory to test the connection

error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>PHP " . PHP_VERSION . " - MySQL Connection Test</h2>";

// Connection parameters for MySQL 8.0 (Docker)
$host = 'mysql80';  // For Docker internal network
// $host = 'localhost:3307';  // For external connection
$username = 'legacy_user';
$password = 'legacy_password';
$database = 'php56_test';

echo "<h3>Testing MySQL 8.0 Connection (PHP 5.6 Compatible)</h3>";

// Test MySQLi connection
echo "<strong>MySQLi Test:</strong><br>";
try {
    $mysqli = new mysqli($host, $username, $password, $database);
    
    if ($mysqli->connect_error) {
        echo "❌ MySQLi Connection failed: " . $mysqli->connect_error . "<br>";
    } else {
        echo "✅ MySQLi Connected successfully!<br>";
        echo "Server Info: " . $mysqli->server_info . "<br>";
        echo "Host Info: " . $mysqli->host_info . "<br>";
        
        // Test query
        $result = $mysqli->query("SELECT COUNT(*) as count FROM users");
        if ($result) {
            $row = $result->fetch_assoc();
            echo "Test table has " . $row['count'] . " records<br>";
        }
        
        $mysqli->close();
    }
} catch (Exception $e) {
    echo "❌ MySQLi Error: " . $e->getMessage() . "<br>";
}

echo "<br>";

// Test MySQL extension (deprecated but still available in PHP 5.6)
echo "<strong>MySQL Extension Test:</strong><br>";
if (function_exists('mysql_connect')) {
    try {
        $connection = mysql_connect($host, $username, $password);
        if ($connection) {
            echo "✅ MySQL extension connected successfully!<br>";
            $selected = mysql_select_db($database, $connection);
            if ($selected) {
                echo "✅ Database selected successfully!<br>";
                $result = mysql_query("SELECT VERSION() as version", $connection);
                if ($result) {
                    $row = mysql_fetch_assoc($result);
                    echo "MySQL Version: " . $row['version'] . "<br>";
                }
            }
            mysql_close($connection);
        } else {
            echo "❌ MySQL extension connection failed<br>";
        }
    } catch (Exception $e) {
        echo "❌ MySQL extension error: " . $e->getMessage() . "<br>";
    }
} else {
    echo "ℹ️ MySQL extension not available (deprecated)<br>";
}

echo "<br>";

// Test PDO connection
echo "<strong>PDO Test:</strong><br>";
try {
    $dsn = "mysql:host=$host;dbname=$database;charset=utf8";
    $pdo = new PDO($dsn, $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "✅ PDO Connected successfully!<br>";
    
    // Get server version
    $stmt = $pdo->query("SELECT VERSION() as version");
    $version = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "MySQL Version: " . $version['version'] . "<br>";
    
    // Test query
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users");
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "Test table has " . $result['count'] . " records<br>";
    
} catch (PDOException $e) {
    echo "❌ PDO Connection failed: " . $e->getMessage() . "<br>";
}

echo "<br><hr><br>";

// Connection info for different scenarios
echo "<h3>Connection Information</h3>";
echo "<strong>For PHP 5.6 applications (use MySQL 8.0 Docker):</strong><br>";
echo "Host: mysql80 (internal) or localhost:3307 (external)<br>";
echo "Username: legacy_user<br>";
echo "Password: legacy_password<br>";
echo "Database: php56_test<br><br>";

echo "<strong>For Modern PHP applications (use MySQL 8.4 Native):</strong><br>";
echo "Host: host.docker.internal (from container) or localhost:3306 (external)<br>";
echo "Username: root<br>";
echo "Password: [your native MySQL password]<br>";

echo "<br>";
echo "<em>Generated at: " . date('Y-m-d H:i:s') . "</em>";
?>
